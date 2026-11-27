import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import '../domain/cart.dart';
import '../domain/models.dart';
import '../domain/offer_factory.dart';
import '../domain/pricing_engine.dart';
import '../services/checkout_service.dart';
import 'bill_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

/// US2 (menu), US3 (add/remove one at a time), US4 (best offer shown live).
class MenuScreen extends StatefulWidget {
  final CafeteriaRepository repo;
  final CardInfo card;
  const MenuScreen({super.key, required this.repo, required this.card});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _cart = Cart();
  late final CheckoutService _checkout = CheckoutService(widget.repo);
  List<MenuItem> _menu = [];
  PricingEngine? _engine;
  late CardInfo _card = widget.card;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final menu = await widget.repo.fetchMenu();
    final codes = await widget.repo.fetchActiveOfferCodes();
    final card = await widget.repo.fetchMyCard();
    if (!mounted) return;
    setState(() {
      _menu = menu;
      _engine = OfferFactory.createEngine(codes);
      _card = card;
    });
  }

  Future<void> _doCheckout() async {
    setState(() => _busy = true);
    final result = await _checkout.checkout(_cart);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BillScreen(result: result, cardName: _card.name)));
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Checkout'),
          content: Text([...result.notes, result.message].join('\n\n')),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'))
          ],
        ),
      );
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi ${_card.name} - Balance: ${_card.balance} Tk'),
        actions: [
          IconButton(
            tooltip: 'Order history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => HistoryScreen(repo: widget.repo))),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.repo.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => LoginScreen(repo: widget.repo)));
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _cart,
        builder: (context, _) => Column(children: [
          Expanded(
            child: ListView(children: [
              for (final item in _menu) _itemTile(item),
            ]),
          ),
          _summary(),
        ]),
      ),
    );
  }

  Widget _itemTile(MenuItem item) {
    final inCart = _cart.quantityOf(item.id);
    final left = item.stock - inCart;
    return ListTile(
      title: Text('${item.name} - ${item.price} Tk'),
      subtitle: Text(item.stock == 0 ? 'SOLD OUT' : '$left left'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Remove ${item.name}',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: inCart == 0 ? null : () => _cart.remove(item),
        ),
        Text('$inCart'),
        IconButton(
          tooltip: 'Add ${item.name}',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: left <= 0 ? null : () => _cart.add(item),
        ),
      ]),
    );
  }

  Widget _summary() {
    final engine = _engine;
    if (engine == null || _cart.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(16), child: Text('Your cart is empty'));
    }
    final prices = {for (final i in _menu) i.name: i.price};
    final price = engine.bestPrice(_cart.namedQuantities(_menu), prices);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Subtotal: ${price.subtotal} Tk'),
          for (final a in price.applied)
            Text('${a.title} x${a.times}: -${a.saving} Tk'),
          if (price.billDiscount > 0)
            Text('${price.billDiscountTitle}: -${price.billDiscount} Tk'),
          Text('Total: ${price.total} Tk',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _doCheckout,
            child: const Text('Checkout'),
          ),
        ]),
      ),
    );
  }
}
