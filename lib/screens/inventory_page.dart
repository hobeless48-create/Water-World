import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/inventory_provider.dart';
import '../shared/widgets.dart';
import 'adjust_page.dart';
import 'dispatch_page.dart';
import 'production_page.dart';
import 'receive_page.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('คลังสินค้า'),
          bottom: const TabBar(tabs: [
            Tab(text: 'วัตถุดิบ'),
            Tab(text: 'สินค้าสำเร็จรูป'),
          ]),
        ),
        body: p.loading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                _quickActions(context),
                Expanded(
                  child: TabBarView(children: [
                    _itemList(p.raw),
                    _itemList(p.finished),
                  ]),
                ),
              ]),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    Widget b(String label, IconData icon, Widget page) => Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
            child: FilledButton.tonal(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => page)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: Size.zero,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        );

    return Row(children: [
      b('รับเข้า', Icons.input, const ReceivePage()),
      b('ผลิต', Icons.factory, const ProductionPage()),
      b('ขาย/ส่ง', Icons.local_shipping, const DispatchPage()),
      b('ปรับยอด', Icons.tune, const AdjustPage()),
    ]);
  }

  Widget _itemList(List<Item> items) {
    if (items.isEmpty) {
      return const Center(child: Text('ไม่มีรายการ'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        return Card(
          child: ListTile(
            title: Text(it.name),
            subtitle: Text('${it.code} • หน่วย: ${it.unit}'),
            trailing: Text(
              '${qtyFmt.format(it.currentQuantity)} ${it.unit}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        );
      },
    );
  }
}
