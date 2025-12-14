import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final FirebaseFirestore _firestore;
  StreamSubscription? _notificationsSubscription;

  NotificationsCubit({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const NotificationsInitial());

  void loadNotifications() {
    emit(const NotificationsLoading());
    
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final notifications = snapshot.docs
                .map((doc) => NotificationModel.fromDocument(doc))
                .toList();
            emit(NotificationsLoaded(notifications));
          },
          onError: (error) {
            emit(NotificationsError('Failed to load notifications: ${error.toString()}'));
          },
        );
  }

  Future<void> toggleReadStatus(String notificationId, bool currentStatus) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': !currentStatus});
      // Notifications will be updated via stream
    } catch (e) {
      emit(NotificationsError('Failed to update notification: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
