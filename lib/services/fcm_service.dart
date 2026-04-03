import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  void listenForMessages(Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      onMessage(message);
    });
  }

  // Not implemented completely depending upon local notification library
  void showLocalNotification(RemoteMessage message) {
    // In a fuller implementation, use flutter_local_notifications
    // Currently, our UI stream builder catches this in the dashboard.
  }
}
