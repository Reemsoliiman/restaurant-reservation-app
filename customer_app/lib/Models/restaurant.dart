import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String category;
  final String description;
  final String? imageUrl;
  final String? vendorId;
  final int numberOfTables;
  final List<int> seatsPerTable;
  final List<String> timeSlots;
  final GeoPoint? location;

  Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.imageUrl,
    this.vendorId,
    this.numberOfTables = 0,
    this.seatsPerTable = const [],
    this.timeSlots = const [],
    this.location,
  });

  factory Restaurant.fromMap(String id, Map<String, dynamic> map) {
    List<int> parseSeats(Object? v) {
      if (v is List) {
        return v.map((e) {
          if (e is int) return e;
          return int.tryParse(e?.toString() ?? '') ?? 0;
        }).toList();
      }
      return <int>[];
    }

    List<String> parseStrings(Object? v) {
      if (v is List) {
        return v
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return <String>[];
    }

    int parseIntSafe(Object? v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Restaurant(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Uncategorized',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      vendorId: map['vendorId'],
      numberOfTables: parseIntSafe(map['numberOfTables']),
      seatsPerTable: parseSeats(map['seatsPerTable']),
      timeSlots: parseStrings(map['timeSlots']),
      location:
          map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
    );
  }
}
