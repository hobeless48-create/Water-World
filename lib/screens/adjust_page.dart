import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/inventory_provider.dart';
import '../shared/widgets.dart';

/// ปรับยอดวัตถุดิบ/สินค้า (เสียหาย, สูญหาย, ตรวจนับได้จริง)
class AdjustPage extends StatefulWidget {
  const AdjustPage({super.key});

  @override
  State<AdjustPage> createState() => _AdjustPageState();
}

class _AdjustPageState extends State<AdjustPage> {
  final _qty = TextEditingController();
  final _reason = TextEditingController();
  Item? _item;
  bool _increase = true;

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    final all = [...p.raw, ...p.finished];

    return Scaffold(
      appBar: AppBar(title: const Text('ปรับยอดสต็อก')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButton<Item>(
            isExpanded: true,
            value: _item,
            hint: const Text('เลือกรายการสต็อก'),
            items: all
                .map((e) => DropdownMenuItem(
                    value: e,
                    child:
                        Text('${e.name} — คงเหลือ ${qtyFmt.format(e.currentQuantity)} ${e.unit}')))
                .toList(),
            onChanged: (v) => setState(() => _item = v),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('ปรับเพิ่ม'), icon: Icon(Icons.add)),
              ButtonSegment(value: false, label: Text('ปรับลด'), icon: Icon(Icons.remove)),
            ],
            selected: {_increase},
            onSelectionChanged: (s) => setState(() => _increase = s.first),
          ),
          const SizedBox(height: 16),
          numberInput(_qty, 'จำนวนที่ปรับ'),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              labelText: 'เหตุผล (บังคับ เช่น ตรวจนับได้จริง / เสียหาย)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('บันทึกการปรับยอด'),
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
      if (item == null) throw AppException('กรุณาเลือกรายการสต็อก');
      if (qty == null || qty <= 0) {
        throw AppException('กรุณากรอกจำนวนที่มากกว่า 0');
      }
      await p.adjust(
        itemId: item.id,
        delta: _increase ? qty : -qty,
        reason: _reason.text,
      );
      return 'ปรับยอด "${item.name}" ${_increase ? '+' : '-'}${qtyFmt.format(qty)} ${item.unit} เรียบร้อย';
    });
    if (ok && mounted) Navigator.pop(context);
  }
}
