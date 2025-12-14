import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String message;
  final String? vendorId;
  final bool read;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.message,
    this.vendorId,
    required this.read,
    this.createdAt,
  });

  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final created = data['createdAt'];
    
    return NotificationModel(
      id: doc.id,
      message: data['message']?.toString() ?? '',
      vendorId: data['vendorId']?.toString(),
      read: data['read'] == true,
      createdAt: (created is Timestamp) ? created.toDate() : null,
    );
  }
}

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;

  const NotificationsLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
