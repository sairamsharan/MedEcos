class InventoryItem {
  final String id;
  final String medicineName;
  final int quantity;
  final double price;
  final DateTime? expiryDate;

  InventoryItem({
    required this.id,
    required this.medicineName,
    required this.quantity,
    required this.price,
    this.expiryDate,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? '',
      medicineName: json['medicineName'] ?? 'Unknown',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
    );
  }
}
