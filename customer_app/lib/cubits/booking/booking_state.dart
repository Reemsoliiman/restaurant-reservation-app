import 'package:equatable/equatable.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingSlotsLoading extends BookingState {
  const BookingSlotsLoading();
}

class BookingSlotsLoaded extends BookingState {
  final Set<String> bookedSlots;

  const BookingSlotsLoaded(this.bookedSlots);

  @override
  List<Object?> get props => [bookedSlots];
}

class BookingSlotsError extends BookingState {
  final String message;

  const BookingSlotsError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingSuccess extends BookingState {
  final String message;

  const BookingSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}
