import 'package:flutter/foundation.dart';

import 'models.dart';

/// OBSERVER PATTERN: Cart is a ChangeNotifier. Every screen that listens
/// to it rebuilds by itself when an item is added or removed.
class Cart extends ChangeNotifier {
  final Map<int, int> _qty = {}; // item id -> quantity

  Map<int, int> get items => Map.unmodifiable(_qty);
  int quantityOf(int itemId) => _qty[itemId] ?? 0;
  bool get isEmpty => _qty.isEmpty;
  int get totalCount => _qty.values.fold(0, (a, b) => a + b);

  /// Adds ONE item. Returns false (and adds nothing) if no stock is left.
  bool add(MenuItem item) {
    if (quantityOf(item.id) >= item.stock) return false;
    _qty[item.id] = quantityOf(item.id) + 1;
    notifyListeners();
    return true;
  }

  /// Removes ONE item. Does nothing if the item is not in the cart.
  void remove(MenuItem item) {
    final current = quantityOf(item.id);
    if (current == 0) return;
    if (current == 1) {
      _qty.remove(item.id);
    } else {
      _qty[item.id] = current - 1;
    }
    notifyListeners();
  }

  /// Used when stock ran out: keeps only what is still available.
  void setQuantity(int itemId, int quantity) {
    if (quantity <= 0) {
      _qty.remove(itemId);
    } else {
      _qty[itemId] = quantity;
    }
    notifyListeners();
  }

  void clear() {
    _qty.clear();
    notifyListeners();
  }

  /// Converts to item name -> quantity, which the pricing engine uses.
  Map<String, int> namedQuantities(List<MenuItem> menu) {
    final result = <String, int>{};
    for (final item in menu) {
      final q = quantityOf(item.id);
      if (q > 0) result[item.name] = q;
    }
    return result;
  }
}
