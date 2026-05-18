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

  Future<void> _proceed() async {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    PaymentResult? result;

    switch (_selected) {
      case PaymentMethod.inStore:
        result = const PaymentResult(
          method: PaymentMethod.inStore,
          paidNow: false,
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
        PaymentMethod.inStore => 'Conferma ordine (paga in negozio)',
        PaymentMethod.card => 'Paga € ${widget.total.toStringAsFixed(2)} con carta',
        PaymentMethod.satispay =>
            'Paga € ${widget.total.toStringAsFixed(2)} con Satispay',
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
        PaymentMethod.inStore => Icons.storefront_outlined,
      };

  Color get _accent => switch (method) {
        PaymentMethod.card => const Color(0xFF635BFF), // Stripe purple
        PaymentMethod.satispay => const Color(0xFFEB4F2A), // Satispay orange
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
