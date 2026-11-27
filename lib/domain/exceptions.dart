/// Errors that the checkout can run into.

class CafeteriaException implements Exception {
  final String message;
  const CafeteriaException(this.message);

  @override
  String toString() => message;
}

/// Another student bought the item while this order was being built.
class OutOfStockException extends CafeteriaException {
  final int itemId;
  final int available;
  const OutOfStockException(this.itemId, this.available)
      : super('Item $itemId has only $available left');
}

/// The card does not have enough money.
class LowBalanceException extends CafeteriaException {
  final int balance;
  final int needed;
  const LowBalanceException(this.balance, this.needed)
      : super('Not enough balance: you have $balance Tk, need $needed Tk');
}
