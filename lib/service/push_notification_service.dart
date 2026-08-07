import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/notifications/notification_navigation.dart';
import 'package:life_legacy/service/toast_service.dart';

/// 백그라운드 isolate — top-level 이어야 한다.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 데이터만 받고 로컬 DB 갱신은 포그라운드에서 한다.
  debugPrint('FCM background: ${message.messageId}');
}

/// OS 알림 권한 · FCM 토큰 등록 · 딥링크 진입.
///
/// Firebase가 아직 설정되지 않았으면(google-services.json 등 없음) 권한 요청만
/// 하고 토큰 등록은 건너뛴다 — 앱은 계속 동작한다.
class PushNotificationService extends GetxService {
  PushNotificationService(this._api);

  final ApiClient _api;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _firebaseReady = false;
  bool _started = false;
  String? _currentToken;

  static const _androidChannel = AndroidNotificationChannel(
    'daily_question',
    '오늘의 질문',
    description: '작성 일정에 맞춘 오늘의 질문 알림',
    importance: Importance.high,
  );

  /// 앱 시작 시 한 번. Firebase 실패해도 예외를 밖으로 안 낸다.
  Future<PushNotificationService> init() async {
    if (_started) return this;
    _started = true;

    await _initLocalNotifications();
    _firebaseReady = await _tryInitFirebase();
    if (!_firebaseReady) return this;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // 스플래시 라우팅이 끝난 뒤 딥링크를 연다.
      Future<void>.delayed(const Duration(milliseconds: 1600), () {
        _openFromMessage(initial);
      });
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await Storage.saveFcmToken(token);
      if (Storage.isLoggedIn) {
        await _registerToken(token);
      }
    });

    return this;
  }

  /// 홈 진입·알림 토글 ON 직후. 권한이 없으면 요청하고, 허용 시 토큰을 올린다.
  Future<void> syncAfterLogin({bool requestIfNeeded = true}) async {
    if (!Storage.isLoggedIn) return;

    final granted = await ensurePermission(requestIfNeeded: requestIfNeeded);
    if (!granted || !_firebaseReady) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    _currentToken = token;
    await Storage.saveFcmToken(token);
    await _registerToken(token);
  }

  /// 설정에서 오늘의 질문 알림을 켰을 때.
  Future<void> onDailyAlarmEnabled() async {
    await syncAfterLogin(requestIfNeeded: true);
  }

  /// 로그아웃 전 — 서버 폐기 + 로컬 토큰 정리.
  Future<void> revokeBeforeLogout() async {
    final token = _currentToken ?? Storage.fcmToken;
    if (token != null && token.isNotEmpty && Storage.isLoggedIn) {
      try {
        await _api.revokeDevicePushToken(token);
      } on ApiException {
        // 서버 로그아웃이 이어서 전체 revoke 한다.
      }
    }
    _currentToken = null;
    await Storage.clearFcmToken();
  }

  /// OS 알림 권한. [requestIfNeeded]가 false면 상태만 본다.
  Future<bool> ensurePermission({bool requestIfNeeded = true}) async {
    if (kIsWeb) return false;

    if (Platform.isIOS) {
      if (_firebaseReady) {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          return true;
        }
        if (!requestIfNeeded || Storage.pushPermissionAsked) {
          return false;
        }
        await Storage.markPushPermissionAsked();
        final next = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return next.authorizationStatus == AuthorizationStatus.authorized ||
            next.authorizationStatus == AuthorizationStatus.provisional;
      }

      // Firebase 없을 때도 OS 프롬프트는 띄운다 (permission_handler).
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (!requestIfNeeded || Storage.pushPermissionAsked) {
        return status.isGranted;
      }
      await Storage.markPushPermissionAsked();
      final next = await Permission.notification.request();
      return next.isGranted;
    }

    // Android 13+ POST_NOTIFICATIONS
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (!requestIfNeeded || Storage.pushPermissionAsked) {
      return status.isGranted;
    }
    await Storage.markPushPermissionAsked();
    final next = await Permission.notification.request();
    return next.isGranted;
  }

  Future<void> _registerToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _api.registerDevicePushToken(platform: platform, token: token);
    } on ApiException catch (e) {
      debugPrint('registerDevicePushToken failed: ${e.message}');
    }
  }

  Future<bool> _tryInitFirebase() async {
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      return true;
    } catch (e) {
      debugPrint(
        'Firebase not configured — push token sync disabled. '
        'Add google-services.json / GoogleService-Info.plist. ($e)',
      );
      return false;
    }
  }

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _openFromData(data.map((k, v) => MapEntry(k, '$v')));
        } catch (_) {}
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] ?? '알림';
    final body = message.notification?.body ?? '';
    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openFromMessage(RemoteMessage message) {
    _openFromData(message.data.map((k, v) => MapEntry(k, '$v')));
  }

  void _openFromData(Map<String, String> data) {
    final notification = AppNotification(
      id: data['notification_id'] ?? 'push',
      type: data['type'] ?? NotificationType.dailyQuestion,
      title: data['title'] ?? '',
      timeLabel: '',
      bookId: data['book_id'],
      questionId: data['question_id'],
      chapterId: data['chapter_id'],
    );

    final toast = Get.isRegistered<ToastService>()
        ? Get.find<ToastService>()
        : null;
    if (toast == null) return;

    NotificationNavigation.open(notification, toast: toast);
  }
}
