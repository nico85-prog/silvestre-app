import 'package:flutter_test/flutter_test.dart';
import 'package:silvestre_app/main.dart';

void main() {
  testWidgets('Welcome screen shows brand on first launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SilvestreApp());
    await tester.pump();

    expect(find.text('Silvestre Fotoservizi'), findsOneWidget);
    expect(find.text('Accedi'), findsOneWidget);
    expect(find.text('Crea un account'), findsOneWidget);
  });
}
