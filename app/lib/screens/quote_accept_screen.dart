import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../state/auth_state.dart';
import '../state/orders_state.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

/// Schermata: cliente inserisce il codice preventivo ricevuto via WhatsApp.
/// Lookup Firestore: se trovato in stato 'quoted', porta a QuoteAcceptScreen.
class EnterQuoteCodeScreen extends StatefulWidget {
  const EnterQuoteCodeScreen({super.key});

  @override
  State<EnterQuoteCodeScreen> createState() => _EnterQuoteCodeScreenState();
}

class _EnterQuoteCodeScreenState extends State<EnterQuoteCodeScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final user = authState.currentUser;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await ordersState.findQuoteByCode(
        pickupCode: code,
        userId: user.id,
      );
      if (!mounted) return;
      if (order == null) {
        setState(() {
          _loading = false;
          _error =
              'Codice non valido o ordine non in stato preventivo.';
        });
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => QuoteAcceptScreen(order: order)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Errore: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Codice preventivo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inserisci il codice ricevuto via WhatsApp dal negozio.',
              style: TextStyle(color: palette.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Codice (es. SLV-1234567)',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              autofocus: true,
              onSubmitted: (_) => _lookup(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _lookup,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Cerca preventivo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Schermata che mostra dettagli preventivo + bottoni paga/test/declina.
class QuoteAcceptScreen extends StatelessWidget {
  final CustomerOrder order;
  const QuoteAcceptScreen({super.key, required this.order});

  Future<void> _proceedToPayment(BuildContext context) async {
    final total = order.quoteAmount ?? order.total;
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final paymentResult = await Navigator.push<PaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          total: total,
          customerNote: null,
          onNoteChanged: (_) {},
        ),
      ),
    );
    if (paymentResult == null || !context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: palette.primary)),
    );
    try {
      await ordersState.acceptQuote(order.id, payment: paymentResult);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Errore: $e')));
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preventivo accettato!'),
        content: Text(
            'Il tuo ordine ${order.pickupCode} è ora in lavorazione. Trovi il dettaglio nella tab Ordini.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedTest(BuildContext context) async {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: palette.primary)),
    );
    try {
      await ordersState.acceptQuote(
        order.id,
        payment: const PaymentResult(
          method: PaymentMethod.inStore,
          paidNow: false,
          transactionId: 'TEST_BYPASS',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Errore: $e')));
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preventivo accettato (TEST)'),
        content: Text(
            'Ordine ${order.pickupCode} in lavorazione. Modalita\' test: nessun pagamento processato.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _decline(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Declinare il preventivo?'),
        content: const Text(
            'L\'ordine sarà annullato. Potrai sempre fare una nuova richiesta.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sì, declina')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ordersState.declineQuote(order.id);
    if (!context.mounted) return;
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final total = order.quoteAmount ?? order.total;
    return Scaffold(
      appBar: AppBar(title: Text('Preventivo ${order.pickupCode}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LA TUA RICHIESTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.textSecondary,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 4),
                Text(
                  order.customRequestTitle ?? '(senza titolo)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: palette.textPrimary,
                  ),
                ),
                if ((order.customRequestDescription ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    order.customRequestDescription!,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('PREVENTIVO DEL NEGOZIO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: palette.textSecondary,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Importo:', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text(
                      '€ ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Text('Tempi:', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text(
                      order.quoteEta ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if ((order.quoteOperatorNote ?? '').isNotEmpty) ...[
                  const Divider(),
                  Text('Nota:',
                      style: TextStyle(
                          fontSize: 11, color: palette.textSecondary)),
                  const SizedBox(height: 4),
                  Text(order.quoteOperatorNote!,
                      style: TextStyle(color: palette.textPrimary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: Text('Accetta e paga € ${total.toStringAsFixed(2)}'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _proceedToPayment(context),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.science_outlined),
            label: const Text('Accetta TEST (bypass pagamento)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _proceedTest(context),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Declina preventivo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: palette.error,
              side: BorderSide(color: palette.error),
            ),
            onPressed: () => _decline(context),
          ),
        ],
      ),
    );
  }
}
