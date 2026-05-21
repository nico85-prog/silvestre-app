import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order.dart';
import '../../state/orders_state.dart';
import '../../theme/app_theme.dart';
import 'operator_order_detail_screen.dart';

/// Pannello operatore "Spedizioni": lista degli ordini che richiedono
/// spedizione (deliveryMethod=shipping) e sono pagati (cosi' l'operatore
/// puo' procedere a stampare l'etichetta e spedire).
///
/// Criteri lista:
///   - deliveryMethod == shipping
///   - payment.paidNow == true OR (bonifico verified == true)
///   - status in [submitted, inProduction, readyForPickup]
///     (escludo pickedUp che per pickup-shipping significherebbe "spedito",
///      e cancelled)
///
/// Per ogni riga: indirizzo formattato copiabile (tap "Copia indirizzo")
/// + tap su riga apre il dettaglio ordine completo.
class OperatorShippingScreen extends StatelessWidget {
  const OperatorShippingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Spedizioni')),
      body: AnimatedBuilder(
        animation: ordersState,
        builder: (context, _) {
          final all = ordersState.orders;
          final toShip = all.where((o) {
            if (o.deliveryMethod != DeliveryMethod.shipping) return false;
            if (o.status == OrderStatus.cancelled) return false;
            if (o.status == OrderStatus.pickedUp) return false;
            final paid = (o.payment?['paidNow'] as bool?) ?? false;
            final verified = (o.payment?['verified'] as bool?) ?? false;
            return paid || verified;
          }).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          // ordini di shipping non ancora pagati (operator si accorga
          // che ci sono ordini "fermi" in attesa di verifica pagamento)
          final pendingPayment = all.where((o) {
            if (o.deliveryMethod != DeliveryMethod.shipping) return false;
            if (o.status == OrderStatus.cancelled) return false;
            if (o.status == OrderStatus.pickedUp) return false;
            final paid = (o.payment?['paidNow'] as bool?) ?? false;
            final verified = (o.payment?['verified'] as bool?) ?? false;
            return !(paid || verified);
          }).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (toShip.isEmpty && pendingPayment.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 64, color: palette.textSecondary),
                        const SizedBox(height: 12),
                        Text('Nessun ordine da spedire al momento.',
                            style:
                                TextStyle(color: palette.textSecondary)),
                      ],
                    ),
                  ),
                ),
              if (toShip.isNotEmpty) ...[
                _SectionHeader(
                    title: 'DA SPEDIRE',
                    count: toShip.length,
                    color: palette.primary,
                    palette: palette),
                const SizedBox(height: 8),
                ...toShip.map((o) =>
                    _ShippingRow(order: o, palette: palette, paid: true)),
              ],
              if (pendingPayment.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SectionHeader(
                    title: 'IN ATTESA DI PAGAMENTO',
                    count: pendingPayment.length,
                    color: palette.warning,
                    palette: palette),
                const SizedBox(height: 4),
                Text(
                  'Spediscili SOLO dopo aver verificato il bonifico sul conto '
                  '(per gli ordini bonifico) o dopo che la transazione carta/'
                  'Satispay è risultata OK.',
                  style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                ...pendingPayment.map((o) =>
                    _ShippingRow(order: o, palette: palette, paid: false)),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final SilvestrePalette palette;
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.local_shipping, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _ShippingRow extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  final bool paid;
  const _ShippingRow({
    required this.order,
    required this.palette,
    required this.paid,
  });

  String get _formattedAddress {
    final a = order.shippingAddress;
    if (a == null) return '(indirizzo mancante)';
    final notes = (a.notes ?? '').isEmpty ? '' : '\n${a.notes}';
    return '${a.fullName}\n${a.phone}\n${a.street} ${a.streetNumber}\n'
        '${a.zipCode} ${a.city} (${a.province})$notes';
  }

  @override
  Widget build(BuildContext context) {
    final addr = order.shippingAddress;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OperatorOrderDetailScreen(order: order)),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: paid
                ? palette.primary.withValues(alpha: 0.06)
                : palette.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: paid ? palette.primary : palette.warning,
                width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(order.pickupCode,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.6)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: order.status.colorOn(context)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status.label.toUpperCase(),
                      style: TextStyle(
                        color: order.status.colorOn(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('€ ${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.primary)),
                ],
              ),
              const SizedBox(height: 8),
              if (addr != null) ...[
                Text(addr.fullName,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        fontSize: 15)),
                Text(addr.phone,
                    style: TextStyle(
                        color: palette.textSecondary,
                        fontFamily: 'Consolas',
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text('${addr.street} ${addr.streetNumber}',
                    style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('${addr.zipCode} ${addr.city} (${addr.province})',
                    style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                if ((addr.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Note: ${addr.notes}',
                      style: TextStyle(
                          fontSize: 12,
                          color: palette.textSecondary,
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.content_copy, size: 16),
                      label: const Text('Copia indirizzo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _formattedAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Indirizzo copiato'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                        'creato ${_fmtDate(order.createdAt)}',
                        style: TextStyle(
                            fontSize: 11, color: palette.textSecondary)),
                  ],
                ),
              ] else
                Text(
                  'Indirizzo spedizione mancante',
                  style: TextStyle(
                      color: palette.error,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
