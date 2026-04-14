import 'package:flutter/material.dart';
import 'dart:async';
import '../models/cart_item_model.dart';
import '../services/realtime_db_service.dart';
import '../utils/expiry_utils.dart';

class CartProvider with ChangeNotifier {
  final RealtimeDBService _dbService;
  StreamSubscription<List<CartItem>>? _cartSubscription;
  double _taxRate = 0.05;

  List<CartItem> _items = [];
  bool _isLoading = true;
  String? _error;

  CartProvider(this._dbService) {
    _initStream();
  }

  void _initStream() {
    _cartSubscription?.cancel();
    _cartSubscription = _dbService.getCartItemsStream().listen(
      (itemsList) {
        _items = itemsList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = error.toString();
        debugPrint('CartProvider stream error: $error');
        notifyListeners();
      },
    );
  }

  List<CartItem> get items => _items;

  bool get isLoading => _isLoading;

  String? get error => _error;

  double get taxRate => _taxRate;

  set taxRate(double value) {
    if (value < 0) {
      throw ArgumentError('taxRate cannot be negative');
    }
    _taxRate = value;
    notifyListeners();
  }

  int get totalItems =>
      _items.fold(0, (running, item) => running + item.quantity);

  int get itemCount => _items.length;

  double get subtotal {
    return _items.fold(
      0.0,
      (running, item) => running + (item.price * item.quantity),
    );
  }

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

  int get safeCount => _items
      .where(
        (item) => ExpiryUtils.getExpiryStatus(item.expiry) == ExpiryStatus.safe,
      )
      .length;

  bool get hasExpiryWarnings => expiredCount > 0 || nearExpiryCount > 0;

  bool get hasExpiredItems => expiredCount > 0;

  Future<void> checkout() async {
    if (hasExpiredItems) {
      throw StateError('Checkout blocked: cart contains expired items.');
    }
    await _dbService.checkout();
  }

  Future<void> addOrIncrementItem({
    required String itemId,
    required String name,
    required double price,
    required String expiry,
    int quantityIncrement = 1,
    int? timestamp,
  }) async {
    try {
      _error = null;
      await _dbService.addOrIncrementItem(
        itemId: itemId,
        name: name,
        price: price,
        expiry: expiry,
        quantityIncrement: quantityIncrement,
        timestamp: timestamp,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      _error = null;
      await _dbService.removeItem(itemId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> decrementItem(String itemId) async {
    try {
      _error = null;
      await _dbService.decrementItem(itemId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      _error = null;
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

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
