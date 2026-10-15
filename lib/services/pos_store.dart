import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/firebase/firestore_mappers.dart';
import '../core/firebase/firestore_paths.dart';
import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/sale.dart';
import '../models/sales_trend_point.dart';
import '../models/stock_movement.dart';
import '../models/store_settings.dart';
import '../models/supplier.dart';

class PosStore extends ChangeNotifier {
  PosStore() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  late final StoreRefs _refs = StoreRefs(_db);
  final List<StreamSubscription<dynamic>> _subs = [];

  StoreSettings settings = StoreSettings(
    storeName: 'RetailX Store',
    currencySymbol: '\$',
    taxRatePercent: 8,
    receiptFooter: 'Thank you for shopping with us!',
  );

  List<AppUser> users = [];
  List<Product> products = [];
  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  List<Sale> sales = [];
  List<PurchaseRecord> purchases = [];
  List<StockMovement> stockMovements = [];

  bool synced = false;

  final List<CartItem> _cart = [];
  String _cartSearch = '';
  double _cartDiscount = 0;
  String? _cartCustomerId;

  List<CartItem> get cart => List.unmodifiable(_cart);
  String get cartSearch => _cartSearch;
  double get cartDiscount => _cartDiscount;
  String? get cartCustomerId => _cartCustomerId;

  String _id() => _db.collection('_').doc().id;

