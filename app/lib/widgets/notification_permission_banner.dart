import 'package:flutter/material.dart';
import '../services/push_notifications_service.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';

/// Subtle banner asking the user to enable push notifications.
/// Auto-hides after permission is granted/denied or the user dismisses it.
class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  State<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends State<NotificationPermissionBanner> {
  NotificationPermission? _status;
  bool _dismissed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final s = await PushNotificationsService.getPermissionStatus();
    if (mounted) setState(() => _status = s);
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    try {
      final s = await PushNotificationsService.requestPermission();
      if (s == NotificationPermission.authorized) {
        final user = authState.currentUser;
        if (user != null) {
          await PushNotificationsService.registerTokenForUser(user.id);
        }
      }
      if (mounted) setState(() => _status = s);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (_status != NotificationPermission.notRequested) {
      return const SizedBox.shrink();
    }
    if (authState.currentUser == null) return const SizedBox.shrink();

    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      color: palette.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vuoi ricevere notifiche?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Ti avvisiamo quando il tuo ordine è pronto.',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _dismissed = true),
                  child: Text(
                    'Non ora',
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: _enable,
                  child: Text(
                    'Attiva',
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
