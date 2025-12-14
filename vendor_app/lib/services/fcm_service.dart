import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call once at app startup to register token and set up basic handlers.
  Future<void> init({String? vendorId}) async {
    await _requestPermission();
    final token = await _fm.getToken();
    if (token != null) {
      await _saveToken(token, vendorId: vendorId);
    }
    _fm.onTokenRefresh.listen((t) => _saveToken(t, vendorId: vendorId));
  }

  Future<void> _requestPermission() async {
    await _fm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _saveToken(String token, {String? vendorId}) async {
    final doc = _db.collection('vendor_tokens').doc(token);
    await doc.set({
      'token': token,
      'vendorId': vendorId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove a token from the backend (call on sign-out or when token is invalid)
  Future<void> removeToken(String token) async {
    try {
      final doc = _db.collection('vendor_tokens').doc(token);
      await doc.delete();
    } catch (e) {
      // ignore: avoid_print
      print('Failed to remove FCM token $token: $e');
    }
  }
}
