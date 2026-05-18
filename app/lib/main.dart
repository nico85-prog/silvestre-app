import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

final ValueNotifier<SilvestreThemeSpec> currentTheme =
    ValueNotifier<SilvestreThemeSpec>(SilvestreThemes.classic);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SilvestreApp());
}

class SilvestreApp extends StatelessWidget {
  const SilvestreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SilvestreThemeSpec>(
      valueListenable: currentTheme,
      builder: (context, spec, _) {
        return MaterialApp(
          title: 'Silvestre Fotoservizi',
          debugShowCheckedModeBanner: false,
          theme: spec.build(),
          home: const AuthGate(),
        );
      },
    );
  }
}
