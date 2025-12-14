import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String? id;
  final String name;
  final String description;
  final String? imageUrl;
  final String categoryId;
  final String category;
  final int numberOfTables;
  final List<int> seatsPerTable;
  final List<String> timeSlots;
  final GeoPoint? location;
  final String? vendorId;

  Restaurant({
    this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.categoryId,
    required this.category,
    required this.numberOfTables,
    required this.seatsPerTable,
    required this.timeSlots,
    this.location,
    this.vendorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'category': category,
      'numberOfTables': numberOfTables,
      'seatsPerTable': seatsPerTable,
      'timeSlots': timeSlots,
      'location': location,
      'vendorId': vendorId,
    };
  }

  factory Restaurant.fromSnapshot(DocumentSnapshot snap) {
    final raw = snap.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
    int parseIntSafe(Object? v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

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

    return Restaurant(
      id: snap.id,
      name: (data['name'] ?? '')?.toString() ?? '',
      description: (data['description'] ?? '')?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      categoryId: (data['categoryId'] ?? '')?.toString() ?? '',
      category:
          (data['category'] ?? 'Uncategorized')?.toString() ?? 'Uncategorized',
      numberOfTables: parseIntSafe(data['numberOfTables']),
      seatsPerTable: parseSeats(data['seatsPerTable']),
      timeSlots: parseStrings(data['timeSlots']),
      location: data['location'] is GeoPoint
          ? data['location'] as GeoPoint
          : null,
      vendorId: data['vendorId']?.toString(),
    );
  }
}
