import 'offers.dart';
import 'pricing_engine.dart';

/// STUB (TDD red step): real logic comes in the feat commit.
class OfferFactory {
  static OfferStrategy? itemOffer(String code) => throw UnimplementedError();

  static BillDiscount? billDiscount(String code) => throw UnimplementedError();

  static PricingEngine createEngine(List<String> activeCodes) =>
      throw UnimplementedError();
}
