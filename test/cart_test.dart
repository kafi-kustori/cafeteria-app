import 'package:cafeteria_app/domain/cart.dart';
import 'package:cafeteria_app/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const burger = MenuItem(id: 1, name: 'Burger', price: 100, stock: 2);
  const tea = MenuItem(id: 4, name: 'Tea', price: 30, stock: 5);

  group('Cart', () {
    test('adds one item at a time', () {
      final cart = Cart();
      cart.add(burger);
      cart.add(burger);
      expect(cart.quantityOf(1), 2);
      expect(cart.totalCount, 2);
    });

    test('cannot add more than the stock', () {
      final cart = Cart();
      expect(cart.add(burger), isTrue);
      expect(cart.add(burger), isTrue);
      expect(cart.add(burger), isFalse); // stock is 2
      expect(cart.quantityOf(1), 2);
    });

    test('removes one item at a time and forgets items at zero', () {
      final cart = Cart()
        ..add(tea)
        ..add(tea);
      cart.remove(tea);
      expect(cart.quantityOf(4), 1);
      cart.remove(tea);
      expect(cart.isEmpty, isTrue);
      cart.remove(tea); // removing again does nothing
      expect(cart.isEmpty, isTrue);
    });

    test('notifies listeners when it changes (Observer)', () {
      final cart = Cart();
      var calls = 0;
      cart.addListener(() => calls++);
      cart.add(tea);
      cart.remove(tea);
      expect(calls, 2);
    });

    test('gives item names and quantities for pricing', () {
      final cart = Cart()
        ..add(burger)
        ..add(tea);
      expect(cart.namedQuantities([burger, tea]), {'Burger': 1, 'Tea': 1});
    });
  });
}
