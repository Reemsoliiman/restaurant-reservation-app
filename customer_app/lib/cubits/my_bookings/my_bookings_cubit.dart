import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Models/booking.dart';
import '../../services/firestore_service.dart';
import 'my_bookings_state.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;
  StreamSubscription? _bookingsSubscription;

  MyBookingsCubit({
    FirestoreService? firestoreService,
    FirebaseAuth? auth,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _auth = auth ?? FirebaseAuth.instance,
        super(const MyBookingsInitial());

  void loadMyBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      emit(const MyBookingsError('You must be logged in to view bookings'));
      return;
    }

    emit(const MyBookingsLoading());

    _bookingsSubscription?.cancel();
    _bookingsSubscription =
        _firestoreService.streamBookingsForUser(user.uid).listen(
      (snapshot) {
        try {
          final bookings = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Booking.fromMap(doc.id, data);
          }).toList();

          emit(MyBookingsLoaded(bookings: bookings));
        } catch (e) {
          emit(MyBookingsError('Failed to load bookings: $e'));
        }
      },
      onError: (error) {
        emit(MyBookingsError('Failed to load bookings: $error'));
      },
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestoreService.cancelBooking(bookingId);
      // The stream will automatically update the UI
    } catch (e) {
      emit(MyBookingsError('Failed to cancel booking: $e'));
      // Reload to restore previous state
      loadMyBookings();
    }
  }

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }
}
