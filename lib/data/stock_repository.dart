import 'package:sqflite/sqflite.dart';

import '../models.dart';
import 'app_db.dart';

/// ทุกการเคลื่อนไหวสต็อกจะถูกบันทึกลง stock_transactions พร้อม ๆ กับ
/// อัปเดต items.current_quantity ใน database transaction เดียวเสมอ
class StockRepository {
  StockRepository([AppDb? db]) : _app = db ?? AppDb.instance;

  final AppDb _app;
  Future<Database> get _db => _app.database;

  Future<List<Item>> items(String itemType) async {
    final rows = await (await _db).query('items',
        where: 'item_type = ?', whereArgs: [itemType], orderBy: 'id');
    return rows.map(Item.fromMap).toList();
  }

  Future<Item> itemByCode(String code) async {
    final rows = await (await _db).query('items',
        where: 'code = ?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) throw AppException('ไม่พบรายการ $code');
    return Item.fromMap(rows.first);
  }

  /// สูตรผลิตของสินค้า 1 ชนิด พร้อมสต็อกปัจจุบันของวัตถุดิบแต่ละตัว
  Future<List<RecipeLine>> recipeFor(int finishedId,
      [DatabaseExecutor? exec]) async {
    final db = exec ?? await _db;
    final rows = await db.rawQuery('''
      SELECT r.raw_material_id, i.name, i.unit, r.quantity_per_unit, i.current_quantity
      FROM recipes r JOIN items i ON i.id = r.raw_material_id
      WHERE r.finished_good_id = ? ORDER BY r.id''', [finishedId]);
    return rows.map(RecipeLine.fromMap).toList();
  }

  Future<Map<int, List<RecipeLine>>> allRecipes() async {
    final db = await _db;
    final rows = await db
        .query('items', columns: ['id'], where: 'item_type = ?',
            whereArgs: ['finished_good']);
    final map = <int, List<RecipeLine>>{};
    for (final r in rows) {
      final id = r['id'] as int;
      map[id] = await recipeFor(id, db);
    }
    return map;
  }

  /// รับเข้าวัตถุดิบ
  Future<void> receive(
      {required int itemId,
      required double qty,
      double? unitCost,
      String? note}) async {
    if (qty <= 0) throw AppException('จำนวนต้องมากกว่า 0');
    final db = await _db;
    await db.transaction((txn) => _apply(txn,
        itemId: itemId,
        delta: qty,
        type: 'receive',
        unitCost: unitCost,
        note: note));
  }

  /// ผลิตสินค้าสำเร็จรูป: ตัดวัตถุดิบตามสูตร + เพิ่มสินค้า ใน transaction เดียว
  Future<String> produce(
      {required int finishedId, required double packs, String? note}) async {
    if (packs <= 0) throw AppException('จำนวนแพ็กต้องมากกว่า 0');
    final db = await _db;
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final batchNo =
        'BATCH-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';

    return db.transaction<String>((txn) async {
      final lines = await recipeFor(finishedId, txn);
      if (lines.isEmpty) throw AppException('สินค้านี้ยังไม่มีสูตรการผลิต');

      final missing = <String>[];
      for (final l in lines) {
        final have = await _qty(txn, l.rawMaterialId);
        if (have < l.requiredFor(packs)) {
          missing.add(
              '${l.name} ขาด ${_num(l.requiredFor(packs) - have)} ${l.unit}');
        }
      }
      if (missing.isNotEmpty) {
        throw AppException('วัตถุดิบไม่พอสำหรับการผลิต:\n${missing.join('\n')}');
      }

      for (final l in lines) {
        await _apply(txn,
            itemId: l.rawMaterialId,
            delta: -l.requiredFor(packs),
            type: 'production_consume',
            ref: batchNo,
            note: note);
      }
      await _apply(txn,
          itemId: finishedId,
          delta: packs,
          type: 'production_output',
          ref: batchNo,
          note: note);
      await txn.insert('production_batches', {
        'batch_number': batchNo,
        'finished_good_id': finishedId,
        'quantity_produced': packs,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      return batchNo;
    });
  }

  /// ขาย/ส่งสินค้าสำเร็จรูปให้ลูกค้า
  Future<void> dispatch(
      {required int itemId, required double qty, String? note}) async {
    if (qty <= 0) throw AppException('จำนวนต้องมากกว่า 0');
    final db = await _db;
    await db.transaction((txn) =>
        _apply(txn, itemId: itemId, delta: -qty, type: 'sale_dispatch', note: note));
  }

  /// ปรับยอด (บวก/ลบ) ต้องระบุเหตุผล
  Future<void> adjust(
      {required int itemId, required double delta, required String reason}) async {
    if (delta == 0) throw AppException('จำนวนการปรับต้องไม่เท่ากับ 0');
    if (reason.trim().isEmpty) throw AppException('ต้องระบุเหตุผลการปรับยอด');
    final db = await _db;
    await db.transaction((txn) => _apply(txn,
        itemId: itemId, delta: delta, type: 'adjustment', note: reason.trim()));
  }

  /// ประวัติความเคลื่อนไหว (ล่าสุดก่อน)
  Future<List<StockTx>> history({String? type, int limit = 300}) async {
    var where = '';
    final args = <Object?>[];
    if (type == 'production') {
      where = "WHERE t.transaction_type LIKE 'production_%'";
    } else if (type != null) {
      where = 'WHERE t.transaction_type = ?';
      args.add(type);
    }
    final rows = await (await _db).rawQuery('''
      SELECT t.id, t.transaction_type, t.quantity_change, t.quantity_after,
             t.note, t.reference_id, t.created_at,
             i.name AS item_name, i.item_type
      FROM stock_transactions t JOIN items i ON i.id = t.item_id
      $where ORDER BY t.id DESC LIMIT ?''', [...args, limit]);
    return rows.map(StockTx.fromMap).toList();
  }

  Future<double> _qty(DatabaseExecutor db, int itemId) async {
    final rows = await db.query('items',
        columns: ['current_quantity'], where: 'id = ?', whereArgs: [itemId]);
    if (rows.isEmpty) throw AppException('ไม่พบสินค้ารหัส $itemId');
    return (rows.first['current_quantity'] as num).toDouble();
  }

  /// อัปเดตยอดคงเหลือ + บันทึก ledger ในที่เดียว
  Future<void> _apply(
    DatabaseExecutor db, {
    required int itemId,
    required double delta,
    required String type,
    double? unitCost,
    String? ref,
    String? note,
  }) async {
    final rows = await db.query('items', where: 'id = ?', whereArgs: [itemId]);
    if (rows.isEmpty) throw AppException('ไม่พบสินค้ารหัส $itemId');
    final row = rows.first;
    final before = (row['current_quantity'] as num).toDouble();
    final after = before + delta;
    if (after < 0) {
      throw AppException(
          '${row['name']}: คงเหลือ ${_num(before)} ${row['unit']} ไม่พอ (ต้องใช้ ${_num(-delta)})');
    }
    final now = DateTime.now().toIso8601String();
    final update = <String, Object?>{
      'current_quantity': after,
      'updated_at': now,
    };
    if (unitCost != null) update['unit_cost'] = unitCost;
    await db.update('items', update, where: 'id = ?', whereArgs: [itemId]);

    final tx = <String, Object?>{
      'item_id': itemId,
      'transaction_type': type,
      'quantity_change': delta,
      'quantity_before': before,
      'quantity_after': after,
      'created_at': now,
    };
    if (unitCost != null) tx['unit_price_or_cost'] = unitCost;
    if (ref != null) tx['reference_id'] = ref;
    if (note != null && note.trim().isNotEmpty) tx['note'] = note.trim();
    await db.insert('stock_transactions', tx);
  }

  String _num(double n) =>
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString();
}
