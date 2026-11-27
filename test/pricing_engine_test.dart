import 'package:cafeteria_app/domain/offer_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prices = {'Burger': 100, 'Bread': 40, 'Coffee': 50, 'Tea': 30};
  final allOffers = [
    'combo_pack', 'free_tea', 'coffee_pair', 'bill_flat', 'bill_percent'
  ];

  group('PricingEngine', () {
    test('no offer fits: total equals subtotal', () {
      final engine = OfferFactory.createEngine(allOffers);
      final r = engine.bestPrice({'Bread': 1}, prices);
      expect(r.subtotal, 40);
      expect(r.total, 40);
      expect(r.discount, 0);
    });

    test('US4 acceptance: 2 Burger + 1 Coffee + 1 Tea costs 235', () {
      final engine = OfferFactory.createEngine(allOffers);
      final r = engine.bestPrice({'Burger': 2, 'Coffee': 1, 'Tea': 1}, prices);
      expect(r.subtotal, 280);
      expect(r.total, 235); // free Tea (-30) beats combo pack (-20), then -15
      expect(r.applied.map((a) => a.title), contains(startsWith('Free Tea')));
      expect(r.billDiscount, 15);
    });

    test('combo pack is chosen when it saves more', () {
      final engine = OfferFactory.createEngine(allOffers);
      final r = engine.bestPrice({'Burger': 1, 'Coffee': 2}, prices);
      // combo pack (-20) beats coffee pair (-5); then bill discount -15
      expect(r.subtotal, 200);
      expect(r.total, 165);
    });

    test('offers can be combined on different items', () {
      final engine = OfferFactory.createEngine(allOffers);
      final r = engine.bestPrice({'Burger': 3, 'Coffee': 1, 'Tea': 1}, prices);
      // free Tea uses 2 Burgers + Tea (-30), combo uses last Burger + Coffee (-20)
      expect(r.subtotal, 380);
      expect(r.total, 380 - 30 - 20 - 15);
    });

    test('only the bigger bill discount is used', () {
      final engine = OfferFactory.createEngine(allOffers);
      final r = engine.bestPrice({'Bread': 15}, prices); // 600 Tk
      expect(r.billDiscount, 60); // 10% beats flat 15
      expect(r.total, 540);
    });

    test('bill discount boundary: 99 gets nothing, 100 gets 15', () {
      final engine = OfferFactory.createEngine(['bill_flat']);
      expect(engine.bestPrice({'X': 1}, {'X': 99}).total, 99);
      expect(engine.bestPrice({'X': 1}, {'X': 100}).total, 85);
    });

    test('empty cart costs 0', () {
      final engine = OfferFactory.createEngine(allOffers);
      expect(engine.bestPrice({}, prices).total, 0);
    });
  });
}
