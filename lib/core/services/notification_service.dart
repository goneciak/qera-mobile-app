import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../providers/providers.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message: ${message.messageId}');
  print('📩 Title: ${message.notification?.title}');
  print('📩 Body: ${message.notification?.body}');
  print('📩 Data: ${message.data}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  /// Inicjalizacja Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        print('📱 FCM Token: $token');

        if (token != null) {
          await _sendTokenToBackend(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_sendTokenToBackend);

        // Setup message handlers
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Initialize local notifications
        await _initializeLocalNotifications();

        print('✅ Push notifications initialized successfully');
      } else {
        print('⚠️ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error initializing push notifications: $e');
    }
  }

  /// Wysyłanie FCM tokenu do backendu
  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _apiClient.post('/rep/notifications/register-device', data: {
        'fcmToken': token,
        'platform': 'flutter', // lub 'ios' / 'android'
        'deviceInfo': {
          'appVersion': '1.0.0',
          'osVersion': 'iOS 17.0', // TODO: Get from device_info_plus
        },
      });
      print('✅ FCM token sent to backend');
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  /// Inicjalizacja lokalnych notyfikacji
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Obsługa wiadomości w foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Foreground message: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Qera Rep',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Obsługa kliknięcia w notyfikację (app w background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📩 Notification opened app: ${message.messageId}');
    _navigateBasedOnData(message.data);
  }

  /// Obsługa kliknięcia w lokalną notyfikację
  void _onNotificationTapped(NotificationResponse response) {
    print('📩 Local notification tapped: ${response.payload}');
    // TODO: Parse payload and navigate
  }

  /// Wyświetlanie lokalnej notyfikacji
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'qera_rep_channel',
      'Qera Rep Notifications',
      channelDescription: 'Powiadomienia z aplikacji Qera Rep',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Nawigacja na podstawie danych z notyfikacji
  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    if (type == null || id == null) return;

    switch (type) {
      case 'interview':
        // TODO: Navigate to interview detail
        print('🔔 Navigate to interview: $id');
        break;
      case 'offer':
        // TODO: Navigate to offer detail
        print('🔔 Navigate to offer: $id');
        break;
      case 'commission':
        // TODO: Navigate to commissions
        print('🔔 Navigate to commission: $id');
        break;
      default:
        print('🔔 Unknown notification type: $type');
    }
  }

  /// Subskrybuj topic (np. "all_reps", "new_features")
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Odsubskrybuj topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Pobierz badge count (iOS)
  Future<int> getBadgeCount() async {
    // TODO: Implement badge count logic
    return 0;
  }

  /// Wyczyść wszystkie notyfikacje
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

// Riverpod provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationService(apiClient);
});
