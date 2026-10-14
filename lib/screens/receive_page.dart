import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/inventory_provider.dart';
import '../shared/widgets.dart';

/// บันทึกรับเข้าวัตถุดิบ
class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final _qty = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  Item? _item;

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('รับเข้าวัตถุดิบ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButton<Item>(
            isExpanded: true,
            value: _item,
            hint: const Text('เลือกวัตถุดิบ'),
            items: p.raw
                .map((e) => DropdownMenuItem(
                    value: e, child: Text('${e.name} (${e.unit})')))
                .toList(),
            onChanged: (v) => setState(() => _item = v),
          ),
          const SizedBox(height: 16),
          numberInput(_qty, 'จำนวนที่รับเข้า'),
          const SizedBox(height: 16),
          numberInput(_cost, 'ต้นทุนต่อหน่วย (บาท, ไม่บังคับ)'),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ (เช่น ชื่อร้านค้าผู้ส่ง)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('บันทึกการรับเข้า'),
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final p = context.read<InventoryProvider>();
    final item = _item;
    final qty = double.tryParse(_qty.text.trim().replaceAll(',', ''));
    final ok = await trySave(context, () async {
      if (item == null) throw AppException('กรุณาเลือกวัตถุดิบ');
      if (qty == null || qty <= 0) {
        throw AppException('กรุณากรอกจำนวนที่มากกว่า 0');
      }
      final cost = double.tryParse(_cost.text.trim());
      await p.receive(
          itemId: item.id,
          qty: qty,
          unitCost: cost,
          note: _note.text.trim());
      return 'บันทึกรับเข้า "${item.name}" ${qtyFmt.format(qty)} ${item.unit} เรียบร้อย';
    });
    if (ok && mounted) Navigator.pop(context);
  }
}
