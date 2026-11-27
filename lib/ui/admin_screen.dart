import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import '../domain/models.dart';
import 'common_widgets.dart';
import 'login_screen.dart';

/// US8 (menu & stock), US9 (top up), US10 (low-stock alert & sales report).
class AdminScreen extends StatefulWidget {
  final CafeteriaRepository repo;
  const AdminScreen({super.key, required this.repo});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<MenuItem> _menu = [];
  int _sales = 0;
  final _cardNo = TextEditingController();
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _cardNo.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final menu = await widget.repo.fetchMenu();
    final sales = await widget.repo.todaySales();
    if (!mounted) return;
    setState(() {
      _menu = menu;
      _sales = sales;
    });
  }

  void _show(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _addItemDialog() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    final p = int.tryParse(price.text);
    final s = int.tryParse(stock.text);
    if (name.text.trim().isEmpty || p == null || p <= 0 || s == null || s < 0) {
      _show('Please enter a name, a price above 0 and a stock of 0 or more');
      return;
    }
    await widget.repo.addItem(name.text.trim(), p, s);
    await _reload();
  }

  Future<void> _topUp() async {
    final amount = int.tryParse(_amount.text);
    if (_cardNo.text.trim().isEmpty || amount == null || amount <= 0) {
      _show('Enter a card ID and an amount above 0');
      return;
    }
    try {
      final balance = await widget.repo.topUp(_cardNo.text.trim(), amount);
      _show('Done. New balance: $balance Tk');
      _amount.clear();
    } catch (_) {
      _show('Top-up failed: card not found?');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = _menu.where((i) => i.isLowStock).toList();
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text(
          'Cafeteria Admin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _reload),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.repo.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginScreen(repo: widget.repo)));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _dashboard(lowStock.length),
          if (lowStock.isNotEmpty) ...[
            const SizedBox(height: 12),
            _lowStockBanner(lowStock),
          ],
          const SizedBox(height: 22),
          Text(
            'Menu and stock',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final item in _menu) ...[
            _stockCard(item),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          _topUpCard(),
        ],
      ),
    );
  }

  Widget _dashboard(int lowStockCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 760 ? 3 : 1;
        final tileWidth = columns == 3 ? (width - 24) / 3 : width;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: tileWidth,
              child: _statCard(
                label: "Today's sales",
                value: '$_sales Tk',
                icon: Icons.point_of_sale,
                color: kBrandTeal,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _statCard(
                label: 'Items',
                value: '${_menu.length}',
                icon: Icons.fastfood,
                color: const Color(0xFF5C6BC0),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _statCard(
                label: 'Low stock',
                value: '$lowStockCount',
                icon: Icons.warning_amber_rounded,
                color: lowStockCount > 0
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lowStockBanner(List<MenuItem> lowStock) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'LOW STOCK: ${lowStock.map((i) => '${i.name} (${i.stock})').join(', ')}',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockCard(MenuItem item) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(foodEmoji(item.name),
                  style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
            FilledButton.tonal(
              onPressed: () async {
                await widget.repo.updateStock(item.id, item.stock + 10);
                await _reload();
              },
              child: const Text('Restock +10'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topUpCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.credit_score, size: 20, color: kBrandTeal),
                const SizedBox(width: 8),
                Text(
                  'Top up a card',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cardNo,
              decoration: const InputDecoration(labelText: 'Card ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (Tk)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _topUp,
                child: const Text('Top up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
