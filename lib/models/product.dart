class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.minimumStock,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  int currentStock;
  final int minimumStock;
  final DateTime createdAt;

  bool get isLowStock => currentStock <= minimumStock;

  Product copyWith({
    String? name,
    String? description,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? currentStock,
    int? minimumStock,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      createdAt: createdAt,
    );
  }
}
