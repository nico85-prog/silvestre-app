import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/brand/silvestre_logo.jpg',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Silvestre Fotoservizi',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le tue foto, stampate con cura dal 1970.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Accedi'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primary,
                    side: BorderSide(color: palette.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Crea un account'),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text('Continuando accetti i ',
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary)),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TermsScreen()),
                    ),
                    child: Text('Termini',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.primary,
                          decoration: TextDecoration.underline,
                        )),
                  ),
                  Text(' e la ',
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary)),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen()),
                    ),
                    child: Text('Privacy',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.primary,
                          decoration: TextDecoration.underline,
                        )),
                  ),
                  Text('.',
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
