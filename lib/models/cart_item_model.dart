class CartItem {
  final String productId;
  final String productName;
  final double mrp;
  final String expiryDate;

  CartItem({
    required this.productId,
    required this.productName,
    required this.mrp,
    required this.expiryDate,
  });

  /// Parse a single flat snapshot from the root node
  factory CartItem.fromMap(Map<dynamic, dynamic> map) {
    return CartItem(
      productId: (map['Product ID'] ?? '').toString(),
      productName: (map['Product name'] ?? '').toString(),
      mrp: double.tryParse(map['MRP']?.toString() ?? '0') ?? 0.0,
      expiryDate: (map['Expiry Date'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Product ID': productId,
      'Product name': productName,
      'MRP': mrp.toString(),
      'Expiry Date': expiryDate,
    };
  }
}
