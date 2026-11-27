import '../data/cafeteria_repository.dart';
import '../domain/cart.dart';
import '../domain/exceptions.dart';
import '../domain/models.dart';
import '../domain/offer_factory.dart';
import '../domain/pricing_engine.dart';

class CheckoutResult {
  final bool success;
  final String message;
  final OrderResult? order;
  final PriceResult? price;

  /// Lines of the bill, e.g. "Burger x 2 = 200".
  final List<String> billLines;

  /// Messages about items that ran out, e.g. "Only 1 Coffee left...".
  final List<String> notes;

  const CheckoutResult({
    required this.success,
    required this.message,
    this.order,
    this.price,
    this.billLines = const [],
    this.notes = const [],
  });
}

/// Puts the checkout steps together:
/// 1. read the newest stock, 2. shrink items that ran out but KEEP the rest,
/// 3. find the lowest total, 4. place the order (all-or-nothing in the database).
class CheckoutService {
  final CafeteriaRepository repo;
  CheckoutService(this.repo);

  Future<PriceResult> preview(Cart cart, List<MenuItem> menu) async {
    final engine = OfferFactory.createEngine(await repo.fetchActiveOfferCodes());
    return engine.bestPrice(cart.namedQuantities(menu), _prices(menu));
  }

  Future<CheckoutResult> checkout(Cart cart) async {
    final menu = await repo.fetchMenu();
    final notes = <String>[];

    for (final item in menu) {
      final wanted = cart.quantityOf(item.id);
      if (wanted > item.stock) {
        cart.setQuantity(item.id, item.stock);
        notes.add('Only ${item.stock} ${item.name} left now. '
            'Your ${item.name} was reduced from $wanted to ${item.stock}. '
            'The rest of your order is kept.');
      }
    }

    if (cart.isEmpty) {
      return CheckoutResult(
          success: false, message: 'Your order is empty.', notes: notes);
    }

    final price = await preview(cart, menu);
    final billLines = [
      for (final item in menu)
        if (cart.quantityOf(item.id) > 0)
          '${item.name} x ${cart.quantityOf(item.id)} = '
              '${cart.quantityOf(item.id) * item.price}'
    ];

    try {
      final order = await repo.placeOrder(cart.items, price.discount);
      cart.clear();
      return CheckoutResult(
        success: true,
        message: 'Payment successful.',
        order: order,
        price: price,
        billLines: billLines,
        notes: notes,
      );
    } on LowBalanceException catch (e) {
      return CheckoutResult(
          success: false,
          message: '${e.message}. Remove some items and try again.',
          price: price,
          notes: notes);
    } on OutOfStockException {
      return CheckoutResult(
          success: false,
          message: 'An item just ran out. Please check your order and try again.',
          notes: notes);
    }
  }

  static Map<String, int> _prices(List<MenuItem> menu) =>
      {for (final item in menu) item.name: item.price};
}
