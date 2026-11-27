/// Plain data classes used everywhere in the app.

class MenuItem {
  final int id;
  final String name;
  final int price;
  final int stock;
  final int lowStockLimit;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.lowStockLimit = 5,
  });

  bool get isLowStock => stock <= lowStockLimit;

  factory MenuItem.fromMap(Map<String, dynamic> m) => MenuItem(
        id: m['id'] as int,
        name: m['name'] as String,
        price: m['price'] as int,
        stock: m['stock'] as int,
        lowStockLimit: (m['low_stock_limit'] ?? 5) as int,
      );
}

class CardInfo {
  final String cardNo;
  final String name;
  final int balance;
  final String role;

  const CardInfo({
    required this.cardNo,
    required this.name,
    required this.balance,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory CardInfo.fromMap(Map<String, dynamic> m) => CardInfo(
        cardNo: m['card_no'] as String,
        name: m['name'] as String,
        balance: m['balance'] as int,
        role: m['role'] as String,
      );
}

class OrderResult {
  final int orderId;
  final int subtotal;
  final int discount;
  final int total;
  final int newBalance;

  const OrderResult({
    required this.orderId,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.newBalance,
  });

  factory OrderResult.fromMap(Map<String, dynamic> m) => OrderResult(
        orderId: m['order_id'] as int,
        subtotal: m['subtotal'] as int,
        discount: m['discount'] as int,
        total: m['total'] as int,
        newBalance: m['new_balance'] as int,
      );
}

class OrderSummary {
  final int id;
  final int total;
  final int discount;
  final DateTime createdAt;
  final List<String> lines; // e.g. "Burger x 2"

  const OrderSummary({
    required this.id,
    required this.total,
    required this.discount,
    required this.createdAt,
    required this.lines,
  });
}
