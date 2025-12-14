import 'package:equatable/equatable.dart';
import '../../models/booking.dart';
import '../../models/restaurant.dart';

abstract class BookingsManagementState extends Equatable {
  const BookingsManagementState();

  @override
  List<Object?> get props => [];
}

class BookingsManagementInitial extends BookingsManagementState {
  const BookingsManagementInitial();
}

class BookingsManagementLoading extends BookingsManagementState {
  const BookingsManagementLoading();
}

class BookingsManagementLoaded extends BookingsManagementState {
  final Restaurant restaurant;
  final List<Booking> bookings;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;

  const BookingsManagementLoaded({
    required this.restaurant,
    required this.bookings,
    this.selectedDate,
    this.selectedTimeSlot,
  });

  @override
  List<Object?> get props => [
    restaurant,
    bookings,
    selectedDate,
    selectedTimeSlot,
  ];

  List<Booking> get filteredBookings {
    return bookings.where((booking) {
      if (selectedDate != null) {
        final dateStr =
            '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
        if (booking.date != dateStr) return false;
      }
      if (selectedTimeSlot != null && selectedTimeSlot!.isNotEmpty) {
        if (booking.timeSlot != selectedTimeSlot) return false;
      }
      return true;
    }).toList();
  }

  BookingsManagementLoaded copyWith({
    Restaurant? restaurant,
    List<Booking>? bookings,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    bool clearDate = false,
    bool clearTimeSlot = false,
  }) {
    return BookingsManagementLoaded(
      restaurant: restaurant ?? this.restaurant,
      bookings: bookings ?? this.bookings,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      selectedTimeSlot: clearTimeSlot
          ? null
          : (selectedTimeSlot ?? this.selectedTimeSlot),
    );
  }
}

class BookingsManagementError extends BookingsManagementState {
  final String message;

  const BookingsManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
