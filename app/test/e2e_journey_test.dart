import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silvestre_app/data/mock_catalog.dart';
import 'package:silvestre_app/main.dart' as app;
import 'package:silvestre_app/state/auth_state.dart';
import 'package:silvestre_app/state/cart_state.dart';
import 'package:silvestre_app/state/orders_state.dart';

void main() {
  setUp(() async {
    if (authState.isAuthenticated) {
      await authState.deleteAccount();
    }
    cartState.clear();
  });

  testWidgets('FULL JOURNEY: registration → browse → cart → submit → orders → account',
      (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // --- STEP 1: Welcome ---
    expect(find.text('Silvestre Fotoservizi'), findsWidgets);
    expect(find.text('Accedi'), findsOneWidget);
    expect(find.text('Crea un account'), findsOneWidget);

    // --- STEP 2: Tap "Crea un account" ---
    await tester.tap(find.text('Crea un account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // --- STEP 3: Fill registration form ---
    final ts = DateTime.now().millisecondsSinceEpoch;
    final email = 'e2e_$ts@silvestre.test';

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome e cognome'), 'Mario Rossi');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefono (opzionale)'),
        '3331234567');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'TestPass123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Conferma password'),
        'TestPass123');

    // Check TOS (first checkbox)
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsAtLeastNWidgets(3));
    await tester.tap(checkboxes.first);
    await tester.pump();

    // --- STEP 4: Submit registration ---
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Crea account'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crea account'));
    // Wait for the simulated 400ms delay in mock auth
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // --- STEP 5: Main scaffold (Catalogo) ---
    expect(find.text('Catalogo'), findsOneWidget,
        reason: 'Bottom nav Catalogo should appear after registration');
    expect(find.text('Ordini'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Cosa vuoi creare oggi?'), findsOneWidget);
    expect(find.text('Stampe foto'), findsOneWidget);

    // --- STEP 6: Tap Stampe foto ---
    await tester.tap(find.text('Stampe foto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Stampa classica'), findsOneWidget);

    // --- STEP 7: Tap product detail ---
    await tester.tap(find.text('Stampa classica'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // --- STEP 8: All variants visible ---
    expect(find.text('Scegli il formato'), findsOneWidget);
    expect(find.text('10x15 cm'), findsOneWidget);
    expect(find.text('13x18 cm'), findsOneWidget);
    expect(find.text('15x21 cm'), findsOneWidget);
    expect(find.text('20x30 cm'), findsOneWidget);
    expect(find.text('30x45 cm'), findsOneWidget);

    // --- STEP 9: Select 13x18 ---
    await tester.ensureVisible(find.text('13x18 cm'));
    await tester.tap(find.text('13x18 cm'));
    await tester.pump();

    // --- STEP 10: Increase quantity to 3 ---
    final addButton = find.byIcon(Icons.add);
    await tester.ensureVisible(addButton.first);
    await tester.tap(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await tester.pump();

    // --- STEP 11: Add to cart ---
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Aggiungi'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Aggiungi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // --- STEP 12: Cart state has 1 line ---
    expect(cartState.items.length, 1);
    expect(cartState.items.first.quantity, 3);
    expect(cartState.items.first.variantName, '13x18 cm');

    // --- STEP 13: Open cart via badge button ---
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Il tuo carrello'), findsOneWidget);
    expect(find.text('Stampa classica'), findsOneWidget);
    expect(find.text('Invia ordine — Paga in negozio'), findsOneWidget);

    // --- STEP 14: Submit order ---
    await tester.tap(find.text('Invia ordine — Paga in negozio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ordine inviato!'), findsOneWidget);
    expect(find.text('Codice ritiro'), findsOneWidget);

    await tester.tap(find.text('Ho capito'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // --- STEP 15: Cart cleared, order persisted ---
    expect(cartState.items.isEmpty, true);
    final user = authState.currentUser!;
    expect(ordersState.forUser(user.id).length, greaterThanOrEqualTo(1));

    // --- STEP 16: Navigate to Ordini tab ---
    await tester.tap(find.text('Ordini'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Ricevuto'), findsOneWidget);

    // --- STEP 17: Open order detail ---
    await tester.tap(find.textContaining('Ricevuto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Codice di ritiro'), findsOneWidget);
    expect(find.text('Stato'), findsOneWidget);

    // --- STEP 18: Back, then Account tab ---
    // Pop the order detail
    final navState =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navState.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text(email), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
    expect(find.text('Esporta i miei dati'), findsOneWidget);
    expect(find.text('Elimina il mio account'), findsOneWidget);
    expect(find.text('Informativa Privacy'), findsOneWidget);
    expect(find.text('Termini di Servizio'), findsOneWidget);

    // --- STEP 19: Logout ---
    await tester.ensureVisible(find.text('Esci'));
    await tester.tap(find.text('Esci'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Accedi'), findsOneWidget);
  });

  testWidgets('Every category opens and shows at least one product',
      (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Quick register
    await tester.tap(find.text('Crea un account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final email = 'cat_${DateTime.now().millisecondsSinceEpoch}@silvestre.test';
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome e cognome'), 'Cat Tester');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'TestPass123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Conferma password'),
        'TestPass123');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Crea account'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crea account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    for (final cat in MockCatalog.categories) {
      await tester.ensureVisible(find.text(cat.name));
      await tester.tap(find.text(cat.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final products = MockCatalog.byCategory(cat.id);
      expect(find.text(products.first.name), findsOneWidget,
          reason:
              'First product (${products.first.name}) of category ${cat.name} should render');

      // Pop back to home
      final nav =
          tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  testWidgets('Theme switching from picker', (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Crea un account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final email =
        'theme_${DateTime.now().millisecondsSinceEpoch}@silvestre.test';
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome e cognome'), 'Theme Tester');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'TestPass123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Conferma password'),
        'TestPass123');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Crea account'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crea account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Scegli il tema'), findsOneWidget);
    expect(find.text('Heritage'), findsOneWidget);
    expect(find.text('Modern Studio'), findsOneWidget);
    expect(find.text('Sunset Soft'), findsOneWidget);
    expect(find.text('Mono Bold'), findsOneWidget);
  });

  testWidgets('Login flow with existing account', (tester) async {
    // Register a user out-of-band
    final email = 'login_${DateTime.now().millisecondsSinceEpoch}@silvestre.test';
    await authState.register(
      email: email,
      password: 'TestPass123',
      displayName: 'Login Tester',
      acceptTos: true,
    );
    await authState.logout();

    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Accedi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'TestPass123');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Accedi'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Catalogo'), findsOneWidget);
    expect(find.text('Cosa vuoi creare oggi?'), findsOneWidget);
  });

  testWidgets('Login with wrong password shows error', (tester) async {
    final email = 'wrong_${DateTime.now().millisecondsSinceEpoch}@silvestre.test';
    await authState.register(
      email: email,
      password: 'Correct123',
      displayName: 'Wrong Tester',
      acceptTos: true,
    );
    await authState.logout();

    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Accedi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'WRONG');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Password errata'), findsOneWidget);
  });
}
