/// ข้อผิดพลาดของแอป แสดงข้อความภาษาไทยตรง ๆ โดยไม่มีคำนำหน้า
class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Item {
  Item({
    required this.id,
    required this.code,
    required this.name,
    required this.itemType,
    required this.unit,
    required this.currentQuantity,
    this.unitCost = 0,
  });

  final int id;
  final String code;
  final String name;
  final String itemType; // 'raw_material' | 'finished_good'
  final String unit;
  final double currentQuantity;
  final double unitCost;

  bool get isRaw => itemType == 'raw_material';

  // เทียบด้วย id เท่านั้น — DropdownButton ต้องหา item ที่เลือกไว้เจอแม้ provider
  // จะสร้าง instance ใหม่จากการ reload ข้อมูลจาก DB (ไม่งั้น assertion ตอน rebuild)
  @override
  bool operator ==(Object other) => other is Item && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory Item.fromMap(Map<String, Object?> m) => Item(
        id: m['id'] as int,
        code: m['code'] as String,
        name: m['name'] as String,
        itemType: m['item_type'] as String,
        unit: m['unit'] as String,
        currentQuantity: (m['current_quantity'] as num).toDouble(),
        unitCost: (m['unit_cost'] as num?)?.toDouble() ?? 0,
      );
}

/// บรรทัดสูตรการผลิต 1 รายการ (วัตถุดิบ 1 ตัว ต่อ 1 หน่วยของสินค้าสำเร็จรูป)
class RecipeLine {
  RecipeLine({
    required this.rawMaterialId,
    required this.name,
    required this.unit,
    required this.qtyPerUnit,
    required this.stock,
  });

  final int rawMaterialId;
  final String name;
  final String unit;
  final double qtyPerUnit;
  final double stock;

  double requiredFor(double packs) => qtyPerUnit * packs;

  double shortageFor(double packs) {
    final d = requiredFor(packs) - stock;
    return d > 0 ? d : 0;
  }

  factory RecipeLine.fromMap(Map<String, Object?> m) => RecipeLine(
        rawMaterialId: m['raw_material_id'] as int,
        name: m['name'] as String,
        unit: m['unit'] as String,
        qtyPerUnit: (m['quantity_per_unit'] as num).toDouble(),
        stock: (m['current_quantity'] as num).toDouble(),
      );
}

class StockTx {
  StockTx({
    required this.id,
    required this.itemName,
    required this.itemType,
    required this.transactionType,
    required this.quantityChange,
    required this.quantityAfter,
    required this.createdAt,
    this.note,
    this.referenceId,
  });

  final int id;
  final String itemName;
  final String itemType;
  final String transactionType;
  final double quantityChange;
  final double quantityAfter;
  final String createdAt;
  final String? note;
  final String? referenceId;

  factory StockTx.fromMap(Map<String, Object?> m) => StockTx(
        id: m['id'] as int,
        itemName: m['item_name'] as String,
        itemType: m['item_type'] as String,
        transactionType: m['transaction_type'] as String,
        quantityChange: (m['quantity_change'] as num).toDouble(),
        quantityAfter: (m['quantity_after'] as num).toDouble(),
        createdAt: m['created_at'] as String,
        note: m['note'] as String?,
        referenceId: m['reference_id'] as String?,
      );
}

const kTxLabels = <String, String>{
  'receive': 'รับเข้าวัตถุดิบ',
  'production_consume': 'ผลิต - ตัดวัตถุดิบ',
  'production_output': 'ผลิต - รับสินค้าสำเร็จรูป',
  'sale_dispatch': 'ขาย/ส่งสินค้า',
  'adjustment': 'ปรับยอด',
};

/// ตัวกรองหน้าประวัติ: (ป้าย, ค่า transaction_type หรือ null = ทั้งหมด, 'production' = ทุกประเภทที่ขึ้นต้นด้วย production_)
const kHistoryFilters = <(String, String?)>[
  ('ทั้งหมด', null),
  ('รับเข้า', 'receive'),
  ('ผลิต', 'production'),
  ('ขาย/ส่ง', 'sale_dispatch'),
  ('ปรับยอด', 'adjustment'),
];