  Future<void> attach() async {
    detach();
    await _ensureSettings();

    _subs.add(_refs.settings.snapshots().listen((snap) {
      if (!snap.exists) return;
      settings = StoreSettingsMap.fromMap(snap.data()!);
      notifyListeners();
    }));

    _subs.add(_refs.products.snapshots().listen((snap) {
      products = snap.docs
          .map((d) => ProductMap.fromDoc(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _syncCartProducts();
      synced = true;
      notifyListeners();
    }));

    _subs.add(_refs.customers.snapshots().listen((snap) {
      customers = snap.docs
          .map((d) => CustomerMap.fromDoc(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }));

    _subs.add(_refs.suppliers.snapshots().listen((snap) {
      suppliers = snap.docs
          .map((d) => SupplierMap.fromDoc(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }));

    _subs.add(
      _refs.sales.orderBy('createdAt', descending: true).snapshots().listen(
        (snap) {
          sales =
              snap.docs.map((d) => SaleMap.fromDoc(d.id, d.data())).toList();
          notifyListeners();
        },
      ),
    );

    _subs.add(
      _refs.purchases.orderBy('createdAt', descending: true).snapshots().listen(
        (snap) {
          purchases = snap.docs
              .map((d) => PurchaseRecordMap.fromDoc(d.id, d.data()))
              .toList();
          notifyListeners();
        },
      ),
    );

    _subs.add(
      _refs.stockMovements
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snap) {
        stockMovements = snap.docs
            .map((d) => StockMovementMap.fromDoc(d.id, d.data()))
            .toList();
        notifyListeners();
      }),
    );

    _subs.add(_refs.users.snapshots().listen((snap) {
      users = snap.docs
          .map((d) => AppUserMap.fromDoc(d.id, d.data()))
          .where((u) => u.active)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }));
  }

  void detach() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    users = [];
    products = [];
    customers = [];
    suppliers = [];
    sales = [];
    purchases = [];
    stockMovements = [];
    synced = false;
    clearCart();
    notifyListeners();
  }

  Future<void> _ensureSettings() async {
    final snap = await _refs.settings.get();
    if (!snap.exists) {
      await _refs.settings.set(
        settings.toMap(receiptCounter: 10000),
        SetOptions(merge: true),
      );
    }
  }

  void _syncCartProducts() {
    _cart.removeWhere((c) => productById(c.product.id) == null);
    for (var i = 0; i < _cart.length; i++) {
      final p = productById(_cart[i].product.id)!;
      _cart[i] = CartItem(product: p, quantity: _cart[i].quantity);
    }
  }

  List<String> get categories {
    final set = products.map((p) => p.category).toSet().toList()..sort();
    return set;
  }

  Future<void> updateSettings(StoreSettings next) async {
    await _refs.settings.set(next.toMap(), SetOptions(merge: true));
  }

  Future<String?> updateUser(AppUser user) async {
    try {
      await _refs.user(user.id).update({
        'name': user.name,
        'email': user.email,
        'role': user.role.name,
      });
      return null;
    } catch (e) {
      return 'Could not update user';
    }
  }

  Future<String?> deleteUser(String id) async {
    final user = users.where((u) => u.id == id).firstOrNull;
    if (user == null) return 'User not found';
    if (user.role == UserRole.admin) {
      return 'Admin accounts cannot be deleted';
    }
    try {
      await _refs.user(id).update({'active': false});
      return null;
    } catch (e) {
      return 'Could not delete cashier';
    }
  }

  List<AppUser> get cashiers =>
      users.where((u) => u.role == UserRole.cashier).toList();

  List<Sale> salesForCashier(String cashierId) =>
      sales.where((s) => s.cashierId == cashierId).toList();

  Future<void> addProduct(Product product) async {
    final batch = _db.batch();
    batch.set(_refs.product(product.id), product.toMap());
    final moveId = _id();
    batch.set(_refs.stockMovement(moveId), {
      ...StockMovement(
        id: moveId,
        productId: product.id,
        productName: product.name,
        type: StockMovementType.initial,
        quantityChange: product.currentStock,
        stockAfter: product.currentStock,
        reference: 'Product created',
        createdAt: DateTime.now(),
      ).toMap(),
    });
    await batch.commit();
  }

  Future<void> updateProduct(Product product) async {
    await _refs.product(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _refs.product(id).delete();
  }

  /// Writes up to hundreds of products in chunked Firestore batches.
  Future<int> importProductsBulk(List<Product> products) async {
    if (products.isEmpty) return 0;

    const chunkSize = 200;
    var imported = 0;

    for (var start = 0; start < products.length; start += chunkSize) {
      final end = (start + chunkSize > products.length)
          ? products.length
          : start + chunkSize;
      final chunk = products.sublist(start, end);
      final batch = _db.batch();
      final now = DateTime.now();

      for (final product in chunk) {
        batch.set(_refs.product(product.id), product.toMap());
        final moveId = _id();
        batch.set(
          _refs.stockMovement(moveId),
          {
            ...StockMovement(
              id: moveId,
              productId: product.id,
              productName: product.name,
              type: StockMovementType.initial,
              quantityChange: product.currentStock,
              stockAfter: product.currentStock,
              reference: 'Bulk import',
              createdAt: now,
            ).toMap(),
          },
        );
      }
      await batch.commit();
      imported += chunk.length;
    }

    return imported;
  }

  Product? productById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await _refs.customer(customer.id).set(customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _refs.customer(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _refs.customer(id).delete();
  }

  List<Sale> salesForCustomer(String customerId) =>
      sales.where((s) => s.customerId == customerId).toList();

  Future<Customer?> _upsertCustomer({
    required String name,
    required String phone,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final existing = customers.where((c) {
      return c.phone.replaceAll(RegExp(r'\s+'), '') == normalizedPhone;
    }).firstOrNull;

    if (existing != null) {
      final updated = existing.copyWith(
        name: name.trim(),
        phone: phone.trim(),
      );
      await updateCustomer(updated);
      return updated;
    }

    final customer = Customer(
      id: _id(),
      name: name.trim(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );
    await addCustomer(customer);
    return customer;
  }

  Future<void> addSupplier(Supplier supplier) async {
    await _refs.supplier(supplier.id).set(supplier.toMap());
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _refs.supplier(supplier.id).update(supplier.toMap());
  }

  Future<void> deleteSupplier(String id) async {
    await _refs.supplier(id).delete();
  }

  List<PurchaseRecord> purchasesForSupplier(String supplierId) =>
      purchases.where((p) => p.supplierId == supplierId).toList();

  Future<void> addStock({
    required String productId,
    required int quantity,
    required String reference,
    StockMovementType type = StockMovementType.adjustment,
  }) async {
    if (quantity <= 0) return;
    final p = productById(productId);
    if (p == null) return;

    final newStock = p.currentStock + quantity;
    final moveId = _id();
    final batch = _db.batch();
    batch.update(_refs.product(productId), {'currentStock': newStock});
    batch.set(_refs.stockMovement(moveId), {
      ...StockMovement(
        id: moveId,
        productId: p.id,
        productName: p.name,
        type: type,
        quantityChange: quantity,
        stockAfter: newStock,
        reference: reference,
        createdAt: DateTime.now(),
      ).toMap(),
    });
    await batch.commit();
  }

  Future<void> recordPurchase({
    required String supplierId,
    required List<PurchaseLineItem> items,
    required String note,
  }) async {
    final supplier = suppliers.firstWhere((s) => s.id == supplierId);
    final total = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final recordId = _id();
    final record = PurchaseRecord(
      id: recordId,
      supplierId: supplierId,
      supplierName: supplier.name,
      items: items,
      total: total,
      createdAt: DateTime.now(),
      note: note,
    );

    final batch = _db.batch();
    batch.set(_refs.purchase(recordId), record.toMap());

    for (final item in items) {
      final p = productById(item.productId);
      if (p == null) continue;
      final newStock = p.currentStock + item.quantity;
      batch.update(_refs.product(item.productId), {
        'currentStock': newStock,
      });
      final moveId = _id();
      batch.set(_refs.stockMovement(moveId), {
        ...StockMovement(
          id: moveId,
          productId: p.id,
          productName: p.name,
          type: StockMovementType.purchase,
          quantityChange: item.quantity,
          stockAfter: newStock,
          reference: 'Purchase $recordId',
          createdAt: DateTime.now(),
        ).toMap(),
      });
    }
    await batch.commit();
  }

  void setCartSearch(String value) {
    _cartSearch = value;
    notifyListeners();
  }

  void setCartDiscount(double value) {
    _cartDiscount = value < 0 ? 0 : value;
    notifyListeners();
  }

  void setCartCustomer(String? customerId) {
    _cartCustomerId = customerId;
    notifyListeners();
  }

  List<Product> productsForPos() {
    final q = _cartSearch.trim().toLowerCase();
    if (q.isEmpty) return products.where((p) => p.currentStock > 0).toList();
    return products
        .where(
          (p) =>
              p.currentStock > 0 &&
              (p.name.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q)),
        )
        .toList();
  }

  void addToCart(Product product, {int qty = 1}) {
    final existing = _cart.where((c) => c.product.id == product.id).firstOrNull;
    if (existing != null) {
      final newQty = existing.quantity + qty;
      if (newQty <= product.currentStock) {
        existing.quantity = newQty;
      }
    } else {
      if (qty <= product.currentStock) {
        _cart.add(CartItem(product: product, quantity: qty));
      }
    }
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    final item = _cart.where((c) => c.product.id == productId).firstOrNull;
    if (item == null) return;
    if (quantity <= 0) {
      _cart.remove(item);
    } else if (quantity <= item.product.currentStock) {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _cartDiscount = 0;
    _cartCustomerId = null;
    _cartSearch = '';
    notifyListeners();
  }

  double get cartSubtotal =>
      _cart.fold(0, (sum, item) => sum + item.lineTotal);

  double cartTaxAmount() =>
      (cartSubtotal - _cartDiscount) * settings.taxRatePercent / 100;

  double cartTotal() =>
      cartSubtotal - _cartDiscount + cartTaxAmount();

  Future<Sale?> completeSale({
    required PaymentMethod paymentMethod,
    required String cashierName,
    required String cashierId,
    required String customerName,
    required String customerPhone,
    double? amountReceived,
  }) async {
    if (_cart.isEmpty) return null;

    for (final item in _cart) {
      if (item.quantity > item.product.currentStock) return null;
    }

    final subtotal = cartSubtotal;
    final discount = _cartDiscount;
    final tax = cartTaxAmount();
    final total = cartTotal();

    double? change;
    if (paymentMethod == PaymentMethod.cash) {
      if (amountReceived == null || amountReceived < total) return null;
      change = amountReceived - total;
    }

    Customer? customer;
    final trimmedName = customerName.trim();
    final trimmedPhone = customerPhone.trim();
    if (trimmedName.isNotEmpty || trimmedPhone.isNotEmpty) {
      customer = await _upsertCustomer(
        name: trimmedName.isEmpty ? 'Walk-in customer' : trimmedName,
        phone: trimmedPhone.isEmpty ? '—' : trimmedPhone,
      );
    }

    final saleId = _id();
    late String receiptNumber;

    await _db.runTransaction((tx) async {
      final settingsSnap = await tx.get(_refs.settings);
      var counter =
          (settingsSnap.data()?['receiptCounter'] as num?)?.toInt() ?? 10000;
      receiptNumber = 'RX-$counter';
      tx.set(
        _refs.settings,
        {'receiptCounter': counter + 1},
        SetOptions(merge: true),
      );
    });

    final saleItems = _cart
        .map(
          (c) => SaleLineItem(
            productId: c.product.id,
            productName: c.product.name,
            unitPrice: c.product.sellingPrice,
            quantity: c.quantity,
          ),
        )
        .toList();

    final sale = Sale(
      id: saleId,
      receiptNumber: receiptNumber,
      items: saleItems,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      cashierName: cashierName,
      cashierId: cashierId,
      customerId: customer?.id,
      customerName: customer?.name,
      customerPhone: customer?.phone,
      amountReceived: amountReceived,
      changeGiven: change,
    );

    final batch = _db.batch();
    batch.set(_refs.sale(saleId), sale.toMap());

    for (final item in _cart) {
      final p = productById(item.product.id)!;
      final newStock = p.currentStock - item.quantity;
      batch.update(_refs.product(p.id), {'currentStock': newStock});
      final moveId = _id();
      batch.set(_refs.stockMovement(moveId), {
        ...StockMovement(
          id: moveId,
          productId: p.id,
          productName: p.name,
          type: StockMovementType.sale,
          quantityChange: -item.quantity,
          stockAfter: newStock,
          reference: receiptNumber,
          createdAt: DateTime.now(),
        ).toMap(),
      });
    }

    await batch.commit();
    clearCart();
    return sale;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Sale> salesToday() {
    final now = DateTime.now();
    return sales.where((s) => _isSameDay(s.createdAt, now)).toList();
  }

  double todaySalesTotal() =>
      salesToday().fold(0, (sum, s) => sum + s.total);

  int todayOrdersCount() => salesToday().length;

  int lowStockCount() => products.where((p) => p.isLowStock).length;

  List<Sale> salesInRange(DateTime start, DateTime end) {
    return sales
        .where(
          (s) =>
              !s.createdAt.isBefore(start) &&
              s.createdAt.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  double revenueForSales(List<Sale> list) =>
      list.fold(0, (sum, s) => sum + s.total);

  double estimatedProfitForSales(List<Sale> list) {
    double profit = 0;
    for (final sale in list) {
      for (final line in sale.items) {
        final product = productById(line.productId);
        if (product != null) {
          profit +=
              (line.unitPrice - product.purchasePrice) * line.quantity;
        }
      }
    }
    return profit;
  }

  List<MapEntry<String, int>> topSellingProducts({int limit = 5}) {
    return topSellingProductsInRange(
      DateTime(2000),
      DateTime.now().add(const Duration(days: 3650)),
      limit: limit,
    );
  }

  List<MapEntry<String, int>> topSellingProductsInRange(
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) {
    final inRange = salesInRange(start, end);
    final counts = <String, int>{};
    for (final sale in inRange) {
      for (final line in sale.items) {
        counts[line.productName] =
            (counts[line.productName] ?? 0) + line.quantity;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  Map<PaymentMethod, double> revenueByPaymentMethod(List<Sale> list) {
    final map = <PaymentMethod, double>{};
    for (final method in PaymentMethod.values) {
      map[method] = 0;
    }
    for (final sale in list) {
      map[sale.paymentMethod] =
          (map[sale.paymentMethod] ?? 0) + sale.total;
    }
    return map;
  }

  Map<String, int> stockUnitsByCategory() {
    final map = <String, int>{};
    for (final p in products) {
      map[p.category] = (map[p.category] ?? 0) + p.currentStock;
    }
    return map;
  }

  List<SalesTrendPoint> salesTrendForRange(
    DateTime start,
    DateTime end, {
    required bool hourly,
  }) {
    if (hourly) {
      final day = DateTime(start.year, start.month, start.day);
      return List.generate(24, (h) {
        final hourSales = sales.where((s) {
          return _isSameDay(s.createdAt, day) && s.createdAt.hour == h;
        }).toList();
        final label = h == 0
            ? '12a'
            : h < 12
                ? '${h}a'
                : h == 12
                    ? '12p'
                    : '${h - 12}p';
        return SalesTrendPoint(
          label: label,
          revenue: revenueForSales(hourSales),
          profit: estimatedProfitForSales(hourSales),
          orders: hourSales.length,
        );
      });
    }

    final points = <SalesTrendPoint>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(endDay)) {
      final daySales =
          sales.where((s) => _isSameDay(s.createdAt, cursor)).toList();
      final label = '${cursor.month}/${cursor.day}';
      points.add(
        SalesTrendPoint(
          label: label,
          revenue: revenueForSales(daySales),
          profit: estimatedProfitForSales(daySales),
          orders: daySales.length,
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return points;
  }

  List<double> last7DaysSales() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final daySales = sales.where((s) => _isSameDay(s.createdAt, day));
      return daySales.fold(0.0, (sum, s) => sum + s.total);
    });
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
