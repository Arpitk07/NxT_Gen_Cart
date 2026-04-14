import 'package:firebase_database/firebase_database.dart';
import '../models/cart_item_model.dart';
import 'dart:async';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String trolleyId;

  RealtimeDBService({this.trolleyId = 'T1'});

  DatabaseReference get _cartItemsRef =>
      _database.ref('trolleys/$trolleyId/cart_items');

  DatabaseReference _itemRef(String itemId) => _cartItemsRef.child(itemId);

  /// Listen only to one trolley's cart items in RTDB.
  Stream<List<CartItem>> getCartItemsStream() {
    return _cartItemsRef.onValue.map((event) {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue == null) {
        return <CartItem>[];
      }

      final List<CartItem> items = [];
      if (snapshotValue is Map) {
        snapshotValue.forEach((key, value) {
          if (value is Map) {
            final item = CartItem.fromMap(key.toString(), value);
            if (item.name.isNotEmpty) {
              items.add(item);
            }
          }
        });
      }

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    });
  }

  /// Adds a new item or increments quantity for an existing scanned item.
  ///
  /// Uses a transaction so concurrent scans do not lose quantity updates.
  Future<void> addOrIncrementItem({
    required String itemId,
    required String name,
    required double price,
    required String expiry,
    int quantityIncrement = 1,
    int? timestamp,
  }) async {
    if (itemId.trim().isEmpty) {
      throw ArgumentError('itemId cannot be empty');
    }

    final int now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final int incrementBy = quantityIncrement <= 0 ? 1 : quantityIncrement;

    await _itemRef(itemId).runTransaction((currentValue) {
      if (currentValue is Map) {
        final int existingQty =
            int.tryParse(currentValue['quantity']?.toString() ?? '0') ?? 0;

        return Transaction.success({
          ...Map<dynamic, dynamic>.from(currentValue),
          'name': name,
          'price': price,
          'expiry': expiry,
          'quantity': existingQty + incrementBy,
          'timestamp': now,
        });
      }

      return Transaction.success({
        'name': name,
        'price': price,
        'expiry': expiry,
        'quantity': incrementBy,
        'timestamp': now,
      });
    });
  }

  /// Decrements quantity for an item.
  ///
  /// If quantity is 1, the item node is deleted from RTDB.
  Future<void> decrementItem(String itemId, {int? timestamp}) async {
    if (itemId.trim().isEmpty) {
      throw ArgumentError('itemId cannot be empty');
    }

    final int now = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    await _itemRef(itemId).runTransaction((currentValue) {
      if (currentValue is! Map) {
        return Transaction.abort();
      }

      final int existingQty =
          int.tryParse(currentValue['quantity']?.toString() ?? '0') ?? 0;

      if (existingQty <= 1) {
        // Returning null deletes this node in Realtime Database.
        return Transaction.success(null);
      }

      return Transaction.success({
        ...Map<dynamic, dynamic>.from(currentValue),
        'quantity': existingQty - 1,
        'timestamp': now,
      });
    });
  }

  Future<void> removeItem(String itemId) async {
    if (itemId.trim().isEmpty) return;
    await _itemRef(itemId).remove();
  }

  Future<void> clearCart() async {
    await _cartItemsRef.remove();
  }

  /// Mark checkout as PAID for the selected trolley.
  Future<void> checkout() async {
    final DatabaseReference statusRef = _database.ref(
      'trolleys/$trolleyId/status',
    );
    await statusRef.set('PAID');
  }
}
