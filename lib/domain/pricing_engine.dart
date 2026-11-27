import 'offers.dart';

/// STUB (TDD red step): real logic comes in the feat commit.
class AppliedOffer {
  final String title;
  final int times;
  final int saving;
  const AppliedOffer(this.title, this.times, this.saving);
}

class PriceResult {
  final int subtotal;
  final List<AppliedOffer> applied;
  final String? billDiscountTitle;
  final int billDiscount;
  final int total;

  const PriceResult({
    required this.subtotal,
    required this.applied,
    required this.billDiscountTitle,
    required this.billDiscount,
    required this.total,
  });

  int get discount => subtotal - total;
}

class PricingEngine {
  final List<OfferStrategy> itemOffers;
  final List<BillDiscount> billDiscounts;

  PricingEngine({required this.itemOffers, required this.billDiscounts});

  PriceResult bestPrice(Map<String, int> qty, Map<String, int> prices) =>
      throw UnimplementedError();
}
