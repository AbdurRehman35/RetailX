import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/enums.dart';
import '../../models/app_user.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/purchase_record.dart';
import '../../models/sale.dart';
import '../../models/stock_movement.dart';
import '../../models/store_settings.dart';
import '../../models/supplier.dart';

DateTime _dt(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return DateTime.now();
}

extension StoreSettingsMap on StoreSettings {
  Map<String, dynamic> toMap({int? receiptCounter}) => {
        'storeName': storeName,
        'currencySymbol': currencySymbol,
        'taxRatePercent': taxRatePercent,
        'receiptFooter': receiptFooter,
        if (receiptCounter != null) 'receiptCounter': receiptCounter,
      };

  static StoreSettings fromMap(Map<String, dynamic> m) => StoreSettings(
        storeName: m['storeName'] as String? ?? 'RetailX Store',
        currencySymbol: m['currencySymbol'] as String? ?? '\$',
        taxRatePercent: (m['taxRatePercent'] as num?)?.toDouble() ?? 8,
        receiptFooter:
            m['receiptFooter'] as String? ?? 'Thank you for shopping with us!',
      );
}

extension AppUserFirestore on AppUser {
  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.name,
        'active': active,
      };
}

class AppUserMap {
  AppUserMap._();

  static AppUser fromDoc(String id, Map<String, dynamic> m) => AppUser(
        id: id,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        password: '',
        role: UserRole.values.byName(m['role'] as String? ?? 'cashier'),
        active: m['active'] as bool? ?? true,
      );
}

extension ProductMap on Product {
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'currentStock': currentStock,
        'minimumStock': minimumStock,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static Product fromDoc(String id, Map<String, dynamic> m) => Product(
        id: id,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        category: m['category'] as String? ?? '',
        purchasePrice: (m['purchasePrice'] as num?)?.toDouble() ?? 0,
        sellingPrice: (m['sellingPrice'] as num?)?.toDouble() ?? 0,
        currentStock: (m['currentStock'] as num?)?.toInt() ?? 0,
        minimumStock: (m['minimumStock'] as num?)?.toInt() ?? 0,
        createdAt: _dt(m['createdAt']),
      );
}

extension CustomerMap on Customer {
  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static Customer fromDoc(String id, Map<String, dynamic> m) => Customer(
        id: id,
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        createdAt: _dt(m['createdAt']),
      );
}

extension SupplierMap on Supplier {
  Map<String, dynamic> toMap() => {
        'name': name,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static Supplier fromDoc(String id, Map<String, dynamic> m) => Supplier(
        id: id,
        name: m['name'] as String? ?? '',
        contactPerson: m['contactPerson'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String? ?? '',
        address: m['address'] as String? ?? '',
        createdAt: _dt(m['createdAt']),
      );
}

extension SaleMap on Sale {
  Map<String, dynamic> toMap() => {
        'receiptNumber': receiptNumber,
        'items': items
            .map(
              (i) => {
                'productId': i.productId,
                'productName': i.productName,
                'unitPrice': i.unitPrice,
                'quantity': i.quantity,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'paymentMethod': paymentMethod.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'cashierName': cashierName,
        'cashierId': cashierId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'amountReceived': amountReceived,
        'changeGiven': changeGiven,
      };

  static Sale fromDoc(String id, Map<String, dynamic> m) {
    final rawItems = m['items'] as List<dynamic>? ?? [];
    return Sale(
      id: id,
      receiptNumber: m['receiptNumber'] as String? ?? id,
      items: rawItems.map((e) {
        final i = e as Map<String, dynamic>;
        return SaleLineItem(
          productId: i['productId'] as String? ?? '',
          productName: i['productName'] as String? ?? '',
          unitPrice: (i['unitPrice'] as num?)?.toDouble() ?? 0,
          quantity: (i['quantity'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (m['discount'] as num?)?.toDouble() ?? 0,
      tax: (m['tax'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.values
          .byName(m['paymentMethod'] as String? ?? 'cash'),
      createdAt: _dt(m['createdAt']),
      cashierName: m['cashierName'] as String? ?? '',
      cashierId: m['cashierId'] as String? ?? '',
      customerId: m['customerId'] as String?,
      customerName: m['customerName'] as String?,
      customerPhone: m['customerPhone'] as String?,
      amountReceived: (m['amountReceived'] as num?)?.toDouble(),
      changeGiven: (m['changeGiven'] as num?)?.toDouble(),
    );
  }
}

extension PurchaseRecordMap on PurchaseRecord {
  Map<String, dynamic> toMap() => {
        'supplierId': supplierId,
        'supplierName': supplierName,
        'items': items
            .map(
              (i) => {
                'productId': i.productId,
                'productName': i.productName,
                'quantity': i.quantity,
                'unitCost': i.unitCost,
              },
            )
            .toList(),
        'total': total,
        'createdAt': Timestamp.fromDate(createdAt),
        'note': note,
      };

  static PurchaseRecord fromDoc(String id, Map<String, dynamic> m) {
    final rawItems = m['items'] as List<dynamic>? ?? [];
    return PurchaseRecord(
      id: id,
      supplierId: m['supplierId'] as String? ?? '',
      supplierName: m['supplierName'] as String? ?? '',
      items: rawItems.map((e) {
        final i = e as Map<String, dynamic>;
        return PurchaseLineItem(
          productId: i['productId'] as String? ?? '',
          productName: i['productName'] as String? ?? '',
          quantity: (i['quantity'] as num?)?.toInt() ?? 0,
          unitCost: (i['unitCost'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
      total: (m['total'] as num?)?.toDouble() ?? 0,
      createdAt: _dt(m['createdAt']),
      note: m['note'] as String? ?? '',
    );
  }
}

extension StockMovementMap on StockMovement {
  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'type': type.name,
        'quantityChange': quantityChange,
        'stockAfter': stockAfter,
        'reference': reference,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static StockMovement fromDoc(String id, Map<String, dynamic> m) =>
      StockMovement(
        id: id,
        productId: m['productId'] as String? ?? '',
        productName: m['productName'] as String? ?? '',
        type: StockMovementType.values.byName(m['type'] as String? ?? 'adjustment'),
        quantityChange: (m['quantityChange'] as num?)?.toInt() ?? 0,
        stockAfter: (m['stockAfter'] as num?)?.toInt() ?? 0,
        reference: m['reference'] as String? ?? '',
        createdAt: _dt(m['createdAt']),
      );
}
