import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/pages/complaint/complaint_detail_page.dart';
import 'package:rapa_track_mobile_app/app/pages/complaint/complaint_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/notification/notification_detail_page.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/reservation_detail_page.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/reservation_list_page.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';
import 'package:rapa_track_mobile_app/app/utils/navigation_handler.dart';

class NotificationHandlerUtil {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'rapa_track_high';
  static const _channelName = 'RapaTrack Notifikasi';
  static const _channelDesc = 'Notifikasi reservasi dan keluhan dari RapaTrack';

  static const _androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onBackgroundTap);
  }

  static Future<void> handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _onBackgroundTap(message);
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final payload = NotificationPayload.fromFcmData(
      message.data,
      title: notification.title,
      body: notification.body,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload.toLocalPayload(),
    );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    navigate(NotificationPayload.fromLocalPayload(response.payload));
  }

  static void _onBackgroundTap(RemoteMessage message) {
    navigate(
      NotificationPayload.fromFcmData(
        message.data,
        title: message.notification?.title,
        body: message.notification?.body,
      ),
    );
  }

  static void navigate(NotificationPayload payload) {
    final user = AuthenticationState().user;
    if (user == null) return;

    final navigatorState = NavigationHandler.navigatorKey.currentState;
    if (navigatorState == null) return;

    Widget page;
    switch (payload.type) {
      case NotificationType.reservationCreated:
      case NotificationType.reservationApproved:
      case NotificationType.reservationRejected:
      case NotificationType.reservationCancelled:
      case NotificationType.reservationReminder:
        page = payload.reservationId != null
            ? ReservationDetailPage(reservationId: payload.reservationId!, user: user)
            : ReservationListPage(user: user);
      case NotificationType.complaintResponse:
        page = payload.complaintId != null
            ? ComplaintDetailPage(complaintId: payload.complaintId!, user: user)
            : ComplaintListPage(user: user);
      case NotificationType.general:
        page = NotificationDetailPage(
          notification: NotificationModel(
            title: payload.title,
            body: payload.body,
            type: payload.type,
            data: payload.data,
            createdAt: DateTime.now(),
          ),
        );
    }

    navigatorState.push(MaterialPageRoute(builder: (_) => page));
  }
}
