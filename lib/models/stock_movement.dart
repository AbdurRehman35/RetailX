import '../core/constants/enums.dart';

class StockMovement {
  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantityChange,
    required this.stockAfter,
    required this.reference,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantityChange;
  final int stockAfter;
  final String reference;
  final DateTime createdAt;
}
