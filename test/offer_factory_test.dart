import 'package:cafeteria_app/domain/offer_factory.dart';
import 'package:cafeteria_app/domain/offers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfferFactory', () {
    test('creates the right Strategy class for each code', () {
      expect(OfferFactory.itemOffer('combo_pack'), isA<ComboPackOffer>());
      expect(OfferFactory.itemOffer('free_tea'), isA<FreeTeaOffer>());
      expect(OfferFactory.itemOffer('coffee_pair'), isA<CoffeePairOffer>());
      expect(OfferFactory.billDiscount('bill_flat'), isA<FlatBillDiscount>());
      expect(OfferFactory.billDiscount('bill_percent'), isA<PercentBillDiscount>());
    });

    test('unknown codes are ignored', () {
      expect(OfferFactory.itemOffer('does_not_exist'), isNull);
      final engine = OfferFactory.createEngine(['does_not_exist', 'free_tea']);
      expect(engine.itemOffers.length, 1);
      expect(engine.billDiscounts, isEmpty);
    });

    test('a switched-off offer is not applied', () {
      // admin turned off free_tea: only combo pack can be used
      final engine = OfferFactory.createEngine(['combo_pack']);
      final r = engine.bestPrice({'Burger': 2, 'Coffee': 1, 'Tea': 1},
          {'Burger': 100, 'Coffee': 50, 'Tea': 30});
      expect(r.total, 260);
    });
  });
}
