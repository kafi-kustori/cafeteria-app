import 'offers.dart';
import 'pricing_engine.dart';

/// FACTORY PATTERN: turns the offer codes stored in the database
/// into the right Strategy objects. If the admin switches an offer off,
/// its code is not in the list, so it is simply not created.
class OfferFactory {
  static OfferStrategy? itemOffer(String code) {
    switch (code) {
      case 'combo_pack':
        return ComboPackOffer();
      case 'free_tea':
        return FreeTeaOffer();
      case 'coffee_pair':
        return CoffeePairOffer();
      default:
        return null;
    }
  }

  static BillDiscount? billDiscount(String code) {
    switch (code) {
      case 'bill_flat':
        return FlatBillDiscount();
      case 'bill_percent':
        return PercentBillDiscount();
      default:
        return null;
    }
  }

  /// Builds a pricing engine from the active offer codes. Unknown codes are ignored.
  static PricingEngine createEngine(List<String> activeCodes) {
    final items = <OfferStrategy>[];
    final bills = <BillDiscount>[];
    for (final code in activeCodes) {
      final item = itemOffer(code);
      if (item != null) items.add(item);
      final bill = billDiscount(code);
      if (bill != null) bills.add(bill);
    }
    return PricingEngine(itemOffers: items, billDiscounts: bills);
  }
}
