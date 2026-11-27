import 'package:flutter/foundation.dart';

import 'models.dart';

/// OBSERVER PATTERN: Cart is a ChangeNotifier. Every screen that listens
/// to it rebuilds by itself when an item is added or removed.
///
/// STUB (TDD red step): same public API as the real Cart, no behaviour yet.
class Cart extends ChangeNotifier {
  Map<int, int> get items => throw UnimplementedError();
  int quantityOf(int itemId) => throw UnimplementedError();
  bool get isEmpty => throw UnimplementedError();
  int get totalCount => throw UnimplementedError();

  /// Adds ONE item. Returns false (and adds nothing) if no stock is left.
  bool add(MenuItem item) => throw UnimplementedError();

  /// Removes ONE item. Does nothing if the item is not in the cart.
  void remove(MenuItem item) => throw UnimplementedError();

  /// Used when stock ran out: keeps only what is still available.
  void setQuantity(int itemId, int quantity) => throw UnimplementedError();

  void clear() => throw UnimplementedError();

  /// Converts to item name -> quantity, which the pricing engine uses.
  Map<String, int> namedQuantities(List<MenuItem> menu) =>
      throw UnimplementedError();
}
