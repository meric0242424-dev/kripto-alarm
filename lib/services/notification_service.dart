import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Android 13+ bildirim izni - kullanıcı diyalog penceresine yanıt
    // verene kadar süre alabilir, bu yüzden bunu BEKLEMEDEN (fire-and-forget)
    // tetikliyoruz ki init() hemen tamamlansın ve uygulama akışını bloklamasın.
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      androidImpl.requestNotificationsPermission();
    }
  }

  static Future<void> showAlarmTriggered({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alarms',
      'Fiyat Alarmları',
      channelDescription: 'Kripto fiyat alarmı bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      color: Color.fromARGB(255, 247, 147, 26),
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
