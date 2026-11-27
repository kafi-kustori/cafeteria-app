import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/exceptions.dart';
import '../domain/models.dart';
import 'cafeteria_repository.dart';

/// ADAPTER PATTERN: adapts the Supabase client API to our own
/// CafeteriaRepository interface.
class SupabaseCafeteriaRepository implements CafeteriaRepository {
  final SupabaseClient client;
  SupabaseCafeteriaRepository(this.client);

  /// Card ID 2203014 logs in as 2203014@cafeteria.app; the PIN is the password.
  static String emailFor(String cardNo) => '${cardNo.trim()}@cafeteria.app';

  @override
  Future<CardInfo> signIn(String cardNo, String pin) async {
    await client.auth.signInWithPassword(email: emailFor(cardNo), password: pin);
    return fetchMyCard();
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  @override
  Future<CardInfo> fetchMyCard() async {
    final uid = client.auth.currentUser!.id;
    final row = await client.from('cards').select().eq('id', uid).single();
    return CardInfo.fromMap(row);
  }

  @override
  Future<List<MenuItem>> fetchMenu() async {
    final rows = await client.from('menu_items').select().order('id');
    return rows.map(MenuItem.fromMap).toList();
  }

  @override
  Future<List<String>> fetchActiveOfferCodes() async {
    final rows = await client.from('offers').select('code').eq('active', true);
    return rows.map((r) => r['code'] as String).toList();
  }

  @override
  Future<OrderResult> placeOrder(Map<int, int> items, int discount) async {
    final payload = items.entries
        .map((e) => {'item_id': e.key, 'qty': e.value})
        .toList();
    try {
      final result = await client.rpc('place_order',
          params: {'p_items': payload, 'p_discount': discount});
      return OrderResult.fromMap(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (e) {
      throw _translate(e.message);
    }
  }

  /// Turns database error text like "OUT_OF_STOCK:4:14" into our own exceptions.
  static CafeteriaException _translate(String message) {
    final parts = message.split(':');
    if (parts.first == 'OUT_OF_STOCK' && parts.length >= 3) {
      return OutOfStockException(int.parse(parts[1]), int.parse(parts[2]));
    }
    if (parts.first == 'LOW_BALANCE' && parts.length >= 3) {
      return LowBalanceException(int.parse(parts[1]), int.parse(parts[2]));
    }
    return CafeteriaException(message);
  }

  @override
  Future<List<OrderSummary>> fetchMyOrders() async {
    final uid = client.auth.currentUser!.id;
    final rows = await client
        .from('orders')
        .select('id, total, discount, created_at, order_items(qty, menu_items(name))')
        .eq('card_id', uid)
        .order('created_at', ascending: false);
    return rows.map((r) {
      final lines = (r['order_items'] as List)
          .map((li) => '${li['menu_items']['name']} x ${li['qty']}')
          .toList();
      return OrderSummary(
        id: r['id'] as int,
        total: r['total'] as int,
        discount: r['discount'] as int,
        createdAt: DateTime.parse(r['created_at'] as String),
        lines: lines,
      );
    }).toList();
  }

  @override
  Future<void> addItem(String name, int price, int stock) async {
    await client
        .from('menu_items')
        .insert({'name': name, 'price': price, 'stock': stock});
  }

  @override
  Future<void> updateStock(int itemId, int newStock) async {
    await client.from('menu_items').update({'stock': newStock}).eq('id', itemId);
  }

  @override
  Future<int> topUp(String cardNo, int amount) async {
    final result = await client
        .rpc('top_up', params: {'p_card_no': cardNo, 'p_amount': amount});
    return result as int;
  }

  @override
  Future<int> todaySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final rows = await client
        .from('orders')
        .select('total')
        .gte('created_at', startOfDay.toIso8601String());
    return rows.fold<int>(0, (sum, r) => sum + (r['total'] as int));
  }
}
