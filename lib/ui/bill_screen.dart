import 'package:flutter/material.dart';

import '../services/checkout_service.dart';
import 'common_widgets.dart';

/// US7: itemized bill after a successful payment.
class BillScreen extends StatelessWidget {
  final CheckoutResult result;
  final String cardName;
  const BillScreen({super.key, required this.result, required this.cardName});

  @override
  Widget build(BuildContext context) {
    final order = result.order!;
    final price = result.price!;
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.6);
    const green = Color(0xFF2E7D32);
    return Scaffold(
      appBar: AppBar(title: Text('Bill #${order.orderId}')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.check_circle, color: green, size: 72),
                    const SizedBox(height: 10),
                    Text(
                      'Payment successful',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bill #${order.orderId}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 20, color: Color(0xFF546E7A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Customer: $cardName',
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final note in result.notes) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: Colors.orange.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note,
                                style: textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const DashedDivider(),
                    for (final line in result.billLines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('$line Tk',
                                  style: textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    const DashedDivider(),
                    Text(
                      'Subtotal: ${order.subtotal} Tk',
                      style: textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    for (final a in price.applied)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer,
                                size: 15, color: green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${a.title} x${a.times}: -${a.saving} Tk',
                                style: textTheme.bodySmall?.copyWith(
                                    color: green,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (price.billDiscount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.percent, size: 15, color: green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${price.billDiscountTitle}: '
                                '-${price.billDiscount} Tk',
                                style: textTheme.bodySmall?.copyWith(
                                    color: green,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: kBrandTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'TOTAL PAID: ${order.total} Tk',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: kBrandTealDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 18, color: Color(0xFF546E7A)),
                        const SizedBox(width: 6),
                        Text(
                          'New balance: ${order.newBalance} Tk',
                          style: textTheme.bodyMedium?.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to menu'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
