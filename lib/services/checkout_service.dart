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

/// STUB (TDD red step): real logic comes in the feat commit.
class CheckoutService {
  final CafeteriaRepository repo;
  CheckoutService(this.repo);

  Future<PriceResult> preview(Cart cart, List<MenuItem> menu) =>
      throw UnimplementedError();

  Future<CheckoutResult> checkout(Cart cart) => throw UnimplementedError();
}
