import 'package:flutter/foundation.dart';

import '../data/stock_repository.dart';
import '../models.dart';

class InventoryProvider extends ChangeNotifier {
  final StockRepository repo = StockRepository();

  List<Item> raw = [];
  List<Item> finished = [];
  Map<int, List<RecipeLine>> recipes = {};
  List<StockTx> historyItems = [];
  String? historyFilter;
  bool loading = true;

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      raw = await repo.items('raw_material');
      finished = await repo.items('finished_good');
      recipes = await repo.allRecipes();
      historyItems = await repo.history(type: historyFilter);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String? filter) async {
    historyFilter = filter;
    historyItems = await repo.history(type: filter);
    notifyListeners();
  }

  Future<void> receive(
      {required int itemId,
      required double qty,
      double? unitCost,
      String? note}) async {
    await repo.receive(itemId: itemId, qty: qty, unitCost: unitCost, note: note);
    await refresh();
  }

  Future<String> produce(
      {required int finishedId, required double packs, String? note}) async {
    final batch = await repo.produce(finishedId: finishedId, packs: packs, note: note);
    await refresh();
    return batch;
  }

  Future<void> dispatch(
      {required int itemId, required double qty, String? note}) async {
    await repo.dispatch(itemId: itemId, qty: qty, note: note);
    await refresh();
  }

  Future<void> adjust(
      {required int itemId, required double delta, required String reason}) async {
    await repo.adjust(itemId: itemId, delta: delta, reason: reason);
    await refresh();
  }
}
