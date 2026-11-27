import '../domain/models.dart';

/// Everything the app needs from the backend.
/// The app only talks to this interface, never to Supabase directly,
/// so tests can replace it with a mock.
abstract class CafeteriaRepository {
  Future<CardInfo> signIn(String cardNo, String pin);
  Future<void> signOut();
  Future<CardInfo> fetchMyCard();

  Future<List<MenuItem>> fetchMenu();
  Future<List<String>> fetchActiveOfferCodes();

  /// [items] = item id -> quantity. Throws [OutOfStockException] or
  /// [LowBalanceException] if the order cannot be placed.
  Future<OrderResult> placeOrder(Map<int, int> items, int discount);
  Future<List<OrderSummary>> fetchMyOrders();

  // admin only
  Future<void> addItem(String name, int price, int stock);
  Future<void> updateStock(int itemId, int newStock);
  Future<int> topUp(String cardNo, int amount);
  Future<int> todaySales();
}
