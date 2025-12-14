import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/local_user_service.dart';
import '../../services/firestore_service.dart';
import '../../models/restaurant.dart';
import '../../models/booking.dart';
import 'vendor_notifications_state.dart';

class VendorNotificationsCubit extends Cubit<VendorNotificationsState> {
  final FirebaseFirestore _firestore;
  final LocalUserService _localUserService;
  final FirestoreService _firestoreService;
  
  StreamSubscription? _notifSub;
  final Map<String, StreamSubscription<List<Booking>>> _bookingSubs = {};
  final Map<String, List<String>> _seenByRestaurant = {};

  VendorNotificationsCubit({
    FirebaseFirestore? firestore,
    LocalUserService? localUserService,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localUserService = localUserService ?? LocalUserService(),
        _firestoreService = firestoreService ?? FirestoreService(),
        super(const VendorNotificationsInitial());

  Future<void> startListening() async {
    try {
      final vendorId = await _localUserService.getUserId();
      
      // Listen for unread notifications
      _notifSub = _firestore
          .collection('notifications')
          .where('vendorId', isEqualTo: vendorId)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen(
            (snap) {
              final docs = snap.docs.toList();
              docs.sort((a, b) {
                final at = a.data()['createdAt'];
                final bt = b.data()['createdAt'];
                if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
                return 0;
              });
              
              for (var d in docs) {
                final raw = d.data();
                final msg = raw['message']?.toString() ?? 'New notification';
                emit(VendorNotificationReceived(
                  message: msg,
                  timestamp: DateTime.now(),
                ));
                
                // Mark notification as read
                try {
                  d.reference.update({'read': true});
                } catch (_) {}
              }
            },
            onError: (e) {
              emit(VendorNotificationsError('Notification stream error: $e'));
            },
          );

      emit(const VendorNotificationsListening());
    } catch (e) {
      emit(VendorNotificationsError('Failed to start listening: $e'));
    }
  }

  void updateRestaurantSubscriptions(List<Restaurant> restaurants) {
    final currentIds = restaurants
        .where((r) => r.id != null)
        .map((r) => r.id!)
        .toSet();

    // Remove subs for restaurants no longer present
    final toRemove = _bookingSubs.keys.where((k) => !currentIds.contains(k)).toList();
    for (final id in toRemove) {
      _bookingSubs[id]?.cancel();
      _bookingSubs.remove(id);
      _seenByRestaurant.remove(id);
    }

    // Add subs for new restaurants
    for (final r in restaurants) {
      final id = r.id;
      if (id == null) continue;
      if (_bookingSubs.containsKey(id)) continue;
      
      _seenByRestaurant[id] = [];
      final sub = _firestoreService.reservationsStreamForRestaurant(id).listen((
        reservations,
      ) {
        if (reservations.isEmpty) return;
        final latest = reservations.first;
        final seen = _seenByRestaurant[id]!;
        if (!seen.contains(latest.id)) {
          seen.insert(0, latest.id);
          final msg = 'New booking for ${r.name}: Table ${latest.tableIndex} - ${latest.timeSlot} on ${latest.date}';
          emit(VendorNotificationReceived(
            message: msg,
            timestamp: DateTime.now(),
          ));
        }
      });
      _bookingSubs[id] = sub;
    }
  }

  @override
  Future<void> close() {
    _notifSub?.cancel();
    for (final sub in _bookingSubs.values) {
      sub.cancel();
    }
    _bookingSubs.clear();
    return super.close();
  }
}
