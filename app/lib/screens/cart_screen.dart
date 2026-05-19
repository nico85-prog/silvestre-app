import 'package:flutter/material.dart';
import '../data/mock_catalog.dart';
import '../models/payment.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../state/orders_state.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Il tuo carrello')),
      body: AnimatedBuilder(
        animation: cartState,
        builder: (context, _) {
          if (cartState.items.isEmpty) {
            return _EmptyCart(palette: palette);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cartState.items.map((item) {
                String? description;
                try {
                  description = MockCatalog.byId(item.productId).description;
                } catch (_) {}
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: item.photoUrls.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.photoUrls.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(
                                                Icons.broken_image_outlined),
                                      ),
                                    )
                                  : ProductImage(
                                      seed: 'cart_${item.id}',
                                      width: 400,
                                      height: 400,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      )),
                                  Text(item.variantName,
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: palette.textSecondary),
                              onPressed: () => cartState.removeItem(item.id),
                            ),
                          ],
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: palette.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline,
                                    size: 14, color: palette.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Quantità',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                  fontSize: 13,
                                )),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: palette.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: palette.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: item.quantity > 1
                                        ? () => cartState.updateQuantity(
                                            item.id, item.quantity - 1)
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(Icons.remove,
                                          size: 16,
                                          color: item.quantity > 1
                                              ? palette.textPrimary
                                              : palette.textSecondary),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 34,
                                    child: Text('${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: palette.textPrimary,
                                        )),
                                  ),
                                  InkWell(
                                    onTap: () => cartState.updateQuantity(
                                        item.id, item.quantity + 1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(Icons.add,
                                          size: 16,
                                          color: palette.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '€ ${item.lineTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: palette.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '€ ${item.unitPrice.toStringAsFixed(2)} cad.',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (item.photoUrls.length > 1) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: item.photoUrls.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (_, i) => ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.photoUrls[i],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox(width: 40, height: 40),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nota per il negozio (opzionale)',
                  hintText: 'Es. preferisco carta opaca, ritiro venerdì',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
                                color: palette.textPrimary,
                              )),
                          Text(
                            'Via Vittorio Emanuele III, 205 — Frattamaggiore',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: cartState,
        builder: (context, _) {
          if (cartState.items.isEmpty) return const SizedBox.shrink();
          return SafeArea(
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
                      Text(
                        '€ ${cartState.total.toStringAsFixed(2)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Invia ordine'),
                      onPressed: _submitOrder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // PULSANTE TEST: bypassa pagamento. Rimuovere prima del lancio reale.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Invia ordine TEST (bypass pagamento)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B57),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _submitTestOrder,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Bypass pagamento/caparra: invia ordine direttamente come "submitted".
  /// Usato solo in fase di test. Da rimuovere prima del lancio reale.
  Future<void> _submitTestOrder() async {
    final user = authState.currentUser;
    if (user == null) return;
    // CONFIRM: evita tap accidentale del bottone test in produzione
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFD32F2F), size: 40),
        title: const Text('MODALITÀ TEST'),
        content: const Text(
            'Stai per inviare un ordine SENZA PAGAMENTO.\n\n'
            'L\'ordine sarà marcato come "TEST_BYPASS" in DB.\n\n'
            'Procedere?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sì, invia TEST'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: palette.primary),
      ),
    );
    String pickupCode;
    try {
      pickupCode = await ordersState.submitOrder(
        userId: user.id,
        items: cartState.items,
        customerNote: '[TEST] ${_noteController.text.trim()}'.trim(),
        customerName: user.displayName,
        customerPhone: user.phone,
        payment: const PaymentResult(
          method: PaymentMethod.inStore,
          paidNow: false,
          transactionId: 'TEST_BYPASS',
        ),
      );
      // FIX 5 ANTICIPATO: cart cleared SUBITO dopo submit success,
      // prima del dialog. Evita duplicati se dialog non si apre.
      cartState.clear();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore invio ordine: $e')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context); // chiudo loader
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ordine TEST inviato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Modalità test: nessun pagamento processato. Codice ritiro:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(pickupCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  )),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cart già clear sopra
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOrder() async {
    final user = authState.currentUser;
    if (user == null) return;

    // Step 1: open checkout to pick payment method
    final paymentResult = await Navigator.push<PaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          total: cartState.total,
          customerNote: _noteController.text,
          onNoteChanged: (v) => _noteController.text = v,
        ),
      ),
    );
    if (paymentResult == null || !mounted) return;

    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: palette.primary),
      ),
    );

    String pickupCode;
    try {
      pickupCode = await ordersState.submitOrder(
        userId: user.id,
        items: cartState.items,
        customerNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        customerName: user.displayName,
        customerPhone: user.phone,
        payment: paymentResult,
      );
      // FIX: clear cart SUBITO dopo submit success, prima del dialog.
      // Evita duplicati se dialog fail to mount o context perso.
      cartState.clear();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore invio ordine: $e')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // close loader

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ordine inviato!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Il negozio ha ricevuto il tuo ordine. Pagamento e ritiro in negozio.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.primary, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, color: palette.primary),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Codice ritiro',
                          style: TextStyle(
                              fontSize: 11, color: palette.textSecondary)),
                      Text(
                        pickupCode,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
                'Trovi il dettaglio nella tab Ordini.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cart già clear sopra
              Navigator.pop(context);
            },
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final SilvestrePalette palette;
  const _EmptyCart({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 80, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Il carrello è vuoto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Torna al catalogo e scegli i tuoi prodotti.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
