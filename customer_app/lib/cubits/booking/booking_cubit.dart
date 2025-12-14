import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;
  StreamSubscription? _slotsSubscription;

  BookingCubit({
    FirestoreService? firestoreService,
    FirebaseAuth? auth,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _auth = auth ?? FirebaseAuth.instance,
        super(const BookingInitial());

  void loadAvailableSlots({
    required String restaurantId,
    required String tableId,
    required DateTime date,
  }) {
    try {
      emit(const BookingSlotsLoading());

      // Cancel any existing subscription
      _slotsSubscription?.cancel();

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // Listen to real-time updates
      _slotsSubscription = _firestoreService
          .streamBookingsForDate(restaurantId, dateStr)
          .listen(
            (bookingsSnapshot) {
              final reservedSlots = <String>{};
              for (var doc in bookingsSnapshot.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final bookedTableId = data['tableId']?.toString();
                final timeSlot = data['timeSlot']?.toString();
                final status = data['status']?.toString();

                // Only count non-cancelled bookings as reserved
                if (bookedTableId == tableId && timeSlot != null && status != 'cancelled') {
                  reservedSlots.add(timeSlot);
                }
              }

              emit(BookingSlotsLoaded(reservedSlots));
            },
            onError: (e) {
              emit(BookingSlotsError('Failed to load available slots: $e'));
            },
          );
    } catch (e) {
      emit(BookingSlotsError('Failed to load available slots: $e'));
    }
  }

  Future<void> createBooking({
    required String restaurantId,
    required String restaurantName,
    required String tableId,
    required String tableLabel,
    required int tableIndex,
    required String timeSlot,
    required DateTime date,
    required int seats,
    String? vendorId,
  }) async {
    try {
      emit(const BookingLoading());

      final user = _auth.currentUser;
      if (user == null) {
        emit(const BookingError('You must be logged in to make a booking'));
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      await _firestoreService.bookTable(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        tableId: tableId,
        tableLabel: tableLabel,
        tableIndex: tableIndex,
        timeSlot: timeSlot,
        date: dateStr,
        seats: seats,
        userId: user.uid,
        vendorId: vendorId ?? '',
      );

      emit(const BookingSuccess('Booking created successfully!'));
    } catch (e) {
      emit(BookingError('Failed to create booking: $e'));
    }
  }

  void reset() {
    emit(const BookingInitial());
  }

  @override
  Future<void> close() {
    _slotsSubscription?.cancel();
    return super.close();
  }
}
