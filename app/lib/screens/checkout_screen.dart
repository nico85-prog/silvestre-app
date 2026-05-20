import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/payment.dart';
import '../services/cloudinary_service.dart';
import '../state/auth_state.dart';
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
      case PaymentMethod.satispay:
        result = await showModalBottomSheet<PaymentResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SatispaySheet(total: widget.total, palette: palette),
        );
        break;
      case PaymentMethod.bankTransfer:
        result = await showModalBottomSheet<PaymentResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              _BankTransferSheet(total: widget.total, palette: palette),
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
        PaymentMethod.satispay =>
            'Paga € ${widget.total.toStringAsFixed(2)} con Satispay',
        PaymentMethod.bankTransfer =>
            'Versa € ${widget.total.toStringAsFixed(2)} con bonifico',
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
        PaymentMethod.satispay => Icons.smartphone,
        PaymentMethod.bankTransfer => Icons.account_balance,
        PaymentMethod.inStore => Icons.storefront_outlined,
      };

  Color get _accent => switch (method) {
        PaymentMethod.card => const Color(0xFF635BFF), // Stripe purple
        PaymentMethod.satispay => const Color(0xFFEB4F2A), // Satispay orange
        PaymentMethod.bankTransfer => const Color(0xFF2E7D32), // 0% fee green
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

/// Demo Satispay sheet showing QR + "Ho pagato" button.
class _SatispaySheet extends StatefulWidget {
  final double total;
  final SilvestrePalette palette;
  const _SatispaySheet({required this.total, required this.palette});

  @override
  State<_SatispaySheet> createState() => _SatispaySheetState();
}

class _SatispaySheetState extends State<_SatispaySheet> {
  bool _processing = false;

  Future<void> _confirm() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(
      context,
      PaymentResult(
        method: PaymentMethod.satispay,
        transactionId: 'demo_sps_${DateTime.now().millisecondsSinceEpoch}',
        paidNow: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: widget.palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.smartphone, color: Color(0xFFEB4F2A)),
              const SizedBox(width: 8),
              Text('Paga con Satispay',
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
          const SizedBox(height: 16),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.palette.border, width: 2),
            ),
            child: CustomPaint(
              painter: _FakeQrPainter(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '€ ${widget.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: widget.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apri Satispay → Scansiona QR',
            style: TextStyle(color: widget.palette.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB4F2A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _processing ? null : _confirm,
              child: _processing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Ho completato il pagamento',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }
}

class _FakeQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cell = size.width / 21;
    // Fake QR pattern with checker
    final pattern = [
      '111111101010111111100',
      '100000101101100000100',
      '101110100110101110100',
      '101110101110101110100',
      '101110100000101110100',
      '100000101110100000100',
      '111111101010111111100',
      '000000000110000000000',
      '110101110011101110100',
      '011010100110110100110',
      '101110101010101010101',
      '011011100110100101110',
      '110100110011101100100',
      '000000000110010110110',
      '111111100110110101010',
      '100000101011010110101',
      '101110101101111100100',
      '101110100110100010110',
      '101110101010111110100',
      '100000100110100100010',
      '111111100110110110110',
    ];
    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        if (pattern[r][c] == '1') {
          canvas.drawRect(
            Rect.fromLTWH(c * cell + 4, r * cell + 4, cell - 1, cell - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  PaymentMethod _depositVia = PaymentMethod.card;

  Future<void> _payDeposit() async {
    PaymentResult? subResult;
    final palette = widget.palette;
    if (_depositVia == PaymentMethod.card) {
      subResult = await showModalBottomSheet<PaymentResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _StripeCardSheet(total: widget.depositAmount, palette: palette),
      );
    } else {
      subResult = await showModalBottomSheet<PaymentResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _SatispaySheet(total: widget.depositAmount, palette: palette),
      );
    }
    if (subResult == null) return;
    if (!mounted) return;
    Navigator.pop(
      context,
      PaymentResult(
        method: PaymentMethod.inStore,
        paidNow: false,
        depositAmount: widget.depositAmount,
        depositMethod: _depositVia,
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
          const SizedBox(height: 18),
          Text("Come paghi la caparra?",
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: palette.textPrimary)),
          const SizedBox(height: 8),
          _DepositMethodTile(
            method: PaymentMethod.card,
            selected: _depositVia == PaymentMethod.card,
            onTap: () => setState(() => _depositVia = PaymentMethod.card),
            palette: palette,
          ),
          _DepositMethodTile(
            method: PaymentMethod.satispay,
            selected: _depositVia == PaymentMethod.satispay,
            onTap: () => setState(() => _depositVia = PaymentMethod.satispay),
            palette: palette,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock),
              label: Text(
                  "Versa EUR ${widget.depositAmount.toStringAsFixed(2)} di caparra"),
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

class _DepositMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  final SilvestrePalette palette;
  const _DepositMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final accent = method == PaymentMethod.card
        ? const Color(0xFF635BFF)
        : const Color(0xFFEB4F2A);
    final icon = method == PaymentMethod.card
        ? Icons.credit_card
        : Icons.smartphone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected ? accent.withValues(alpha: 0.08) : palette.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? accent : palette.border,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(method.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    )),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? accent : palette.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bonifico Istantaneo: 0% commissione. Cliente paga dalla sua banca,
/// carica la ricevuta, operatore verifica a mano sul conto e conferma.
class _BankTransferSheet extends StatefulWidget {
  final double total;
  final SilvestrePalette palette;
  const _BankTransferSheet({required this.total, required this.palette});

  @override
  State<_BankTransferSheet> createState() => _BankTransferSheetState();
}

class _BankTransferSheetState extends State<_BankTransferSheet> {
  // Causale = pickupCode pre-generato. L'operatore lo cercherà sull'estratto
  // conto per identificare quale ordine è stato pagato.
  late final String _causale =
      'SLV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  final ImagePicker _picker = ImagePicker();

  String? _proofUrl;
  bool _uploading = false;
  bool _confirming = false;

  Future<void> _pickAndUploadProof() async {
    final user = authState.currentUser;
    if (user == null) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await CloudinaryService.uploadBytes(
        bytes: bytes,
        fileName: picked.name,
        userId: user.id,
        folderSuffix: 'bank_transfer_proofs',
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _proofUrl = result.url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload ricevuta fallito: $e')),
      );
    }
  }

  Future<void> _confirm() async {
    if (_proofUrl == null) return;
    setState(() => _confirming = true);
    if (!mounted) return;
    Navigator.pop(
      context,
      PaymentResult(
        method: PaymentMethod.bankTransfer,
        transactionId: _causale, // = pickupCode, usato anche come causale
        paidNow: false,
        verified: false,
        proofUrl: _proofUrl,
      ),
    );
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiato'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text('Bonifico Istantaneo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('0% FEE',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Effettua il bonifico dall\'app della tua banca usando i dati '
              'qui sotto. Poi carica una foto della ricevuta.',
              style:
                  TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            const SizedBox(height: 18),
            _bankRow(
              palette,
              label: 'IBAN',
              value: kShopBankAccount.iban,
              onCopy: () => _copyToClipboard(kShopBankAccount.iban, 'IBAN'),
              monospace: true,
            ),
            const SizedBox(height: 8),
            _bankRow(
              palette,
              label: 'Intestatario',
              value: kShopBankAccount.holder,
              onCopy: () => _copyToClipboard(
                  kShopBankAccount.holder, 'Intestatario'),
            ),
            const SizedBox(height: 8),
            _bankRow(
              palette,
              label: 'Banca',
              value: kShopBankAccount.bankName,
              onCopy: null,
            ),
            const SizedBox(height: 8),
            _bankRow(
              palette,
              label: 'Importo',
              value: '€ ${widget.total.toStringAsFixed(2)}',
              onCopy: () => _copyToClipboard(
                  widget.total.toStringAsFixed(2), 'Importo'),
              highlight: true,
            ),
            const SizedBox(height: 8),
            _bankRow(
              palette,
              label: 'Causale',
              value: _causale,
              onCopy: () => _copyToClipboard(_causale, 'Causale'),
              monospace: true,
              highlight: true,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: palette.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: palette.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inserisci la causale ESATTA per identificare il '
                      'tuo ordine. Senza causale corretta il bonifico '
                      'potrebbe non essere associato in tempi rapidi.',
                      style: TextStyle(
                          fontSize: 11, color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_proofUrl == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(_uploading
                      ? 'Caricamento ricevuta…'
                      : 'Carica foto della ricevuta'),
                  onPressed: _uploading ? null : _pickAndUploadProof,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E7D32)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF2E7D32)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Ricevuta caricata',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _proofUrl = null),
                      child: const Text('Cambia'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (_proofUrl == null || _confirming) ? null : _confirm,
                child: _confirming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Conferma ordine (in attesa verifica)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            const SizedBox(height: 4),
            Text(
              'L\'ordine partirà in lavorazione dopo che l\'operatore avrà '
              'verificato il bonifico sul conto bancario (di solito entro '
              '1-2 ore in orario di apertura).',
              style: TextStyle(
                  fontSize: 11,
                  color: palette.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankRow(
    SilvestrePalette palette, {
    required String label,
    required String value,
    VoidCallback? onCopy,
    bool monospace = false,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? palette.primary.withValues(alpha: 0.08)
            : palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? palette.primary.withValues(alpha: 0.4)
              : palette.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? palette.primary : palette.textPrimary,
                fontFamily: monospace ? 'Consolas' : null,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
                letterSpacing: monospace ? 0.5 : 0,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Copia',
            ),
        ],
      ),
    );
  }
}
