import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import '../../Models/table_model.dart';
import '../../services/firestore_service.dart';
import 'restaurant_details_state.dart';

class RestaurantDetailsCubit extends Cubit<RestaurantDetailsState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _tablesSubscription;
  StreamSubscription? _bookingsSubscription;

  RestaurantDetailsCubit({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService(),
        super(const RestaurantDetailsInitial());

  void loadRestaurantDetails({
    required String restaurantId,
    required String restaurantName,
    String? vendorId,
  }) async {
    emit(const RestaurantDetailsLoading());

    final selectedDate = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Fetch restaurant data first
    try {
      final restaurantDoc = await _firestoreService.getRestaurant(restaurantId);
      final restaurantData =
          restaurantDoc.data() as Map<String, dynamic>? ?? {};

      final imageUrl = restaurantData['imageUrl'] as String?;
      final description = restaurantData['description'] as String?;
      final category = restaurantData['category'] as String?;

      // Parse restaurant timeSlots and seatsPerTable
      List<String> timeSlots = [];
      if (restaurantData['timeSlots'] is List) {
        timeSlots = (restaurantData['timeSlots'] as List)
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }

      List<int> seatsPerTable = [];
      if (restaurantData['seatsPerTable'] is List) {
        seatsPerTable = (restaurantData['seatsPerTable'] as List).map((e) {
          if (e is int) return e;
          return int.tryParse(e?.toString() ?? '') ?? 4;
        }).toList();
      }

      final location = restaurantData['location'];
      final numberOfTables = restaurantData['numberOfTables'];

      // Listen to tables
      _tablesSubscription?.cancel();
      _tablesSubscription = _firestoreService.streamTables(restaurantId).listen(
        (tablesSnapshot) {
          try {
            final tables = tablesSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return TableModel.fromMap(doc.id, data);
            }).toList();

            // Also listen to bookings for the selected date
            _listenToBookings(
                restaurantId,
                dateStr,
                tables,
                restaurantName,
                vendorId,
                imageUrl,
                description,
                category,
                timeSlots,
                seatsPerTable,
                location,
                numberOfTables);
          } catch (e) {
            emit(RestaurantDetailsError('Failed to load tables: $e'));
          }
        },
        onError: (error) {
          emit(RestaurantDetailsError('Failed to load tables: $error'));
        },
      );
    } catch (e) {
      emit(RestaurantDetailsError('Failed to load restaurant: $e'));
    }
  }

  void _listenToBookings(
    String restaurantId,
    String dateStr,
    List<TableModel> tables,
    String restaurantName,
    String? vendorId,
    String? imageUrl,
    String? description,
    String? category,
    List<String> timeSlots,
    List<int> seatsPerTable,
    dynamic location,
    dynamic numberOfTables,
  ) {
    _bookingsSubscription?.cancel();
    _bookingsSubscription =
        _firestoreService.streamBookingsForDate(restaurantId, dateStr).listen(
      (bookingsSnapshot) {
        try {
          final reservedSlots = <String, Set<String>>{};

          for (var doc in bookingsSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final tableId = data['tableId']?.toString();
            final timeSlot = data['timeSlot']?.toString();
            final status = data['status']?.toString();

            // Only count non-cancelled bookings as reserved
            if (tableId != null && timeSlot != null && status != 'cancelled') {
              reservedSlots
                  .putIfAbsent(tableId, () => <String>{})
                  .add(timeSlot);
            }
          }

          emit(RestaurantDetailsLoaded(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            vendorId: vendorId,
            imageUrl: imageUrl,
            description: description,
            category: category,
            tables: tables,
            selectedDate: DateTime.parse(dateStr),
            reservedSlots: reservedSlots,
            timeSlots: timeSlots,
            seatsPerTable: seatsPerTable,
            location: location,
            numberOfTables: numberOfTables,
          ));
        } catch (e) {
          emit(RestaurantDetailsError('Failed to load bookings: $e'));
        }
      },
      onError: (error) {
        emit(RestaurantDetailsError('Failed to load bookings: $error'));
      },
    );
  }

  void changeDate(DateTime newDate) {
    final currentState = state;
    if (currentState is RestaurantDetailsLoaded) {
      final dateStr = DateFormat('yyyy-MM-dd').format(newDate);

      emit(currentState.copyWith(selectedDate: newDate));

      // Reload bookings for the new date
      _listenToBookings(
        currentState.restaurantId,
        dateStr,
        currentState.tables,
        currentState.restaurantName,
        currentState.vendorId,
        currentState.imageUrl,
        currentState.description,
        currentState.category,
        currentState.timeSlots,
        currentState.seatsPerTable,
        currentState.location,
        currentState.numberOfTables,
      );
    }
  }

  @override
  Future<void> close() {
    _tablesSubscription?.cancel();
    _bookingsSubscription?.cancel();
    return super.close();
  }
}
