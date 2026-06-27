import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../app/routes/app_routes.dart';
import '../../firebase_options.dart';
import '../constants/firebase_constants.dart';

// ── Shared persist helper (top-level so background isolate can call it) ───────
//
// Strategy for zero duplicates:
//   • Cloud Functions write to `notifications/<notifId>` with a deterministic
//     ID (e.g. "proof_submitted_<proofId>") AND include `notifId` + `recipientId`
//     in the FCM data payload.
//   • When the FCM arrives here, we write to the SAME doc ID with merge:true
//     so the second write is a no-op if the Cloud Function already wrote it.
//   • For queue-based pushes (chat, reminders) that have no matching Cloud
//     Function Firestore write, we generate a UUID — one new doc per message.
//   • Topic/broadcast messages (no recipientId) are skipped entirely.

Future<void> _persistFcmMessage(RemoteMessage message) async {
  final data = message.data;
  // Prefer explicit recipientId (individual pushes). For topic broadcasts
  // (new_apps), fall back to the currently signed-in user so the notification
  // lands in their in-app list and updates their badge count.
  final String recipientId = (data['recipientId'] as String?)?.trim().isNotEmpty == true
      ? (data['recipientId'] as String).trim()
      : (FirebaseAuth.instance.currentUser?.uid ?? '');
  if (recipientId.isEmpty) return;

  final notification = message.notification;
  final title = notification?.title ?? (data['title'] as String?)?.trim() ?? '';
  final body = notification?.body ?? (data['body'] as String?)?.trim() ?? '';
  if (title.isEmpty && body.isEmpty) return; // nothing to show

  // Use deterministic notifId when present (Cloud Function set it) so a retry
  // write is idempotent. Fall back to UUID for queue-based notifications.
  final notifId = (data['notifId'] as String?)?.trim() ?? '';
  final docId = notifId.isNotEmpty ? notifId : const Uuid().v4();

  // Strip internal routing fields before storing in Firestore
  final storedData = Map<String, String>.from(
    data.map((k, v) => MapEntry(k, v.toString())),
  )
    ..remove('notifId')
    ..remove('recipientId');

  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .set(
          {
            'recipientId': recipientId,
            'title': title,
            'body': body,
            'type': storedData['type'] ?? 'general',
            'data': storedData,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  } catch (e) {
    debugPrint('[FCM] Persist failed: $e');
  }
}

// ── Background handler (separate isolate) ────────────────────────────────────

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Persist the notification so it appears in the in-app list even if the
  // Cloud Function write hasn't landed yet, or for queue-based push types
  // (chat, reminders) that have no Cloud Function Firestore write.
  await _persistFcmMessage(message);
}

// ── Notification channel ID ──────────────────────────────────────────────────

const _kChannelId = 'tester_mandi_high';
const _kChannelName = 'TesterMandi Notifications';

// ── NotificationService ──────────────────────────────────────────────────────

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initLocal();
    await _initFCM();
  }

  // ── Local notifications setup ────────────────────────────────────────────

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // Create Android high-importance channel
    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: 'Real-time updates for swaps, proofs, and messages',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── FCM setup ────────────────────────────────────────────────────────────

  Future<void> _initFCM() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _fetchFcmToken();
      _messaging.subscribeToTopic('new_apps').catchError((_) {});
    }

    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _uploadTokenIfLoggedIn();
    });

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      _handleTap(initial);
    }
  }

  // ── Token management ─────────────────────────────────────────────────────

  Future<void> _fetchFcmToken() async {
    if (Platform.isIOS) {
      await _fetchFcmTokenIOS();
      return;
    }
    final token = await _tryGetToken();
    if (token != null) {
      _fcmToken = token;
      debugPrint('[FCM] Token acquired');
      return;
    }
    _retryFcmTokenInBackground();
  }

  Future<void> _fetchFcmTokenIOS() async {
    String? apnsToken = await _messaging.getAPNSToken();
    if (apnsToken == null) {
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(seconds: 2));
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) break;
      }
    }
    if (apnsToken == null) {
      debugPrint('[FCM] APNs token unavailable — Simulator or missing entitlement');
      return;
    }
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) debugPrint('[FCM] Token acquired');
    } catch (e) {
      debugPrint('[FCM] iOS token error: $e');
    }
  }

  Future<String?> _tryGetToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  void _retryFcmTokenInBackground() {
    Future(() async {
      const delays = [5, 15, 30, 60];
      for (final seconds in delays) {
        await Future.delayed(Duration(seconds: seconds));
        final token = await _tryGetToken();
        if (token != null) {
          _fcmToken = token;
          debugPrint('[FCM] Token acquired on retry');
          _uploadTokenIfLoggedIn();
          return;
        }
      }
      debugPrint('[FCM] Token unavailable after all retries — onTokenRefresh will handle it');
    });
  }

  Future<void> uploadFcmToken(String userId) async {
    if (userId.isEmpty) return;
    if (_fcmToken == null) await _fetchFcmToken();
    if (_fcmToken == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({FirebaseConstants.fieldFcmToken: _fcmToken});
    } catch (e) {
      debugPrint('[FCM] Token upload failed: $e');
    }
  }

  void _uploadTokenIfLoggedIn() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) uploadFcmToken(uid);
  }

  // ── Foreground message ───────────────────────────────────────────────────

  Future<void> _handleForeground(RemoteMessage message) async {
    // Always persist so the notification appears in the in-app list.
    // This covers chat/reminder pushes that have no Cloud Function Firestore
    // write, and is idempotent for proof/swap pushes (same doc ID, merge:true).
    unawaited(_persistFcmMessage(message));

    final notification = message.notification;
    if (notification == null) return;

    // Display local banner while app is in foreground
    await _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  // ── Notification tap navigation ──────────────────────────────────────────

  void _handleTap(RemoteMessage message) {
    Get.toNamed(AppRoutes.notifications);
  }

  void _onLocalTap(NotificationResponse response) {
    Get.toNamed(AppRoutes.notifications);
  }

  // ── Scheduled local notifications ────────────────────────────────────────

  Future<void> scheduleDailyProofReminder() async {
    await _local.periodicallyShow(
      0,
      'Time to submit your proof! 📸',
      "Don't forget to upload today's testing screenshots.",
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showLocalBanner(String title, String body) async {
    await _local.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancelAll() => _local.cancelAll();

  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
