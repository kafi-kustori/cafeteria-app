import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import '../domain/cart.dart';
import '../domain/models.dart';
import '../domain/offer_factory.dart';
import '../domain/pricing_engine.dart';
import '../services/checkout_service.dart';
import 'bill_screen.dart';
import 'common_widgets.dart';
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

  PriceResult? _bestPrice() {
    final engine = _engine;
    if (engine == null) return null;
    final prices = {for (final i in _menu) i.name: i.price};
    return engine.bestPrice(_cart.namedQuantities(_menu), prices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        toolbarHeight: 92,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi ${_card.name}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
            ),
            const SizedBox(height: 6),
            Chip(
              elevation: 0,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // The theme paints chips white, so use dark text for contrast.
              color: const WidgetStatePropertyAll(Colors.white),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              label: Text(
                'Balance: ${_card.balance} Tk',
                style: const TextStyle(
                    color: Color(0xFF00574B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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
        builder: (context, _) {
          final price = _bestPrice();
          return Column(
            children: [
              Expanded(child: _menuBody()),
              _summary(price),
            ],
          );
        },
      ),
    );
  }

  Widget _menuBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_menu.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final width = constraints.maxWidth;
        if (width >= 600) {
          final columns = width >= 900 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 164,
            ),
            itemCount: _menu.length,
            itemBuilder: (context, index) => _gridCard(_menu[index]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          itemCount: _menu.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _listCard(_menu[index]),
        );
      },
    );
  }

  Widget _gridCard(MenuItem item) {
    final inCart = _cart.quantityOf(item.id);
    final available = item.stock - inCart;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(foodEmoji(item.name),
                    style: const TextStyle(fontSize: 26)),
                const Spacer(),
                StockBadge(stock: item.stock),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.price} Tk',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Row(
              children: [
                _counterButton(
                  tooltip: 'Remove ${item.name}',
                  icon: Icons.remove,
                  filled: false,
                  onPressed: inCart == 0 ? null : () => _cart.remove(item),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$inCart',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                _counterButton(
                  tooltip: 'Add ${item.name}',
                  icon: Icons.add,
                  filled: true,
                  onPressed: available <= 0 ? null : () => _cart.add(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _listCard(MenuItem item) {
    final scheme = Theme.of(context).colorScheme;
    final inCart = _cart.quantityOf(item.id);
    final available = item.stock - inCart;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(foodEmoji(item.name),
                  style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.price} Tk',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  StockBadge(stock: item.stock),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _counterButton(
              tooltip: 'Remove ${item.name}',
              icon: Icons.remove,
              filled: false,
              onPressed: inCart == 0 ? null : () => _cart.remove(item),
            ),
            SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  '$inCart',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _counterButton(
              tooltip: 'Add ${item.name}',
              icon: Icons.add,
              filled: true,
              onPressed: available <= 0 ? null : () => _cart.add(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton({
    required String tooltip,
    required IconData icon,
    required bool filled,
    required VoidCallback? onPressed,
  }) {
    final style = IconButton.styleFrom(
      minimumSize: const Size(38, 38),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final iconWidget = Icon(icon, size: 18);
    return filled
        ? IconButton.filled(
            tooltip: tooltip,
            style: style,
            onPressed: onPressed,
            icon: iconWidget,
          )
        : IconButton.filledTonal(
            tooltip: tooltip,
            style: style,
            onPressed: onPressed,
            icon: iconWidget,
          );
  }

  Widget _summary(PriceResult? price) {
    final subtotal = price?.subtotal ?? 0;
    final total = price?.total ?? 0;
    final applied = price?.applied ?? const <AppliedOffer>[];
    final billDiscount = price?.billDiscount ?? 0;
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Subtotal: $subtotal Tk',
                    style: textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const Spacer(),
                  if (_cart.totalCount > 0)
                    Text(
                      '${_cart.totalCount} item${_cart.totalCount == 1 ? '' : 's'}',
                      style: textTheme.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
              if (applied.isNotEmpty || billDiscount > 0) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in applied)
                      _offerChip(
                        Icons.local_offer,
                        '${a.title} x${a.times}  -${a.saving} Tk',
                      ),
                    if (billDiscount > 0)
                      _offerChip(
                        Icons.percent,
                        '${price?.billDiscountTitle}: -$billDiscount Tk',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Total: $total Tk',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: (_busy || _cart.isEmpty) ? null : _doCheckout,
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offerChip(IconData icon, String text) {
    const green = Color(0xFF2E7D32);
    return Chip(
      elevation: 0,
      avatar: Icon(icon, size: 16, color: green),
      label: Text(
        text,
        style: const TextStyle(
            color: green, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: green.withValues(alpha: 0.10),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
