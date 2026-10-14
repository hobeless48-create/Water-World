import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// เปิด/สร้างฐานข้อมูล SQLite ในเครื่อง พร้อม seed รายการเริ่มต้น
/// สามารถ inject factory/path สำหรับใช้ใน unit test ได้
class AppDb {
  AppDb({this.factory, this.path});

  static final AppDb instance = AppDb();

  final DatabaseFactory? factory;
  final String? path;
  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await (factory ?? databaseFactory).openDatabase(
      path ?? p.join(await getDatabasesPath(), 'water_world.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          // บน Android execute รันได้ทีละ 1 statement จึงต้อง split เอง
          for (final stmt in _schema.split(';')) {
            final s = stmt.trim();
            if (s.isNotEmpty) await db.execute(s);
          }
          await _seed(db);
        },
      ),
    );
    _db = db;
    return db;
  }

  static const _schema = '''
CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  item_type TEXT NOT NULL CHECK (item_type IN ('raw_material','finished_good')),
  unit TEXT NOT NULL,
  current_quantity REAL NOT NULL DEFAULT 0,
  unit_cost REAL NOT NULL DEFAULT 0,
  min_quantity REAL NOT NULL DEFAULT 0,
  safety_stock REAL NOT NULL DEFAULT 0,
  reserved_quantity REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  finished_good_id INTEGER NOT NULL REFERENCES items (id),
  raw_material_id INTEGER NOT NULL REFERENCES items (id),
  quantity_per_unit REAL NOT NULL
);
CREATE TABLE production_batches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_number TEXT UNIQUE NOT NULL,
  finished_good_id INTEGER NOT NULL REFERENCES items (id),
  quantity_produced REAL NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE stock_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL REFERENCES items (id),
  transaction_type TEXT NOT NULL,
  quantity_change REAL NOT NULL,
  quantity_before REAL NOT NULL,
  quantity_after REAL NOT NULL,
  unit_price_or_cost REAL,
  reference_id TEXT,
  note TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX idx_tx_item ON stock_transactions (item_id);
CREATE INDEX idx_tx_created ON stock_transactions (created_at);
''';

  static Future<void> _seed(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();

    Future<void> item(String code, String name, String type, String unit) =>
        db.insert('items', {
          'code': code,
          'name': name,
          'item_type': type,
          'unit': unit,
          'created_at': now,
          'updated_at': now,
        });

    // วัตถุดิบ
    await item('PET_350', 'ขวดพลาสติก PET 350 ml', 'raw_material', 'ขวด');
    await item('PET_600', 'ขวดพลาสติก PET 600 ml', 'raw_material', 'ขวด');
    await item('PET_1500', 'ขวดพลาสติก PET 1500 ml', 'raw_material', 'ขวด');
    await item('CAP_SCREW', 'ฝาขวดเกลียว', 'raw_material', 'ฝา');
    await item('PVC_FILM', 'ฟิล์มหด PVC', 'raw_material', 'แผ่น');
    await item('PE_FILM', 'ฟิล์มหด PE', 'raw_material', 'แผ่น');

    // สินค้าสำเร็จรูป
    await item('WATER_350_12', 'น้ำดื่ม 350 ml แพ็ก 12 ขวด', 'finished_good', 'แพ็ก');
    await item('WATER_600_12', 'น้ำดื่ม 600 ml แพ็ก 12 ขวด', 'finished_good', 'แพ็ก');
    await item('WATER_1500_6', 'น้ำดื่ม 1500 ml แพ็ก 6 ขวด', 'finished_good', 'แพ็ก');

    Future<int> idOf(String code) async {
      final rows = await db.query('items',
          columns: ['id'], where: 'code = ?', whereArgs: [code], limit: 1);
      return rows.first['id'] as int;
    }

    Future<void> recipe(String fg, String rm, double qty) async {
      await db.insert('recipes', {
        'finished_good_id': await idOf(fg),
        'raw_material_id': await idOf(rm),
        'quantity_per_unit': qty,
      });
    }

    // สูตรผลิต 1 แพ็ก
    await recipe('WATER_350_12', 'PET_350', 12);
    await recipe('WATER_350_12', 'CAP_SCREW', 12);
    await recipe('WATER_350_12', 'PVC_FILM', 1);

    await recipe('WATER_600_12', 'PET_600', 12);
    await recipe('WATER_600_12', 'CAP_SCREW', 12);
    await recipe('WATER_600_12', 'PVC_FILM', 1);

    await recipe('WATER_1500_6', 'PET_1500', 6);
    await recipe('WATER_1500_6', 'CAP_SCREW', 6);
    await recipe('WATER_1500_6', 'PE_FILM', 1);
  }
}
