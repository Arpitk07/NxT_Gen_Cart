import 'package:flutter/material.dart';
import 'dart:async';
import '../models/cart_item_model.dart';
import '../services/realtime_db_service.dart';
import '../utils/expiry_utils.dart';

class CartProvider with ChangeNotifier {
  final RealtimeDBService _dbService;
  late StreamSubscription<List<CartItem>> _cartSubscription;

  List<CartItem> _items = [];
  bool _isLoading = true;
  String? _error;

  CartProvider(this._dbService) {
    _initStream();
  }

  void _initStream() {
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

  int get itemCount => _items.length;

  double get totalPrice {
    double total = 0.0;
    for (var item in _items) {
      total += item.mrp;
    }
    return total;
  }

  int get expiredCount => _items
      .where((item) =>
          ExpiryUtils.getExpiryStatus(item.expiryDate) == ExpiryStatus.expired)
      .length;

  int get nearExpiryCount => _items
      .where((item) =>
          ExpiryUtils.getExpiryStatus(item.expiryDate) ==
          ExpiryStatus.nearExpiry)
      .length;

  int get safeCount => _items
      .where((item) =>
          ExpiryUtils.getExpiryStatus(item.expiryDate) == ExpiryStatus.safe)
      .length;

  bool get hasExpiryWarnings => expiredCount > 0 || nearExpiryCount > 0;

  Future<void> checkout() async {
    await _dbService.checkout();
  }

  @override
  void dispose() {
    _cartSubscription.cancel();
    super.dispose();
  }
}
