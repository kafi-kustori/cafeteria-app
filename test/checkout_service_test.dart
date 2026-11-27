import 'package:cafeteria_app/data/cafeteria_repository.dart';
import 'package:cafeteria_app/domain/cart.dart';
import 'package:cafeteria_app/domain/exceptions.dart';
import 'package:cafeteria_app/domain/models.dart';
import 'package:cafeteria_app/services/checkout_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// MOCK: a fake repository, so the test needs no internet and no Supabase.
class MockRepo extends Mock implements CafeteriaRepository {}

void main() {
  const burger = MenuItem(id: 1, name: 'Burger', price: 100, stock: 50);
  const coffee = MenuItem(id: 3, name: 'Coffee', price: 50, stock: 20);
  const tea = MenuItem(id: 4, name: 'Tea', price: 30, stock: 15);
  const allCodes = [
    'combo_pack', 'free_tea', 'coffee_pair', 'bill_flat', 'bill_percent'
  ];
  const okOrder = OrderResult(
      orderId: 1, subtotal: 280, discount: 45, total: 235, newBalance: 765);

  late MockRepo repo;
  late CheckoutService service;

  setUpAll(() => registerFallbackValue(<int, int>{}));

  setUp(() {
    repo = MockRepo();
    service = CheckoutService(repo);
    when(() => repo.fetchActiveOfferCodes()).thenAnswer((_) async => allCodes);
  });

  Cart cartWith(Map<MenuItem, int> items) {
    final cart = Cart();
    items.forEach((item, n) {
      for (var i = 0; i < n; i++) {
        cart.add(item);
      }
    });
    return cart;
  }

  test('successful checkout sends the best discount and empties the cart',
      () async {
    when(() => repo.fetchMenu()).thenAnswer((_) async => [burger, coffee, tea]);
    when(() => repo.placeOrder(any(), any())).thenAnswer((_) async => okOrder);
    final cart = cartWith({burger: 2, coffee: 1, tea: 1});

    final result = await service.checkout(cart);

    expect(result.success, isTrue);
    expect(result.order!.total, 235);
    expect(cart.isEmpty, isTrue);
    final sent = verify(() => repo.placeOrder(captureAny(), captureAny()))
        .captured;
    expect(sent[0], {1: 2, 3: 1, 4: 1});
    expect(sent[1], 45); // 280 - 235
  });

  test('US5: item runs out -> only that item is reduced, rest is kept',
      () async {
    // the newest menu says only 1 Coffee is left
    const lastCoffee = MenuItem(id: 3, name: 'Coffee', price: 50, stock: 1);
    when(() => repo.fetchMenu())
        .thenAnswer((_) async => [burger, lastCoffee, tea]);
    when(() => repo.placeOrder(any(), any())).thenAnswer((_) async => okOrder);
    final cart = cartWith({burger: 2, coffee: 2, tea: 1});

    final result = await service.checkout(cart);

    expect(result.success, isTrue);
    expect(result.notes.single, contains('reduced from 2 to 1'));
    final sent = verify(() => repo.placeOrder(captureAny(), any())).captured;
    expect(sent.single, {1: 2, 3: 1, 4: 1}); // Burger and Tea untouched
  });

  test('US6: low balance -> payment refused and cart is kept', () async {
    when(() => repo.fetchMenu()).thenAnswer((_) async => [burger, coffee, tea]);
    when(() => repo.placeOrder(any(), any()))
        .thenAnswer((_) async => throw const LowBalanceException(100, 235));
    final cart = cartWith({burger: 2, coffee: 1, tea: 1});

    final result = await service.checkout(cart);

    expect(result.success, isFalse);
    expect(result.message, contains('Not enough balance'));
    expect(cart.totalCount, 4); // nothing was lost
  });

  test('everything ran out -> no order is sent', () async {
    const noTea = MenuItem(id: 4, name: 'Tea', price: 30, stock: 0);
    when(() => repo.fetchMenu()).thenAnswer((_) async => [burger, coffee, noTea]);
    final cart = cartWith({tea: 1});

    final result = await service.checkout(cart);

    expect(result.success, isFalse);
    verifyNever(() => repo.placeOrder(any(), any()));
  });
}
