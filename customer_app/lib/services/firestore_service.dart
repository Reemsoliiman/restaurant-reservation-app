import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> streamRestaurants() {
    return _db.collection('restaurants').snapshots();
  }

  Future<DocumentSnapshot> getRestaurant(String id) {
    return _db.collection('restaurants').doc(id).get();
  }

  Stream<QuerySnapshot> streamTables(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .snapshots();
  }

  Future<QuerySnapshot> getTablesOnce(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .get();
  }

  Future<QuerySnapshot> getReservationsForDate(
      String restaurantId, String date) {
    // Reservations are stored in the `bookings` collection in this project.
    return _db
        .collection('bookings')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('date', isEqualTo: date)
        .get();
  }

  /// Stream reservations for a given restaurant and date so UI can react in real-time
  Stream<QuerySnapshot> streamReservationsForDate(
      String restaurantId, String date) {
    // Stream bookings for the given restaurant/date (named "reservations" in UI)
    return _db
        .collection('bookings')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('date', isEqualTo: date)
        .snapshots();
  }

  Future<void> bookTable({
    required String restaurantId,
    required String tableId,
    required String tableLabel,
    required int tableIndex,
    required String restaurantName,
    required String userId,
    required int seats,
    required String date,
    required String timeSlot,
    required String vendorId,
  }) async {
    // Create a deterministic lock document ID based on the booking slot
    final lockId = '${restaurantId}_${tableId}_${date}_${timeSlot.replaceAll(':', '')}';
    final lockRef = _db.collection('booking_locks').doc(lockId);
    final bookingsRef = _db.collection('bookings');

    try {
      // Fetch customer name before transaction
      String customerName = '';
      try {
        final userDoc = await _db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            final uname = data['username'] ?? data['customerName'];
            if (uname != null) customerName = uname.toString();
          }
        }
      } catch (e, st) {
        debugPrint('Warning: failed to fetch user name for $userId: $e\n$st');
      }

      return await _db.runTransaction((tx) async {
        // Check if lock document exists (this is atomic)
        final lockDoc = await tx.get(lockRef);

        if (lockDoc.exists) {
          final lockData = lockDoc.data();
          final status = lockData?['status']?.toString();
          
          // If status is not cancelled, slot is taken
          if (status != 'cancelled') {
            throw Exception('This time slot has just been booked by another customer. Please select a different time.');
          }
          // If cancelled, we can proceed to rebook by overwriting
        }

        // Create/Update lock document with booking data (prevents race condition)
        // Using SetOptions.merge() to ensure we can overwrite cancelled bookings
        tx.set(
          lockRef, 
          {
            'restaurantId': restaurantId,
            'restaurantName': restaurantName,
            'tableId': tableId,
            'tableNumber': tableLabel,
            'tableIndex': tableIndex,
            'customerId': userId,
            'customerName': customerName,
            'seats': seats,
            'date': date,
            'timeSlot': timeSlot,
            'status': 'confirmed',
            'updatedAt': FieldValue.serverTimestamp(),
            'vendorId': vendorId,
          },
          SetOptions(merge: false), // Overwrite completely, don't merge
        );

        // Also create in bookings collection for queries
        final bookingRef = bookingsRef.doc();
        tx.set(bookingRef, {
          'lockId': lockId,
          'restaurantId': restaurantId,
          'restaurantName': restaurantName,
          'tableId': tableId,
          'tableNumber': tableLabel,
          'tableIndex': tableIndex,
          'customerId': userId,
          'customerName': customerName,
          'seats': seats,
          'date': date,
          'timeSlot': timeSlot,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
          'vendorId': vendorId,
        });

        // Add notification for vendor
        final notifRef = _db.collection('notifications').doc();
        tx.set(notifRef, {
          'vendorId': vendorId,
          'restaurantId': restaurantId,
          'message': 'New booking for $date at $timeSlot',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      // rethrow with clearer message
      debugPrint('Firestore booking error: ${e.code} ${e.message}');
      throw Exception(e.message ?? 'Booking failed due to Firestore error');
    } catch (e) {
      debugPrint('Unknown booking error: $e');
      rethrow;
    }
  }

  /// Stream bookings for a given restaurant and date so UI can react in real-time
  Stream<QuerySnapshot> streamBookingsForDate(
      String restaurantId, String date) {
    return _db
        .collection('bookings')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('date', isEqualTo: date)
        .snapshots();
  }

  /// Stream bookings for a given user (customer)
  Stream<QuerySnapshot> streamBookingsForUser(String userId) {
    // Order by createdAt so the query does not require a composite index
    // `createdAt` is set at write time and is single-field-indexed by default.
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Cancel a booking by setting status to 'cancelled'
  Future<void> cancelBooking(String bookingId) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);
    
    // Get booking data to find the lock document
    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }
    
    final bookingData = bookingDoc.data();
    final lockId = bookingData?['lockId']?.toString();
    
    // Update both booking and lock document
    if (lockId != null) {
      final lockRef = _db.collection('booking_locks').doc(lockId);
      await _db.runTransaction((tx) async {
        tx.update(bookingRef, {'status': 'cancelled'});
        tx.update(lockRef, {'status': 'cancelled'});
      });
    } else {
      // Fallback: just update booking if no lockId (old bookings)
      await bookingRef.update({'status': 'cancelled'});
    }
  }
}
