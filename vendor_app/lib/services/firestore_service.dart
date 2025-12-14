import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import '../models/booking.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Category>> categoriesStream() {
    return _db
        .collection('categories')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return Category.fromMap(d.id, data);
          }).toList(),
        );
  }

  Future<void> addCategory(String name) async {
    await _db.collection('categories').add({'name': name});
  }

  Future<void> removeCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Future<void> addRestaurant(Restaurant r) async {
    // Create restaurant document, then create per-table documents under
    // restaurants/{id}/tables so customers can book specific tables.
    final ref = await _db.collection('restaurants').add(r.toMap());
    final batch = _db.batch();
    final tablesCount = r.numberOfTables;
    // Create per-table documents. Also assign default grid-based coordinates
    // (x,y) between 0..1 so the layout can render immediately without editor.
    final cols = tablesCount <= 4 ? tablesCount : 4;
    for (var i = 0; i < tablesCount; i++) {
      final seats = (i < r.seatsPerTable.length)
          ? r.seatsPerTable[i]
          : (r.seatsPerTable.isNotEmpty ? r.seatsPerTable.last : 4);
      final tableRef = _db
          .collection('restaurants')
          .doc(ref.id)
          .collection('tables')
          .doc();
      final col = i % cols;
      final row = (i / cols).floor();
      final rows = (tablesCount / cols).ceil();
      final x = cols <= 1 ? 0.5 : (col / (cols - 1));
      final y = rows <= 1 ? 0.5 : (row / (rows - 1));
      batch.set(tableRef, {
        'seats': seats,
        'label': 'Table ${i + 1}',
        'tableIndex': i + 1, // store as 1-based for clarity
        'x': x,
        'y': y,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<List<Restaurant>> restaurantsStream() {
    return _db
        .collection('restaurants')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Restaurant.fromSnapshot(d)).toList(),
        );
  }

  Stream<List<Restaurant>> restaurantsStreamForVendor(String vendorId) {
    return _db
        .collection('restaurants')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Restaurant.fromSnapshot(d)).toList(),
        );
  }

  Stream<Restaurant?> restaurantStream(String restaurantId) {
    return _db.collection('restaurants').doc(restaurantId).snapshots().map((
      snap,
    ) {
      if (!snap.exists) return null;
      return Restaurant.fromSnapshot(snap);
    });
  }

  Stream<List<Booking>> reservationsStreamForRestaurant(String restaurantId) {
    // Avoid requiring a composite index (where + orderBy) by fetching matching
    // documents and sorting client-side. This is simpler for development and
    // avoids needing to create indexes in Firebase Console.
    return _db
        .collection('bookings')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Booking.fromSnapshot(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> updateRestaurant(Restaurant r) async {
    await _db.collection('restaurants').doc(r.id).update(r.toMap());
  }
}
