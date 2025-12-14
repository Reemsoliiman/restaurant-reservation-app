import 'package:equatable/equatable.dart';

abstract class VendorNotificationsState extends Equatable {
  const VendorNotificationsState();

  @override
  List<Object?> get props => [];
}

class VendorNotificationsInitial extends VendorNotificationsState {
  const VendorNotificationsInitial();
}

class VendorNotificationsListening extends VendorNotificationsState {
  const VendorNotificationsListening();
}

class VendorNotificationReceived extends VendorNotificationsState {
  final String message;
  final DateTime timestamp;

  const VendorNotificationReceived({
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, timestamp];
}

class VendorNotificationsError extends VendorNotificationsState {
  final String message;

  const VendorNotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
