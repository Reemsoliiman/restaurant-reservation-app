import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String restaurantId;
  final int tableIndex;
  final int seats;
  final String timeSlot;
  final String date;
  final String status;
  final Timestamp createdAt;

  Booking({
    required this.id,
    required this.restaurantId,
    required this.tableIndex,
    required this.seats,
    required this.timeSlot,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromSnapshot(DocumentSnapshot snap) {
    final raw = snap.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
    int parseIntSafe(Object? v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final created = data['createdAt'];
    final createdAt = (created is Timestamp) ? created : Timestamp.now();

    return Booking(
      id: snap.id,
      restaurantId: data['restaurantId']?.toString() ?? '',
      tableIndex: parseIntSafe(data['tableIndex']),
      seats: parseIntSafe(data['seats']),
      timeSlot: data['timeSlot']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      createdAt: createdAt,
    );
  }
}
