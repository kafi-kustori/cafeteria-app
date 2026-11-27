import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import '../domain/models.dart';

/// US7: list of the student's past orders.
class HistoryScreen extends StatelessWidget {
  final CafeteriaRepository repo;
  const HistoryScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order history')),
      body: FutureBuilder<List<OrderSummary>>(
        future: repo.fetchMyOrders(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) return const Center(child: Text('No orders yet'));
          return ListView(children: [
            for (final o in orders)
              ListTile(
                title: Text('Order #${o.id} - ${o.total} Tk'),
                subtitle: Text('${o.lines.join(', ')}\n'
                    'Discount ${o.discount} Tk - ${o.createdAt.toLocal()}'),
                isThreeLine: true,
              ),
          ]);
        },
      ),
    );
  }
}
