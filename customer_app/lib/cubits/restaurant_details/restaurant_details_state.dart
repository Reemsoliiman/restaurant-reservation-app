import 'package:equatable/equatable.dart';
import '../../Models/table_model.dart';

abstract class RestaurantDetailsState extends Equatable {
  const RestaurantDetailsState();

  @override
  List<Object?> get props => [];
}

class RestaurantDetailsInitial extends RestaurantDetailsState {
  const RestaurantDetailsInitial();
}

class RestaurantDetailsLoading extends RestaurantDetailsState {
  const RestaurantDetailsLoading();
}

class RestaurantDetailsLoaded extends RestaurantDetailsState {
  final String restaurantId;
  final String restaurantName;
  final String? vendorId;
  final String? imageUrl;
  final String? description;
  final String? category;
  final List<TableModel> tables;
  final DateTime selectedDate;
  final Map<String, Set<String>> reservedSlots; // tableId -> Set of time slots
  final List<String> timeSlots;
  final List<int> seatsPerTable;
  final dynamic location;
  final dynamic numberOfTables;

  const RestaurantDetailsLoaded({
    required this.restaurantId,
    required this.restaurantName,
    this.vendorId,
    this.imageUrl,
    this.description,
    this.category,
    required this.tables,
    required this.selectedDate,
    required this.reservedSlots,
    this.timeSlots = const [],
    this.seatsPerTable = const [],
    this.location,
    this.numberOfTables,
  });

  @override
  List<Object?> get props => [
        restaurantId,
        restaurantName,
        vendorId,
        imageUrl,
        description,
        category,
        tables,
        selectedDate,
        reservedSlots,
        timeSlots,
        seatsPerTable,
        location,
        numberOfTables,
      ];

  RestaurantDetailsLoaded copyWith({
    String? restaurantId,
    String? restaurantName,
    String? vendorId,
    String? imageUrl,
    String? description,
    String? category,
    List<TableModel>? tables,
    DateTime? selectedDate,
    Map<String, Set<String>>? reservedSlots,
    List<String>? timeSlots,
    List<int>? seatsPerTable,
    dynamic location,
    dynamic numberOfTables,
  }) {
    return RestaurantDetailsLoaded(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      vendorId: vendorId ?? this.vendorId,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      tables: tables ?? this.tables,
      selectedDate: selectedDate ?? this.selectedDate,
      reservedSlots: reservedSlots ?? this.reservedSlots,
      timeSlots: timeSlots ?? this.timeSlots,
      seatsPerTable: seatsPerTable ?? this.seatsPerTable,
      location: location ?? this.location,
      numberOfTables: numberOfTables ?? this.numberOfTables,
    );
  }

  List<String> getAvailableSlots(String tableId, List<String> allSlots) {
    final reserved = reservedSlots[tableId] ?? {};
    return allSlots.where((slot) => !reserved.contains(slot)).toList();
  }
}

class RestaurantDetailsError extends RestaurantDetailsState {
  final String message;

  const RestaurantDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
