import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'i18n/translations.dart';
import 'screens/auth_gate.dart';
import 'state/catalog_images_state.dart';
import 'theme/app_theme.dart';

final ValueNotifier<SilvestreThemeSpec> currentTheme =
    ValueNotifier<SilvestreThemeSpec>(SilvestreThemes.classic);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Carica cache immagini catalogo Pexels (Firestore) all'avvio
  catalogImagesState.load();
  runApp(const SilvestreApp());
}

class SilvestreApp extends StatelessWidget {
  const SilvestreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeState,
      builder: (context, _) {
        return ValueListenableBuilder<SilvestreThemeSpec>(
          valueListenable: currentTheme,
          builder: (context, spec, _) {
            return MaterialApp(
              title: 'Silvestre Fotoservizi',
              debugShowCheckedModeBanner: false,
              theme: spec.build(),
              locale: localeState.locale,
              supportedLocales: const [Locale('it'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AuthGate(),
            );
          },
        );
      },
    );
  }
}
