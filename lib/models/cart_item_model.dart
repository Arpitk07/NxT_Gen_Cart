class CartItem {
  final String id;
  final String name;
  final double price;
  final String expiry;
  final String imageUrl;
  final List<String> suggestions;
  final int quantity;
  final int timestamp;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.expiry,
    required this.imageUrl,
    this.suggestions = const <String>[],
    required this.quantity,
    required this.timestamp,
  });

  factory CartItem.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawSuggestions = map['suggestions'];
    final suggestions = rawSuggestions is List
        ? rawSuggestions.whereType<dynamic>().map((e) => '$e').toList()
        : <String>[];

    return CartItem(
      id: id,
      name: (map['name'] ?? '').toString(),
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      expiry: (map['expiry'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? map['image'] ?? '').toString(),
      suggestions: suggestions,
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      timestamp: int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0,
    );
  }

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    String? expiry,
    String? imageUrl,
    List<String>? suggestions,
    int? quantity,
    int? timestamp,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      expiry: expiry ?? this.expiry,
      imageUrl: imageUrl ?? this.imageUrl,
      suggestions: suggestions ?? this.suggestions,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'expiry': expiry,
      'imageUrl': imageUrl,
      'suggestions': suggestions,
      'quantity': quantity,
      'timestamp': timestamp,
    };
  }
}
