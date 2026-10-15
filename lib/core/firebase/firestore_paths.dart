import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore references for the single-store RetailX deployment.
class StoreRefs {
  StoreRefs(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get settings => _db
      .collection('stores')
      .doc('default')
      .collection('settings')
      .doc('main');

  CollectionReference<Map<String, dynamic>> get products => _db
      .collection('stores')
      .doc('default')
      .collection('products');

  DocumentReference<Map<String, dynamic>> product(String id) =>
      products.doc(id);

  CollectionReference<Map<String, dynamic>> get customers => _db
      .collection('stores')
      .doc('default')
      .collection('customers');

  DocumentReference<Map<String, dynamic>> customer(String id) =>
      customers.doc(id);

  CollectionReference<Map<String, dynamic>> get suppliers => _db
      .collection('stores')
      .doc('default')
      .collection('suppliers');

  DocumentReference<Map<String, dynamic>> supplier(String id) =>
      suppliers.doc(id);

  CollectionReference<Map<String, dynamic>> get sales =>
      _db.collection('stores').doc('default').collection('sales');

  DocumentReference<Map<String, dynamic>> sale(String id) => sales.doc(id);

  CollectionReference<Map<String, dynamic>> get purchases => _db
      .collection('stores')
      .doc('default')
      .collection('purchases');

  DocumentReference<Map<String, dynamic>> purchase(String id) =>
      purchases.doc(id);

  CollectionReference<Map<String, dynamic>> get stockMovements => _db
      .collection('stores')
      .doc('default')
      .collection('stock_movements');

  DocumentReference<Map<String, dynamic>> stockMovement(String id) =>
      stockMovements.doc(id);

  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> user(String uid) => users.doc(uid);
}
