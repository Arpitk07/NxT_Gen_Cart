import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/realtime_db_service.dart';
import '../utils/expiry_utils.dart';

class CartProvider with ChangeNotifier {
  final RealtimeDBService _dbService;

  StreamSubscription<List<CartItem>>? _cartSubscription;
  final Set<String> _recentlyAddedItemIds = <String>{};
  final Map<String, Timer> _recentItemTimers = <String, Timer>{};
  final Map<String, List<CartItem>> _suggestionsByItemId =
      <String, List<CartItem>>{};
  final Set<String> _loadingSuggestionsFor = <String>{};

  List<CartItem> _catalogProducts = <CartItem>[];
  List<CartItem> _items = <CartItem>[];

  bool _isLoading = true;
  String? _error;
  double _taxRate = 0.05;

  CartProvider(this._dbService) {
    _initStream();
  }

  List<CartItem> get items => _items;
  List<CartItem> get catalogProducts => _catalogProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get taxRate => _taxRate;
  String get trolleyId => _dbService.trolleyId;

  int get itemCount => _items.length;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  double get tax => subtotal * _taxRate;
  double get total => subtotal + tax;
  double get totalPrice => total;

  int get expiredCount => _items
      .where(
        (item) =>
            ExpiryUtils.getExpiryStatus(item.expiry) == ExpiryStatus.expired,
      )
      .length;

  int get nearExpiryCount => _items
      .where(
        (item) =>
            ExpiryUtils.getExpiryStatus(item.expiry) == ExpiryStatus.nearExpiry,
      )
      .length;

  bool get hasExpiryWarnings => expiredCount > 0 || nearExpiryCount > 0;
  bool get hasExpiredItems => expiredCount > 0;

  set taxRate(double value) {
    if (value < 0) {
      throw ArgumentError('taxRate cannot be negative');
    }
    _taxRate = value;
    notifyListeners();
  }

  bool isRecentlyAdded(String itemId) => _recentlyAddedItemIds.contains(itemId);

  bool isSuggestionsLoading(String itemId) =>
      _loadingSuggestionsFor.contains(itemId);

  bool hasSuggestionsLoaded(String itemId) =>
      _suggestionsByItemId.containsKey(itemId);

  List<CartItem> getSuggestionsFor(String itemId) =>
      _suggestionsByItemId[itemId] ?? <CartItem>[];

  void _initStream() {
    _cartSubscription?.cancel();
    _cartSubscription = _dbService.getCartItemsStream().listen(
      (itemsList) {
        final Set<String> previousIds = _items.map((e) => e.id).toSet();
        _items = itemsList;
        final Set<String> nextIds = _items.map((e) => e.id).toSet();
        _trackRecentlyAdded(previousIds, nextIds);
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> checkout() async {
    if (hasExpiredItems) {
      throw StateError('Checkout blocked: cart contains expired items.');
    }
    await _dbService.checkout();
  }

  Future<void> addOrIncrementItem(CartItem item, {int quantityIncrement = 1}) async {
    _error = null;
    notifyListeners();
    try {
      await _dbService.addOrIncrementItem(
        itemId: item.id,
        name: item.name,
        price: item.price,
        expiry: item.expiry,
        imageUrl: item.imageUrl,
        quantityIncrement: quantityIncrement,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> decrementItem(String itemId) async {
    _error = null;
    notifyListeners();
    try {
      await _dbService.decrementItem(itemId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    _error = null;
    notifyListeners();
    try {
      await _dbService.removeItem(itemId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addCatalogProduct(String productId, {int quantityIncrement = 1}) async {
    _error = null;
    notifyListeners();
    try {
      await _dbService.addCatalogProduct(
        productId,
        quantityIncrement: quantityIncrement,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    _error = null;
    notifyListeners();
    try {
      await _dbService.clearCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> retryConnection() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _initStream();
  }

  Future<void> loadSuggestionsFor(CartItem item) async {
    if (_suggestionsByItemId.containsKey(item.id) ||
        _loadingSuggestionsFor.contains(item.id)) {
      return;
    }

    _loadingSuggestionsFor.add(item.id);
    notifyListeners();

    try {
      _suggestionsByItemId[item.id] = await _dbService.getSuggestedProducts(item);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingSuggestionsFor.remove(item.id);
      notifyListeners();
    }
  }

  Future<void> loadCatalogProducts() async {
    try {
      _catalogProducts = await _dbService.getCatalogProducts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _trackRecentlyAdded(Set<String> previousIds, Set<String> nextIds) {
    final removedIds = previousIds.difference(nextIds);
    for (final id in removedIds) {
      _recentlyAddedItemIds.remove(id);
      _recentItemTimers.remove(id)?.cancel();
      _suggestionsByItemId.remove(id);
      _loadingSuggestionsFor.remove(id);
    }

    final addedIds = nextIds.difference(previousIds);
    for (final id in addedIds) {
      _recentlyAddedItemIds.add(id);
      _recentItemTimers.remove(id)?.cancel();
      _recentItemTimers[id] = Timer(const Duration(seconds: 2), () {
        _recentlyAddedItemIds.remove(id);
        _recentItemTimers.remove(id);
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    for (final timer in _recentItemTimers.values) {
      timer.cancel();
    }
    _recentItemTimers.clear();
    super.dispose();
  }
}
