/// STRATEGY PATTERN: every offer is its own class behind one interface.
/// To add a new offer, write a new class; nothing else has to change.

/// The result of applying one offer as many times as it fits.
class OfferApplication {
  final String title;
  final int times;
  final int saving;
  final Map<String, int> remaining; // items left for the next offers

  const OfferApplication({
    required this.title,
    required this.times,
    required this.saving,
    required this.remaining,
  });
}

/// An offer that uses up items (each item can be used by only one offer).
abstract class OfferStrategy {
  String get code;
  String get title;

  /// [qty] = item name -> how many are still free to use.
  /// [prices] = item name -> price in Tk.
  OfferApplication apply(Map<String, int> qty, Map<String, int> prices);
}

int _count(Map<String, int> qty, String name) => qty[name] ?? 0;

/// A. Combo pack: 1 Burger + 1 Coffee = 20 Tk off.
class ComboPackOffer implements OfferStrategy {
  @override
  String get code => 'combo_pack';
  @override
  String get title => 'Combo pack (Burger + Coffee)';

  @override
  OfferApplication apply(Map<String, int> qty, Map<String, int> prices) {
    final burgers = _count(qty, 'Burger');
    final coffees = _count(qty, 'Coffee');
    final times = burgers < coffees ? burgers : coffees;
    final left = Map<String, int>.from(qty)
      ..['Burger'] = burgers - times
      ..['Coffee'] = coffees - times;
    return OfferApplication(
        title: title, times: times, saving: times * 20, remaining: left);
  }
}

/// B. 2 Burgers + 1 Tea: the Tea is free.
class FreeTeaOffer implements OfferStrategy {
  @override
  String get code => 'free_tea';
  @override
  String get title => 'Free Tea (2 Burgers + 1 Tea)';

  @override
  OfferApplication apply(Map<String, int> qty, Map<String, int> prices) {
    final burgers = _count(qty, 'Burger');
    final teas = _count(qty, 'Tea');
    final pairs = burgers ~/ 2;
    final times = pairs < teas ? pairs : teas;
    final left = Map<String, int>.from(qty)
      ..['Burger'] = burgers - times * 2
      ..['Tea'] = teas - times;
    return OfferApplication(
        title: title,
        times: times,
        saving: times * (prices['Tea'] ?? 0),
        remaining: left);
  }
}

/// C. 2 Coffees: 5 Tk off.
class CoffeePairOffer implements OfferStrategy {
  @override
  String get code => 'coffee_pair';
  @override
  String get title => 'Coffee pair (2 Coffees)';

  @override
  OfferApplication apply(Map<String, int> qty, Map<String, int> prices) {
    final coffees = _count(qty, 'Coffee');
    final times = coffees ~/ 2;
    final left = Map<String, int>.from(qty)..['Coffee'] = coffees - times * 2;
    return OfferApplication(
        title: title, times: times, saving: times * 5, remaining: left);
  }
}

/// A discount on the whole bill. Only ONE bill discount is used: the biggest.
abstract class BillDiscount {
  String get code;
  String get title;
  int discountFor(int amount);
}

/// D1. Bill 100 Tk or more: 15 Tk off.
class FlatBillDiscount implements BillDiscount {
  @override
  String get code => 'bill_flat';
  @override
  String get title => 'Bill discount (15 Tk)';

  @override
  int discountFor(int amount) => amount >= 100 ? 15 : 0;
}

/// D2. Bill 500 Tk or more: 10% off.
class PercentBillDiscount implements BillDiscount {
  @override
  String get code => 'bill_percent';
  @override
  String get title => 'Bill discount (10%)';

  @override
  int discountFor(int amount) => amount >= 500 ? amount ~/ 10 : 0;
}
