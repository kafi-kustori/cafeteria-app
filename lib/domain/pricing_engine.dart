import 'offers.dart';

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

/// Finds the combination of offers that gives the LOWEST total.
///
/// Item offers can fight over the same items (a Burger can be in a combo pack
/// OR in the free-tea offer, not both). So the engine tries the offers in
/// every possible order, applies each as many times as it fits, then adds
/// the biggest bill discount, and keeps the cheapest result.
class PricingEngine {
  final List<OfferStrategy> itemOffers;
  final List<BillDiscount> billDiscounts;

  PricingEngine({required this.itemOffers, required this.billDiscounts});

  PriceResult bestPrice(Map<String, int> qty, Map<String, int> prices) {
    var subtotal = 0;
    qty.forEach((name, count) => subtotal += count * (prices[name] ?? 0));

    PriceResult? best;
    for (final order in _permutations(itemOffers)) {
      var left = Map<String, int>.from(qty);
      var saving = 0;
      final applied = <AppliedOffer>[];
      for (final offer in order) {
        final result = offer.apply(left, prices);
        if (result.times > 0) {
          applied.add(AppliedOffer(result.title, result.times, result.saving));
          saving += result.saving;
        }
        left = result.remaining;
      }

      final afterItems = subtotal - saving;
      var billDiscount = 0;
      String? billTitle;
      for (final bill in billDiscounts) {
        final d = bill.discountFor(afterItems);
        if (d > billDiscount) {
          billDiscount = d;
          billTitle = bill.title;
        }
      }

      final total = afterItems - billDiscount;
      if (best == null || total < best.total) {
        best = PriceResult(
          subtotal: subtotal,
          applied: applied,
          billDiscountTitle: billTitle,
          billDiscount: billDiscount,
          total: total,
        );
      }
    }
    return best!;
  }

  /// All orderings of the list. With no offers there is one ordering: [].
  static List<List<T>> _permutations<T>(List<T> list) {
    if (list.isEmpty) return [<T>[]];
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i++) {
      final rest = [...list]..removeAt(i);
      for (final p in _permutations(rest)) {
        result.add([list[i], ...p]);
      }
    }
    return result;
  }
}
