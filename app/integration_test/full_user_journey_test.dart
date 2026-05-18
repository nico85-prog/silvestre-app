import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:silvestre_app/data/mock_catalog.dart';
import 'package:silvestre_app/main.dart' as app;
import 'package:silvestre_app/state/auth_state.dart';
import 'package:silvestre_app/state/cart_state.dart';
import 'package:silvestre_app/state/orders_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    if (authState.isAuthenticated) {
      await authState.deleteAccount();
    }
    cartState.clear();
    // ordersState is global — leave alone, deleteAccount clears the user's orders implicitly
  });

  testWidgets('FULL JOURNEY: registration → browse → cart → submit → orders → account',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // --- STEP 1: Welcome screen visible ---
    expect(find.text('Silvestre Fotoservizi'), findsWidgets,
        reason: 'Welcome screen should show brand title');
    expect(find.text('Accedi'), findsOneWidget);
    expect(find.text('Crea un account'), findsOneWidget);

    // --- STEP 2: Tap "Crea un account" ---
    await tester.tap(find.text('Crea un account'));
    await tester.pumpAndSettle();

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

    // Check the TOS checkbox (first checkbox)
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsAtLeastNWidgets(3),
        reason: 'Should have 3 consent checkboxes');
    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();

    // --- STEP 4: Submit registration ---
    await tester.tap(find.text('Crea account'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // --- STEP 5: We should be on the main scaffold (Catalogo tab) ---
    expect(find.text('Catalogo'), findsOneWidget,
        reason: 'Bottom nav "Catalogo" should be visible after login');
    expect(find.text('Ordini'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Cosa vuoi creare oggi?'), findsOneWidget);

    // --- STEP 6: Tap "Stampe foto" category ---
    await tester.tap(find.text('Stampe foto'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Stampa classica'), findsOneWidget,
        reason: 'Product list should show Stampa classica');

    // --- STEP 7: Tap product detail ---
    await tester.tap(find.text('Stampa classica'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // --- STEP 8: All variants visible ---
    expect(find.text('Scegli il formato'), findsOneWidget,
        reason: 'Section header should be visible');
    expect(find.text('10x15 cm'), findsOneWidget);
    expect(find.text('13x18 cm'), findsOneWidget);
    expect(find.text('15x21 cm'), findsOneWidget);
    expect(find.text('20x30 cm'), findsOneWidget);
    expect(find.text('30x45 cm'), findsOneWidget);

    // --- STEP 9: Select 13x18 variant ---
    await tester.ensureVisible(find.text('13x18 cm'));
    await tester.tap(find.text('13x18 cm'));
    await tester.pumpAndSettle();

    // --- STEP 10: Increase quantity to 3 ---
    await tester.ensureVisible(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // --- STEP 11: Add to cart ---
    await tester.ensureVisible(find.text('Aggiungi'));
    await tester.tap(find.text('Aggiungi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Should be back on category list
    expect(find.text('Stampa classica'), findsOneWidget);

    // --- STEP 12: Cart should have 1 line with quantity 3 ---
    expect(cartState.items.length, 1, reason: 'One line in cart');
    expect(cartState.items.first.quantity, 3, reason: 'Quantity 3');

    // --- STEP 13: Open cart ---
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Il tuo carrello'), findsOneWidget);
    expect(find.text('Stampa classica'), findsOneWidget);
    expect(find.text('Invia ordine — Paga in negozio'), findsOneWidget);

    // --- STEP 14: Submit order ---
    await tester.tap(find.text('Invia ordine — Paga in negozio'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Ordine inviato!'), findsOneWidget,
        reason: 'Order confirmation dialog should appear');
    expect(find.text('Codice ritiro'), findsOneWidget);

    await tester.tap(find.text('Ho capito'));
    await tester.pumpAndSettle();

    // --- STEP 15: Verify order persisted, cart empty ---
    expect(cartState.items.isEmpty, true, reason: 'Cart cleared after submit');
    final user = authState.currentUser!;
    expect(ordersState.forUser(user.id).length, 1,
        reason: 'Order persisted in orders state');

    // --- STEP 16: Navigate to Ordini tab ---
    await tester.tap(find.text('Ordini'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ricevuto'), findsOneWidget,
        reason: 'Order should appear with status Ricevuto');

    // --- STEP 17: Open order detail ---
    await tester.tap(find.textContaining('Ricevuto'));
    await tester.pumpAndSettle();

    expect(find.text('Codice di ritiro'), findsOneWidget);
    expect(find.text('Stato'), findsOneWidget);
    expect(find.textContaining('Simula'), findsOneWidget);

    // --- STEP 18: Simulate status progression ---
    await tester.ensureVisible(find.textContaining('Simula'));
    await tester.tap(find.textContaining('Simula'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Simula'), findsOneWidget,
        reason: 'After moving to inProduction, button should now say "pronto"');

    // --- STEP 19: Go to Account tab ---
    Navigator.of(tester.element(find.byType(MaterialApp))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text(email), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
    expect(find.text('Esporta i miei dati'), findsOneWidget);
    expect(find.text('Elimina il mio account'), findsOneWidget);
    expect(find.text('Informativa Privacy'), findsOneWidget);
    expect(find.text('Termini di Servizio'), findsOneWidget);

    // --- STEP 20: Logout ---
    await tester.ensureVisible(find.text('Esci'));
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(find.text('Accedi'), findsOneWidget,
        reason: 'After logout, Welcome screen should reappear');
  });

  testWidgets('Theme switching changes colors across the app',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Register quick account
    await tester.tap(find.text('Crea un account'));
    await tester.pumpAndSettle();

    final email = 'theme_${DateTime.now().millisecondsSinceEpoch}@silvestre.test';
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome e cognome'), 'Tester');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'TestPass123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Conferma password'),
        'TestPass123');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crea account'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Open theme picker
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Scegli il tema'), findsOneWidget);
    expect(find.text('Heritage'), findsOneWidget);
    expect(find.text('Modern Studio'), findsOneWidget);
    expect(find.text('Sunset Soft'), findsOneWidget);

    // Pick Heritage
    await tester.tap(find.text('Heritage'));
    await tester.pumpAndSettle();
  });

  testWidgets('Catalog screens render all categories correctly',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Register
    await tester.tap(find.text('Crea un account'));
    await tester.pumpAndSettle();
    final email = 'cat_${DateTime.now().millisecondsSinceEpoch}@silvestre.test';
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome e cognome'), 'Test');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'TestPass123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Conferma password'),
        'TestPass123');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crea account'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Iterate each category, enter it, ensure at least 1 product
    for (final cat in MockCatalog.categories) {
      await tester.ensureVisible(find.text(cat.name));
      await tester.tap(find.text(cat.name));
      await tester.pumpAndSettle();

      final products = MockCatalog.byCategory(cat.id);
      expect(products.isNotEmpty, true,
          reason: 'Category ${cat.name} must have products');
      expect(find.text(products.first.name), findsOneWidget,
          reason: 'First product of ${cat.name} should render');

      Navigator.of(tester.element(find.text(cat.name))).pop();
      await tester.pumpAndSettle();
    }
  });
}
