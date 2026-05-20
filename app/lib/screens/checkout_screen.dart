import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  final String? customerNote;
  final ValueChanged<String> onNoteChanged;

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.customerNote,
    required this.onNoteChanged,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selected = PaymentMethod.inStore;
  late final TextEditingController _noteController =
      TextEditingController(text: widget.customerNote ?? '');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Caparra: 20% del totale, ma minimo kDepositMinAmount per evitare
  /// transazioni sotto soglia che gli operatori carta rifiutano.
  double get _depositAmount {
    final raw = widget.total * kDepositPercentage;
    final clamped = raw < kDepositMinAmount ? kDepositMinAmount : raw;
    // Mai chiedere caparra maggiore del totale (per ordini molto piccoli)
    final capped = clamped > widget.total ? widget.total : clamped;
    return double.parse(capped.toStringAsFixed(2));
  }

  double get _balanceAmount =>
      double.parse((widget.total - _depositAmount).toStringAsFixed(2));

  Future<void> _proceed() async {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    PaymentResult? result;

    switch (_selected) {
      case PaymentMethod.inStore:
        // Caparra 20% obbligatoria → scegli Carta o Satispay per il deposito
        result = await showModalBottomSheet<PaymentResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _DepositSheet(
            depositAmount: _depositAmount,
            balanceAmount: _balanceAmount,
            total: widget.total,
            palette: palette,
          ),
        );
        break;
      case PaymentMethod.card:
        result = await showModalBottomSheet<PaymentResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _StripeCardSheet(total: widget.total, palette: palette),
        );
        break;
    }

    if (result != null && mounted) {
      widget.onNoteChanged(_noteController.text);
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Come vuoi pagare?',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final m in PaymentMethod.values)
            _MethodTile(
              method: m,
              selected: _selected == m,
              onTap: () => setState(() => _selected = m),
              palette: palette,
            ),
          const SizedBox(height: 22),
          Text('Nota per il negozio (opzionale)',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Es. carta opaca, ritiro venerdì pomeriggio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront, color: palette.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ritiro in negozio',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary)),
                      Text(
                        'Via V. Emanuele III, 205 — Frattamaggiore',
                        style: TextStyle(
                            color: palette.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: palette.background,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Totale',
                      style: TextStyle(color: palette.textSecondary)),
                  const Spacer(),
                  Text('€ ${widget.total.toStringAsFixed(2)}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      )),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(_selected == PaymentMethod.inStore
                      ? Icons.storefront
                      : Icons.lock_outline),
                  label: Text(_ctaLabel),
                  onPressed: _proceed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _ctaLabel => switch (_selected) {
        PaymentMethod.inStore =>
            'Versa caparra € ${_depositAmount.toStringAsFixed(2)} e conferma',
        PaymentMethod.card => 'Paga € ${widget.total.toStringAsFixed(2)} con carta',
      };
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  final SilvestrePalette palette;
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  IconData get _icon => switch (method) {
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.inStore => Icons.storefront_outlined,
      };

  Color get _accent => switch (method) {
        PaymentMethod.card => const Color(0xFF1B6BFF), // SumUp blue
        PaymentMethod.inStore => palette.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.08)
                : palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _accent : palette.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        )),
                    Text(method.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textSecondary,
                        )),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? _accent : palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Demo Stripe-like card sheet. UI is real; backend charging is mocked.
/// When user provides real pk_test_/sk_test, swap _processFakeCharge for
/// real Stripe.confirmPayment call.
class _StripeCardSheet extends StatefulWidget {
  final double total;
  final SilvestrePalette palette;
  const _StripeCardSheet({required this.total, required this.palette});

  @override
  State<_StripeCardSheet> createState() => _StripeCardSheetState();
}

class _StripeCardSheetState extends State<_StripeCardSheet> {
  final _cardController = TextEditingController();
  final _expController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _cardController.dispose();
    _expController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    // SIMULATED Stripe charge (demo). To go live: integrate flutter_stripe.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final last4 = _cardController.text
        .replaceAll(' ', '')
        .padLeft(4, '0')
        .substring(_cardController.text.replaceAll(' ', '').length >= 4
            ? _cardController.text.replaceAll(' ', '').length - 4
            : 0);
    Navigator.pop(
      context,
      PaymentResult(
        method: PaymentMethod.card,
        transactionId: 'demo_ch_${DateTime.now().millisecondsSinceEpoch}',
        paidNow: true,
        lastFour: last4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: widget.palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF635BFF)),
              const SizedBox(width: 8),
              Text('Paga con carta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.palette.textPrimary,
                  )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.palette.warning.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('DEMO',
                    style: TextStyle(
                      color: widget.palette.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Test mode — nessun addebito reale. Per pagamenti veri serve account Stripe.',
              style: TextStyle(
                  fontSize: 11, color: widget.palette.textSecondary)),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome sulla carta',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Numero carta',
              hintText: '4242 4242 4242 4242 (test Stripe)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'MM/AA',
                    hintText: '12/28',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _cvcController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    hintText: '123',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF635BFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _processing ? null : _pay,
              child: _processing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Paga € ${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 12, color: widget.palette.textSecondary),
              const SizedBox(width: 4),
              Text('Sicuro · Powered by Stripe (demo)',
                  style: TextStyle(
                      fontSize: 10, color: widget.palette.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepositSheet extends StatefulWidget {
  final double depositAmount;
  final double balanceAmount;
  final double total;
  final SilvestrePalette palette;
  const _DepositSheet({
    required this.depositAmount,
    required this.balanceAmount,
    required this.total,
    required this.palette,
  });

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  Future<void> _payDeposit() async {
    final palette = widget.palette;
    final subResult = await showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _StripeCardSheet(total: widget.depositAmount, palette: palette),
    );
    if (subResult == null) return;
    if (!mounted) return;
    Navigator.pop(
      context,
      PaymentResult(
        method: PaymentMethod.inStore,
        paidNow: false,
        depositAmount: widget.depositAmount,
        depositMethod: PaymentMethod.card,
        depositTransactionId: subResult.transactionId,
        lastFour: subResult.lastFour,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: palette.primary),
              const SizedBox(width: 8),
              Text("Caparra obbligatoria",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Per confermare l'ordine devi versare il 20% di caparra. Il saldo lo paghi al ritiro in negozio.",
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                _depRow("Totale ordine",
                    "EUR ${widget.total.toStringAsFixed(2)}", palette,
                    bold: false),
                const SizedBox(height: 6),
                _depRow(
                    "Caparra (20%, paga ora)",
                    "EUR ${widget.depositAmount.toStringAsFixed(2)}",
                    palette,
                    bold: true,
                    highlight: true),
                const SizedBox(height: 6),
                _depRow(
                    "Saldo (al ritiro)",
                    "EUR ${widget.balanceAmount.toStringAsFixed(2)}",
                    palette,
                    bold: false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.credit_card),
              label: Text(
                  "Versa EUR ${widget.depositAmount.toStringAsFixed(2)} con carta"),
              onPressed: _payDeposit,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
        ],
      ),
    );
  }

  Widget _depRow(String k, String v, SilvestrePalette palette,
      {bool bold = false, bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(k,
              style: TextStyle(
                color: highlight ? palette.primary : palette.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              )),
        ),
        Text(v,
            style: TextStyle(
              color: highlight ? palette.primary : palette.textPrimary,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 13,
            )),
      ],
    );
  }
}

