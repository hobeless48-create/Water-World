import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/inventory_provider.dart';
import '../shared/widgets.dart';

/// บันทึกการผลิต: พรีวิวสูตร + ตัดวัตถุดิบอัตโนมัติ
class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  final _packs = TextEditingController();
  final _note = TextEditingController();
  Item? _finished;

  @override
  void initState() {
    super.initState();
    _packs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _packs.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _packsValue => double.tryParse(_packs.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    final lines = _finished == null ? null : p.recipes[_finished!.id];
    final packs = _packsValue;

    final ready = _finished != null &&
        packs > 0 &&
        lines != null &&
        lines.isNotEmpty &&
        lines.every((l) => l.shortageFor(packs) == 0);

    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกการผลิต')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButton<Item>(
            isExpanded: true,
            value: _finished,
            hint: const Text('เลือกสินค้าสำเร็จรูปที่จะผลิต'),
            items: p.finished
                .map((e) => DropdownMenuItem(
                    value: e, child: Text('${e.name} (${e.unit})')))
                .toList(),
            onChanged: (v) => setState(() => _finished = v),
          ),
          const SizedBox(height: 16),
          numberInput(_packs, 'จำนวนแพ็กที่ผลิต'),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (lines != null && lines.isNotEmpty) _preview(lines, packs),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.factory),
            label: const Text('ยืนยันการผลิต'),
            onPressed: ready ? _save : null,
          ),
          if (!ready)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'กรุณาเลือกสินค้า ระบุจำนวนแพ็ก และตรวจสอบว่าวัตถุดิบครบ',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _preview(List<RecipeLine> lines, double packs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('วัตถุดิบที่ใช้ต่อ ${qtyFmt.format(packs)} แพ็ก',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.name),
                          Text(
                            'ต้องใช้ ${qtyFmt.format(l.requiredFor(packs))} ${l.unit} • มีอยู่ ${qtyFmt.format(l.stock)} ${l.unit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (l.shortageFor(packs) > 0)
                      Text(
                        'ขาด ${qtyFmt.format(l.shortageFor(packs))}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final p = context.read<InventoryProvider>();
    final finished = _finished!;
    final ok = await trySave(context, () async {
      final batch = await p.produce(
          finishedId: finished.id, packs: _packsValue, note: _note.text.trim());
      return 'บันทึกการผลิต "${finished.name}" $_packsValue แพ็ก เรียบร้อย ($batch)';
    });
    if (ok && mounted) Navigator.pop(context);
  }
}
