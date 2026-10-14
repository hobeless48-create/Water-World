import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/inventory_provider.dart';
import '../shared/widgets.dart';

final _dateFmt = DateFormat('d MMM yyyy HH:mm', 'th');

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InventoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติสต็อก')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final (label, value) in kHistoryFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: p.historyFilter == value,
                      onSelected: (_) => p.loadHistory(value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: p.historyItems.isEmpty
                ? const Center(child: Text('ยังไม่มีรายการความเคลื่อนไหว'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: p.historyItems.length,
                    itemBuilder: (context, i) =>
                        _txCard(context, p.historyItems[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _txCard(BuildContext context, StockTx tx) {
    final color = _colorOf(tx.transactionType);
    final isIn = tx.quantityChange > 0;
    final note = (tx.note == null || tx.note!.isEmpty) ? '' : '\n${tx.note}';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_iconOf(tx.transactionType), color: color, size: 20),
        ),
        title: Text(tx.itemName),
        subtitle: Text(
          '${kTxLabels[tx.transactionType] ?? tx.transactionType} • ${_dateFmt.format(DateTime.parse(tx.createdAt))}$note',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIn ? '+' : ''}${qtyFmt.format(tx.quantityChange)}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text('เหลือ ${qtyFmt.format(tx.quantityAfter)}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Color _colorOf(String type) => switch (type) {
        'receive' => Colors.green,
        'production_consume' => Colors.orange,
        'production_output' => Colors.blue,
        'sale_dispatch' => Colors.purple,
        _ => Colors.blueGrey,
      };

  IconData _iconOf(String type) => switch (type) {
        'receive' => Icons.arrow_downward,
        'production_consume' => Icons.factory,
        'production_output' => Icons.water_drop,
        'sale_dispatch' => Icons.local_shipping,
        _ => Icons.tune,
      };
}
