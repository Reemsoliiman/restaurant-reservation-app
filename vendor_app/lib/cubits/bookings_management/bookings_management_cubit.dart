import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../models/restaurant.dart';
import '../../services/firestore_service.dart';
import 'bookings_management_state.dart';

class BookingsManagementCubit extends Cubit<BookingsManagementState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _restaurantSubscription;
  StreamSubscription? _bookingsSubscription;

  BookingsManagementCubit({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService(),
      super(const BookingsManagementInitial());

  void loadBookings(String restaurantId) {
    emit(const BookingsManagementLoading());

    // Listen to restaurant
    _restaurantSubscription?.cancel();
    _restaurantSubscription = _firestoreService
        .restaurantStream(restaurantId)
        .listen(
          (restaurant) {
            if (restaurant != null) {
              _listenToBookings(restaurantId, restaurant);
            } else {
              emit(const BookingsManagementError('Restaurant not found'));
            }
          },
          onError: (error) {
            emit(BookingsManagementError('Failed to load restaurant: $error'));
          },
        );
  }

  void _listenToBookings(String restaurantId, Restaurant restaurant) {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = _firestoreService
        .reservationsStreamForRestaurant(restaurantId)
        .listen(
          (bookings) {
            emit(
              BookingsManagementLoaded(
                restaurant: restaurant,
                bookings: bookings,
              ),
            );
          },
          onError: (error) {
            emit(BookingsManagementError('Failed to load bookings: $error'));
          },
        );
  }

  void updateDateFilter(DateTime? date) {
    final currentState = state;
    if (currentState is BookingsManagementLoaded) {
      emit(currentState.copyWith(selectedDate: date));
    }
  }

  void clearDateFilter() {
    final currentState = state;
    if (currentState is BookingsManagementLoaded) {
      emit(currentState.copyWith(clearDate: true));
    }
  }

  void updateTimeSlotFilter(String? timeSlot) {
    final currentState = state;
    if (currentState is BookingsManagementLoaded) {
      emit(currentState.copyWith(selectedTimeSlot: timeSlot));
    }
  }

  @override
  Future<void> close() {
    _restaurantSubscription?.cancel();
    _bookingsSubscription?.cancel();
    return super.close();
  }
}
