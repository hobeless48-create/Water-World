import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:water_world/data/app_db.dart';
import 'package:water_world/data/stock_repository.dart';
import 'package:water_world/models.dart';

/// ทดสอบการตัดสต็อกตามสูตรผลิตด้วย SQLite จริง (FFI)
void main() {
  sqfliteFfiInit();

  late StockRepository repo;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('water_world_test');
    repo = StockRepository(
        AppDb(factory: databaseFactoryFfi, path: p.join(dir.path, 'test.db')));
    // รอให้ฐานข้อมูลสร้าง + seed
    await repo.itemByCode('PET_350');
  });

  test('ผลิตตัดวัตถุดิบตามสูตรและเพิ่มสินค้าสำเร็จรูป', () async {
    final pet = await repo.itemByCode('PET_350');
    final cap = await repo.itemByCode('CAP_SCREW');
    final pvc = await repo.itemByCode('PVC_FILM');
    final water = await repo.itemByCode('WATER_350_12');

    await repo.receive(itemId: pet.id, qty: 120, unitCost: 2.5);
    await repo.receive(itemId: cap.id, qty: 120);
    await repo.receive(itemId: pvc.id, qty: 10);

    final batch = await repo.produce(finishedId: water.id, packs: 10);
    expect(batch, startsWith('BATCH-'));

    // ตัดวัตถุดิบครบตามสูตร 12/12/1 ต่อแพ็ก
    expect((await repo.itemByCode('PET_350')).currentQuantity, 0);
    expect((await repo.itemByCode('CAP_SCREW')).currentQuantity, 0);
    expect((await repo.itemByCode('PVC_FILM')).currentQuantity, 0);
    expect((await repo.itemByCode('WATER_350_12')).currentQuantity, 10);
    expect((await repo.itemByCode('PET_350')).unitCost, 2.5);
  });

  test('วัตถุดิบไม่พอ ต้องไม่ตัดยอดใด ๆ (rollback ทั้ง transaction)', () async {
    final pet = await repo.itemByCode('PET_350');
    final cap = await repo.itemByCode('CAP_SCREW');
    final pvc = await repo.itemByCode('PVC_FILM');
    final water = await repo.itemByCode('WATER_350_12');

    await repo.receive(itemId: pet.id, qty: 120);
    await repo.receive(itemId: cap.id, qty: 120);
    await repo.receive(itemId: pvc.id, qty: 5);

    await expectLater(repo.produce(finishedId: water.id, packs: 10),
        throwsA(isA<AppException>()));

    // ต้องไม่มีอะไรถูกตัด/เพิ่มเลย
    expect((await repo.itemByCode('PET_350')).currentQuantity, 120);
    expect((await repo.itemByCode('PVC_FILM')).currentQuantity, 5);
    expect((await repo.itemByCode('WATER_350_12')).currentQuantity, 0);
    // มีแค่ 3 รายการรับเข้า ไม่มีธุรกรรมผลิตหลุดรอด
    expect((await repo.history()).length, 3);
  });

  test('ขายสินค้าตัดสต็อกและป้องกันยอดติดลบ', () async {
    final pet = await repo.itemByCode('PET_350');
    final cap = await repo.itemByCode('CAP_SCREW');
    final pvc = await repo.itemByCode('PVC_FILM');
    final water = await repo.itemByCode('WATER_350_12');

    await repo.receive(itemId: pet.id, qty: 120);
    await repo.receive(itemId: cap.id, qty: 120);
    await repo.receive(itemId: pvc.id, qty: 10);
    await repo.produce(finishedId: water.id, packs: 10);

    await repo.dispatch(itemId: water.id, qty: 4, note: 'ลูกค้า A');
    expect((await repo.itemByCode('WATER_350_12')).currentQuantity, 6);

    await expectLater(repo.dispatch(itemId: water.id, qty: 100),
        throwsA(isA<AppException>()));
    expect((await repo.itemByCode('WATER_350_12')).currentQuantity, 6);
  });

  test('กรองประวัติตามประเภท', () async {
    final pet = await repo.itemByCode('PET_350');
    final cap = await repo.itemByCode('CAP_SCREW');
    final pvc = await repo.itemByCode('PVC_FILM');
    final water = await repo.itemByCode('WATER_350_12');

    await repo.receive(itemId: pet.id, qty: 120);
    await repo.receive(itemId: cap.id, qty: 120);
    await repo.receive(itemId: pvc.id, qty: 10);
    await repo.produce(finishedId: water.id, packs: 10);
    await repo.dispatch(itemId: water.id, qty: 1);

    expect((await repo.history()).length, 8); // 3 + 4 + 1
    expect((await repo.history(type: 'receive')).length, 3);
    expect((await repo.history(type: 'production')).length, 4);
    expect((await repo.history(type: 'sale_dispatch')).length, 1);
  });
}
