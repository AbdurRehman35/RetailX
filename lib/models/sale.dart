import '../core/constants/enums.dart';

class SaleLineItem {
  SaleLineItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;
}

class Sale {
  Sale({
    required this.id,
    required this.receiptNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.cashierName,
    required this.cashierId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.amountReceived,
    this.changeGiven,
  });

  final String id;
  final String receiptNumber;
  final List<SaleLineItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final String cashierName;
  final String cashierId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final double? amountReceived;
  final double? changeGiven;

  double get estimatedProfit => items.fold<double>(0, (sum, item) {
        return sum + item.lineTotal;
      });
}
