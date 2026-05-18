import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Manages FCM permissions, token retrieval, and Firestore registration.
///
/// On web requires the VAPID public key (set [webVapidKey]).
/// Get yours from Firebase Console → Project Settings → Cloud Messaging
/// → Web Push certificates → "Generate key pair".
class PushNotificationsService {
  /// VAPID public key from Firebase Console → Cloud Messaging → Web Push certificates.
  /// Required for FCM web push to work.
  static const String? webVapidKey =
      'BJwmL3IJX96AylL3tULRe31RiJxiJsM0WYsnvMBt5IMsUArxmDxltouQp7HJy9ya7IbxHDhY959vjQ4QEmypZ1k';

  static FirebaseMessaging get _fm => FirebaseMessaging.instance;

  /// Request OS notification permission. Call on first login or from settings.
  static Future<NotificationPermission> requestPermission() async {
    final settings = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return _toLocal(settings.authorizationStatus);
  }

  /// Get current permission status without prompting.
  static Future<NotificationPermission> getPermissionStatus() async {
    final settings = await _fm.getNotificationSettings();
    return _toLocal(settings.authorizationStatus);
  }

  static NotificationPermission _toLocal(AuthorizationStatus s) =>
      switch (s) {
        AuthorizationStatus.authorized => NotificationPermission.authorized,
        AuthorizationStatus.provisional => NotificationPermission.authorized,
        AuthorizationStatus.denied => NotificationPermission.denied,
        AuthorizationStatus.notDetermined =>
          NotificationPermission.notRequested,
      };

  /// Get the device-specific FCM token (used to target this device).
  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        if (webVapidKey == null) return null;
        return await _fm.getToken(vapidKey: webVapidKey);
      }
      return await _fm.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Save token to users/{uid}/fcmTokens/{deviceTokenId}.
  /// Multi-device: same user may have N tokens (web + phone + tablet).
  static Future<void> registerTokenForUser(String userId) async {
    final token = await getToken();
    if (token == null) return;
    final db = FirebaseFirestore.instance;
    await db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'platform': kIsWeb ? 'web' : 'mobile',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Foreground message handler. Set up in main() with
  ///   FirebaseMessaging.onMessage.listen(PushNotificationsService.onForeground)
  static void onForeground(RemoteMessage message) {
    // Hook: show in-app banner. For now log via debugPrint.
    debugPrint('FCM foreground: ${message.notification?.title} — ${message.notification?.body}');
  }
}

enum NotificationPermission { notRequested, authorized, denied }
