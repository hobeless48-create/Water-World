import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/inventory_provider.dart';
import '../shared/widgets.dart';

/// ตัดสต็อกสินค้าสำเร็จรูปเมื่อขาย/ส่งมอบให้ลูกค้า
class DispatchPage extends StatefulWidget {
  const DispatchPage({super.key});

  @override
  State<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends State<DispatchPage> {
  final _qty = TextEditingController();
  final _note = TextEditingController();
  Item? _item;

  @override
  void initState() {
    super.initState();
    _qty.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _qtyValue => double.tryParse(_qty.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    final overStock = _item != null && _qtyValue > _item!.currentQuantity;

    return Scaffold(
      appBar: AppBar(title: const Text('ขาย/ส่งสินค้า')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButton<Item>(
            isExpanded: true,
            value: _item,
            hint: const Text('เลือกสินค้าสำเร็จรูป'),
            items: p.finished
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                        '${e.name} — คงเหลือ ${qtyFmt.format(e.currentQuantity)} ${e.unit}')))
                .toList(),
            onChanged: (v) => setState(() => _item = v),
          ),
          const SizedBox(height: 16),
          numberInput(_qty, 'จำนวนแพ็กที่ส่งมอบ'),
          if (overStock)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'เกินสต็อกคงเหลือ (${qtyFmt.format(_item!.currentQuantity)} ${_item!.unit})',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'ชื่อลูกค้า / หมายเหตุ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.local_shipping),
            label: const Text('บันทึกตัดสต็อก'),
            onPressed:
                (_item == null || _qtyValue <= 0 || overStock) ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final p = context.read<InventoryProvider>();
    final item = _item!;
    final ok = await trySave(context, () async {
      await p.dispatch(itemId: item.id, qty: _qtyValue, note: _note.text.trim());
      return 'ตัดสต็อก "${item.name}" ${qtyFmt.format(_qtyValue)} ${item.unit} เรียบร้อย';
    });
    if (ok && mounted) Navigator.pop(context);
  }
}
