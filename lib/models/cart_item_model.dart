class CartItem {
  final String id;
  final String name;
  final double price;
  final String expiry;
  final int quantity;
  final int timestamp;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.expiry,
    required this.quantity,
    required this.timestamp,
  });

  factory CartItem.fromMap(String id, Map<dynamic, dynamic> map) {
    return CartItem(
      id: id,
      name: (map['name'] ?? '').toString(),
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      expiry: (map['expiry'] ?? '').toString(),
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      timestamp: int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'expiry': expiry,
      'quantity': quantity,
      'timestamp': timestamp,
    };
  }
}
