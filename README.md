# Silvestre Fotoservizi — App

Piattaforma mobile/web per il negozio di fotografia Silvestre Fotoservizi (Frattamaggiore, NA).

**Live demo:** https://silvestre-fotoservizi.web.app

## Stack
- **App:** Flutter (Dart) — iOS + Android + Web
- **Auth + Database:** Firebase (Auth, Firestore)
- **Storage foto:** Cloudinary (free tier 25GB)
- **Push notifications:** Firebase Cloud Messaging
- **Backend automations:** Firebase Cloud Functions (richiede Blaze)
- **Pagamenti:** Stripe + Satispay + Paga in negozio (UI pronta, integrazione finale al rilascio)

## Struttura

```
SilvestreApp/
├ app/                    Flutter project (silvestre_app)
│  ├ lib/                 Sorgenti Dart
│  ├ web/                 PWA manifest + icons
│  ├ android/             Config Android
│  └ ios/                 Config iOS
├ firebase/               Firebase config + rules + functions
│  ├ firestore.rules
│  ├ storage.rules
│  └ functions/           Cloud Functions Node 20
├ docs/                   Documentazione + script .py per rigenerarla
└ .github/workflows/      CI/CD GitHub Actions
```

## Sviluppo locale

```bash
cd app
flutter pub get
flutter run -d chrome --web-port=8080
```

## Test

```bash
cd app
flutter test
```

## Deploy manuale (se non vuoi aspettare la CI)

```bash
cd app
flutter build web --release
cp -r build/web/* ../firebase/public/
cd ../firebase
firebase deploy --only hosting
```

## Deploy automatico

Ogni push su `main` triggera GitHub Actions che:
1. Esegue `flutter analyze` + `flutter test`
2. Build web release
3. Deploy su Firebase Hosting

URL pubblico aggiornato in 3-5 minuti.

## Documentazione

Vedi `docs/MANUALE_GENERALE_Silvestre.docx` come entry point.
