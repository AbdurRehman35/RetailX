class PurchaseLineItem {
  PurchaseLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitCost;

  double get lineTotal => unitCost * quantity;
}

class PurchaseRecord {
  PurchaseRecord({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.note,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final List<PurchaseLineItem> items;
  final double total;
  final DateTime createdAt;
  final String note;
}
