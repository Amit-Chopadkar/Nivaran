import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'safety_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Request notification permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'activate_sos' || response.actionId == 'activate_sos') {
          // Trigger the globally tracked SafetyService instance
          try {
            SafetyService.instance.activateSOS();
            debugPrint('SOS Activation Triggered via Mobile Notification Dashboard');
          } catch (e) {
            debugPrint('Notification SOS Error: SafetyService not yet initialized');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse notificationResponse) {
    if (notificationResponse.payload == 'activate_sos' || notificationResponse.actionId == 'activate_sos') {
      try {
        SafetyService.instance.activateSOS();
      } catch (e) {
        debugPrint('Background Notification SOS Error: SafetyService not yet initialized');
      }
    }
  }

  static Future<void> showPersistentSOS() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sos_channel',
      'Emergency SOS',
      channelDescription: 'Persistent SOS trigger for quick access',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      showWhen: false,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(''),
      color: Color(0xFFEF4444),
      colorized: true,
      fullScreenIntent: true,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          'activate_sos',
          '🚨 ACTIVATE SOS NOW',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      'SafeHer Quick SOS',
      'Hold to stay safe. Tap the button below to alert contacts immediately.',
      platformChannelSpecifics,
      payload: 'activate_sos',
    );
  }
}
