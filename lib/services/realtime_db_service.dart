import 'package:firebase_database/firebase_database.dart';
import '../models/cart_item_model.dart';
import 'dart:async';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  RealtimeDBService();

  /// Listen to the root node for cart item data pushed by ESP32
  Stream<List<CartItem>> getCartItemsStream() {
    DatabaseReference rootRef = _database.ref();

    return rootRef.onValue.map((event) {
      final List<CartItem> items = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value;
        if (data is Map) {
          // Check if root itself is a single item (flat fields at root)
          if (data.containsKey('Product ID') || data.containsKey('Product name')) {
            final item = CartItem.fromMap(data);
            // Only add if the item has meaningful data
            if (item.productName.isNotEmpty || item.productId.isNotEmpty) {
              items.add(item);
            }
          } else {
            // Multiple items stored as children under root
            data.forEach((key, value) {
              if (value is Map) {
                final item = CartItem.fromMap(value);
                if (item.productName.isNotEmpty || item.productId.isNotEmpty) {
                  items.add(item);
                }
              }
            });
          }
        }
      }
      return items;
    });
  }

  /// Mark checkout as PAID at root level
  Future<void> checkout() async {
    DatabaseReference statusRef = _database.ref('status');
    await statusRef.set('PAID');
  }
}
