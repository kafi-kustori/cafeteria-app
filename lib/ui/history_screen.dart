import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import '../domain/models.dart';

/// US7: list of the student's past orders.
class HistoryScreen extends StatelessWidget {
  final CafeteriaRepository repo;
  const HistoryScreen({super.key, required this.repo});

  static String _formatDate(DateTime date) {
    final d = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

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
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _orderCard(context, orders[index]),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderSummary order) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long,
                      size: 22, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order.createdAt),
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${order.total} Tk',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            if (order.lines.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 10),
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(line, style: textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
            if (order.discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_offer,
                      size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Text(
                    'Discount ${order.discount} Tk',
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
