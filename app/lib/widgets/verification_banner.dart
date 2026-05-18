import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';

/// Yellow banner shown at the top of MainScaffold when user.emailVerified=false.
/// Lets user re-send verification email or refresh status.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _busy = false;
  bool _justResent = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await authState.resendVerificationEmail();
      if (!mounted) return;
      setState(() => _justResent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email di verifica reinviata.')),
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final verified = await authState.refreshEmailVerified();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(verified
            ? '✅ Email verificata!'
            : 'Non risulta ancora verificata. Controlla la posta.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authState,
      builder: (context, _) {
        if (authState.isEmailVerified || authState.currentUser == null) {
          return const SizedBox.shrink();
        }
        final palette = Theme.of(context).extension<SilvestrePalette>()!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          color: palette.warning.withValues(alpha: 0.18),
          child: Row(
            children: [
              Icon(Icons.mark_email_unread_outlined, color: palette.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifica la tua email',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _justResent
                          ? 'Email inviata. Clicca il link nella mail.'
                          : 'Controlla ${authState.currentUser?.email} e clicca il link.',
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
                      onPressed: _resend,
                      child: Text('Reinvia',
                          style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: _check,
                      child: Text('Ho fatto',
                          style: TextStyle(
                              color: palette.success,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
