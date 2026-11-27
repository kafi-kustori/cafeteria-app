import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import '../domain/models.dart';
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
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: price, decoration: const InputDecoration(labelText: 'Price')),
          TextField(controller: stock, decoration: const InputDecoration(labelText: 'Stock')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
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
      appBar: AppBar(
        title: const Text('Cafeteria Admin'),
        actions: [
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _reload),
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
      body: ListView(padding: const EdgeInsets.all(12), children: [
        // US10: low-stock alert
        if (lowStock.isNotEmpty)
          MaterialBanner(
            content: Text('LOW STOCK: ${lowStock.map((i) => '${i.name} (${i.stock})').join(', ')}'),
            leading: const Icon(Icons.warning, color: Colors.orange),
            actions: const [SizedBox.shrink()],
          ),
        // US10: daily sales report
        Card(
          child: ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text("Today's sales: $_sales Tk"),
          ),
        ),
        // US8: menu and stock
        Text('Menu and stock', style: Theme.of(context).textTheme.titleMedium),
        for (final item in _menu)
          ListTile(
            title: Text('${item.name} - ${item.price} Tk'),
            subtitle: Text('Stock: ${item.stock}${item.isLowStock ? '  (low)' : ''}'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await widget.repo.updateStock(item.id, item.stock + 10);
                await _reload();
              },
              child: Text('Restock ${item.name} +10'),
            ),
          ),
        const Divider(),
        // US9: top up a card
        Text('Top up a card', style: Theme.of(context).textTheme.titleMedium),
        TextField(controller: _cardNo, decoration: const InputDecoration(labelText: 'Card ID')),
        TextField(controller: _amount, decoration: const InputDecoration(labelText: 'Amount (Tk)')),
        const SizedBox(height: 8),
        FilledButton(onPressed: _topUp, child: const Text('Top up')),
        const SizedBox(height: 80),
      ]),
    );
  }
}
