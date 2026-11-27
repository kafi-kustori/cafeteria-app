import 'package:flutter/material.dart';

import '../services/checkout_service.dart';

/// US7: itemized bill after a successful payment.
class BillScreen extends StatelessWidget {
  final CheckoutResult result;
  final String cardName;
  const BillScreen({super.key, required this.result, required this.cardName});

  @override
  Widget build(BuildContext context) {
    final order = result.order!;
    final price = result.price!;
    return Scaffold(
      appBar: AppBar(title: Text('Bill #${order.orderId}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final note in result.notes)
          Text(note, style: const TextStyle(color: Colors.orange)),
        Text('Customer: $cardName'),
        const Divider(),
        for (final line in result.billLines) Text('$line Tk'),
        const Divider(),
        Text('Subtotal: ${order.subtotal} Tk'),
        for (final a in price.applied)
          Text('${a.title} x${a.times}: -${a.saving} Tk'),
        if (price.billDiscount > 0)
          Text('${price.billDiscountTitle}: -${price.billDiscount} Tk'),
        Text('TOTAL PAID: ${order.total} Tk',
            style: Theme.of(context).textTheme.titleLarge),
        Text('New balance: ${order.newBalance} Tk'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to menu'),
        ),
      ]),
    );
  }
}
