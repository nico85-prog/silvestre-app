import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../state/marketing_optin_intent.dart';
import '../theme/app_theme.dart';
import 'auth/welcome_screen.dart';
import 'main_scaffold.dart';
import 'operator/operator_scaffold.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _optInDialogShown = false;

  void _maybeShowOptInDialog() {
    // Trigger una volta sola, quando l'utente loggato arriva con
    // ?optin=marketing e non ha ancora marketing attivo.
    if (_optInDialogShown) return;
    if (!MarketingOptInIntent.peek()) return;
    final user = authState.currentUser;
    if (user == null) return;
    // Operatori non vedono il dialog
    if (user.isOperator) return;
    // Se ha già marketing attivo, consume silenziosamente senza dialog
    if (user.acceptedMarketing) {
      MarketingOptInIntent.consume();
      return;
    }
    _optInDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOptInDialog());
  }

  Future<void> _showOptInDialog() async {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final activated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final accent = palette.primary;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.card_giftcard, color: accent),
              const SizedBox(width: 8),
              const Expanded(child: Text('Attiva le promozioni')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vuoi ricevere offerte esclusive, sconti fino al -40% '
                'e novità via WhatsApp ed email?',
              ),
              const SizedBox(height: 12),
              Text(
                'Puoi disattivarle quando vuoi da Impostazioni → Account.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, grazie'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check),
              label: const Text('Sì, attiva'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    MarketingOptInIntent.consume();
    if (activated == true) {
      try {
        await authState.updateProfile(acceptMarketing: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Promozioni attivate. Grazie!'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authState,
      builder: (context, _) {
        if (authState.isLoading) {
          return const _SplashScreen();
        }
        // Trigger dialog opt-in se utente loggato + intent pending
        _maybeShowOptInDialog();
        final Widget child;
        if (!authState.isAuthenticated) {
          child = const WelcomeScreen(key: ValueKey('welcome'));
        } else if (authState.currentUser!.isOperator) {
          child = const OperatorScaffold(key: ValueKey('operator'));
        } else {
          child = const MainScaffold(key: ValueKey('main'));
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: child,
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/brand/silvestre_logo.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
