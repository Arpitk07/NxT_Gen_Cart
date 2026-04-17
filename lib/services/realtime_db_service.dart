import 'package:firebase_database/firebase_database.dart';
import '../models/cart_item_model.dart';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String trolleyId;

  RealtimeDBService({this.trolleyId = 'T1'});

  DatabaseReference get _cartItemsRef =>
      _database.ref('trolleys/$trolleyId/cart_items');

  DatabaseReference get _productsRef => _database.ref('products');

  DatabaseReference _itemRef(String itemId) => _cartItemsRef.child(itemId);

  static const Map<String, List<String>> _fallbackSuggestions = {
    'milk': ['bread', 'coffee'],
    'bread': ['butter', 'jam'],
    'eggs': ['cheese', 'bread'],
  };

  static const Map<String, Map<String, dynamic>> _fallbackCatalog = {
    'milk': {
      'name': 'Milk',
      'price': 62.0,
      'expiry': '2026-12-30',
      'imageUrl': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300',
    },
    'bread': {
      'name': 'Bread',
      'price': 42.0,
      'expiry': '2026-10-15',
      'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
    },
    'coffee': {
      'name': 'Coffee',
      'price': 285.0,
      'expiry': '2027-05-01',
      'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=300',
    },
    'butter': {
      'name': 'Butter',
      'price': 54.0,
      'expiry': '2026-11-20',
      'imageUrl': 'https://images.unsplash.com/photo-1589985270958-3491b0f4f28a?w=300',
    },
    'jam': {
      'name': 'Jam',
      'price': 110.0,
      'expiry': '2027-02-02',
      'imageUrl': 'https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=300',
    },
    'eggs': {
      'name': 'Eggs',
      'price': 78.0,
      'expiry': '2026-08-11',
      'imageUrl': 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=300',
    },
    'cheese': {
      'name': 'Cheese',
      'price': 160.0,
      'expiry': '2026-11-08',
      'imageUrl': 'https://images.unsplash.com/photo-1452195100486-9cc805987862?w=300',
    },
  };

  /// Listen only to one trolley's cart items in RTDB.
  Stream<List<CartItem>> getCartItemsStream() {
    return _cartItemsRef.onValue.asyncMap((event) async {
      if (event.snapshot.children.isEmpty) {
        return <CartItem>[];
      }

      final Map<dynamic, dynamic> productsMap = await _fetchProductsMap();

      final List<CartItem> items = event.snapshot.children
          .map((child) {
            final value = child.value;
            if (value is! Map) return null;
            final String id = child.key ?? '';
            final productRaw = productsMap[id];
            final Map<dynamic, dynamic>? productMap =
                productRaw is Map ? productRaw : null;
            final item = _mergeCartWithProductData(
              itemId: id,
              cartMap: value,
              productMap: productMap,
            );
            return item.name.isEmpty ? null : item;
          })
          .whereType<CartItem>()
          .toList();

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    });
  }

  Future<void> addOrIncrementItem({
    required String itemId,
    required String name,
    required double price,
    required String expiry,
    required String imageUrl,
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
          'image': imageUrl,
          'quantity': existingQty + incrementBy,
          'timestamp': now,
        });
      }

      return Transaction.success({
        'name': name,
        'price': price,
        'expiry': expiry,
        'image': imageUrl,
        'quantity': incrementBy,
        'timestamp': now,
      });
    });
  }

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
        return Transaction.success(null);
      }

      return Transaction.success({
        ...Map<dynamic, dynamic>.from(currentValue),
        'quantity': existingQty - 1,
        'timestamp': now,
      });
    });
  }

  Future<List<CartItem>> getSuggestedProducts(CartItem forItem) async {
    final Map<dynamic, dynamic> productsMap = await _fetchProductsMap();

    List<String> suggestionIds = forItem.suggestions;
    if (suggestionIds.isEmpty) {
      suggestionIds =
          _fallbackSuggestions[_slugify(forItem.id)] ??
          _fallbackSuggestions[_slugify(forItem.name)] ??
          <String>[];
    }

    final List<CartItem> suggestions = <CartItem>[];
    for (final suggestionId in suggestionIds) {
      final String key = _slugify(suggestionId);
      final dynamic raw = productsMap[key];
      if (raw is Map) {
        suggestions.add(_cartItemFromMap(key, raw));
        continue;
      }

      final fallback = _fallbackCatalog[key];
      if (fallback != null) {
        suggestions.add(_cartItemFromMap(key, fallback));
      }
    }

    return suggestions;
  }

  Future<List<CartItem>> getCatalogProducts() async {
    final List<CartItem> results = [];
    try {
      final snapshot = await _productsRef.get();
      if (snapshot.value is Map) {
        final Map rawMap = snapshot.value as Map;
        rawMap.forEach((key, value) {
          if (value is Map) {
            results.add(_cartItemFromMap(_slugify(key.toString()), value));
          }
        });
      }
    } catch (_) {
      // Fall back to static catalog.
    }

    if (results.isNotEmpty) {
      results.sort((a, b) => a.name.compareTo(b.name));
      return results;
    }

    return _fallbackCatalog.entries
        .map((entry) => _cartItemFromMap(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addCatalogProduct(String productId, {int quantityIncrement = 1}) async {
    final CartItem? product = await _resolveProduct(productId);
    if (product == null) {
      throw StateError('Product not found for id: $productId');
    }

    await addOrIncrementItem(
      itemId: product.id,
      name: product.name,
      price: product.price,
      expiry: product.expiry,
      imageUrl: product.imageUrl,
      quantityIncrement: quantityIncrement,
    );
  }

  Future<CartItem?> _resolveProduct(String productId) async {
    final String key = _slugify(productId);
    try {
      final snapshot = await _productsRef.child(key).get();
      if (snapshot.value is Map) {
        return _cartItemFromMap(key, snapshot.value as Map);
      }
    } catch (_) {
      // Fall back to static catalog.
    }

    final fallback = _fallbackCatalog[key];
    if (fallback == null) return null;
    return _cartItemFromMap(key, fallback);
  }

  CartItem _cartItemFromMap(String id, Map<dynamic, dynamic> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return CartItem(
      id: id,
      name: (map['name'] ?? id).toString(),
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0,
      expiry: (map['expiry'] ?? '').toString(),
      imageUrl: (map['image'] ?? map['imageUrl'] ?? '').toString(),
      suggestions: _parseSuggestions(map['suggestions']),
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      timestamp: int.tryParse(map['timestamp']?.toString() ?? '$now') ?? now,
    );
  }

  CartItem _mergeCartWithProductData({
    required String itemId,
    required Map<dynamic, dynamic> cartMap,
    required Map<dynamic, dynamic>? productMap,
  }) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    final String name =
        (productMap?['name'] ?? cartMap['name'] ?? itemId).toString();
    final double price =
        double.tryParse((productMap?['price'] ?? cartMap['price'] ?? '0').toString()) ??
        0;
    final String expiry =
        (productMap?['expiry'] ?? cartMap['expiry'] ?? '').toString();
    final String imageUrl =
        (productMap?['image'] ??
                productMap?['imageUrl'] ??
                cartMap['image'] ??
                cartMap['imageUrl'] ??
                '')
            .toString();
    final int quantity =
        int.tryParse((cartMap['quantity'] ?? '1').toString()) ?? 1;
    final int timestamp =
        int.tryParse((cartMap['timestamp'] ?? '$now').toString()) ?? now;

    List<String> suggestions = _parseSuggestions(productMap?['suggestions']);
    if (suggestions.isEmpty) {
      suggestions =
          _fallbackSuggestions[_slugify(itemId)] ??
          _fallbackSuggestions[_slugify(name)] ??
          <String>[];
    }

    return CartItem(
      id: itemId,
      name: name,
      price: price,
      expiry: expiry,
      imageUrl: imageUrl,
      suggestions: suggestions,
      quantity: quantity,
      timestamp: timestamp,
    );
  }

  List<String> _parseSuggestions(dynamic rawSuggestions) {
    if (rawSuggestions is List) {
      return rawSuggestions.whereType<dynamic>().map((e) => _slugify('$e')).toList();
    }
    return <String>[];
  }

  Future<Map<dynamic, dynamic>> _fetchProductsMap() async {
    try {
      final snapshot = await _productsRef.get();
      final dynamic value = snapshot.value;
      if (value is Map) {
        return value;
      }
    } catch (_) {
      // Fall back to local catalog.
    }

    final Map<String, dynamic> fallback = <String, dynamic>{};
    for (final entry in _fallbackCatalog.entries) {
      fallback[entry.key] = entry.value;
    }
    return fallback;
  }

  String _slugify(String value) {
    final normalized = value.toLowerCase().trim();
    final slug = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return slug.replaceAll(RegExp(r'^_+|_+$'), '');
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
    await _database.ref().update({
      'trolleys/$trolleyId/status': 'PAID',
      'trolleys/$trolleyId/cart_items': null,
    });
  }
}
