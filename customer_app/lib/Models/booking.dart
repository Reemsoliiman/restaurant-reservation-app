class Booking {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String tableId;
  final String tableNumber;
  final String customerId;
  final String customerName;
  final int seats;
  final String date;
  final String timeSlot;
  final String status;

  Booking({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.tableId,
    required this.tableNumber,
    required this.customerId,
    required this.customerName,
    required this.seats,
    required this.date,
    required this.timeSlot,
    required this.status,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> m) {
    int parseIntSafe(Object? v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Booking(
      id: id,
      restaurantId: m['restaurantId']?.toString() ?? '',
      restaurantName: m['restaurantName']?.toString() ?? '',
      tableId: m['tableId']?.toString() ?? '',
      tableNumber: m['tableNumber']?.toString() ?? '',
      customerId: m['customerId']?.toString() ?? '',
      customerName: m['customerName']?.toString() ?? '',
      seats: parseIntSafe(m['seats']),
      date: m['date']?.toString() ?? '',
      timeSlot: m['timeSlot']?.toString() ?? '',
      status: m['status']?.toString() ?? '',
    );
  }
}
