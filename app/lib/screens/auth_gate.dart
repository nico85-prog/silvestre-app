import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import 'auth/welcome_screen.dart';
import 'main_scaffold.dart';
import 'operator/operator_scaffold.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authState,
      builder: (context, _) {
        if (authState.isLoading) {
          return const _SplashScreen();
        }
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
