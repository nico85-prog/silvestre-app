import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../state/orders_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/order_overload.dart';
import 'operator_history_screen.dart';
import 'operator_order_detail_screen.dart';
import 'operator_promotion_screen.dart';
import 'operator_shipping_screen.dart';

class OperatorDashboard extends StatelessWidget {
  const OperatorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: Listenable.merge([ordersState, settingsState]),
      builder: (context, _) {
        final all = ordersState.orders;
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final today = all.where((o) =>
            o.createdAt.isAfter(startOfDay) && o.createdAt.isBefore(endOfDay));
        final lateHours = settingsState.settings.lateOrderHours;
        final lateThreshold = now.subtract(Duration(hours: lateHours));
        final late = all.where((o) =>
            o.status == OrderStatus.inProduction &&
            o.createdAt.isBefore(lateThreshold));
        final dailyLimit = settingsState.settings.dailyOrderLimit;
        final todayCount = today.length;
        final limitReached = todayCount >= dailyLimit;
        final overloadedIds = computeOverloadedOrderIds(all, dailyLimit);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Buongiorno',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            Text(
              _formatToday(now),
              style: TextStyle(color: palette.textSecondary),
            ),
            const SizedBox(height: 18),
            if (limitReached)
              _AlertBanner(
                color: palette.error,
                icon: Icons.block,
                title: 'Limite ordini giornalieri raggiunto',
                message:
                    'Hai $todayCount/$dailyLimit ordini oggi. Sospendi nuovi ordini o aumenta il limite in Impostazioni.',
              )
            else if (todayCount >= (dailyLimit * 0.8))
              _AlertBanner(
                color: palette.warning,
                icon: Icons.warning_amber_rounded,
                title: 'Capacità in esaurimento',
                message:
                    '$todayCount/$dailyLimit ordini oggi (≥80%). Stai per saturare la giornata.',
              ),
            if (late.isNotEmpty)
              _AlertBanner(
                color: palette.error,
                icon: Icons.alarm,
                title: '${late.length} ordini in ritardo',
                message:
                    'Ordini in lavorazione da oltre ${lateHours}h. Tocca "Ordini" per gestirli.',
              ),
            const SizedBox(height: 8),
            // Layout fisso 4+4+2 quando schermo abbastanza largo,
            // altrimenti collassa a 2 cols per mobile.
            LayoutBuilder(builder: (ctx, c) {
              final w = c.maxWidth;
              final wide = w >= 760; // 4 colonne possibili
              // Card ridotte: aspect ratio piu' alto = card piu' basse
              final ratio = wide ? 1.7 : 1.45;

              // Card per riga 1 (status workflow normale)
              final row1 = [
                _statusCard(context, OrderStatus.submitted, all,
                    overloadedIds),
                _statusCard(context, OrderStatus.inProduction, all,
                    overloadedIds),
                _statusCard(context, OrderStatus.readyForPickup, all,
                    overloadedIds),
                _statusCard(context, OrderStatus.pickedUp, all,
                    overloadedIds),
              ];
              // Card per riga 2 (status quote + spedizioni + promozione)
              final row2 = [
                _statusCard(context, OrderStatus.quoteRequested, all,
                    overloadedIds),
                _statusCard(context, OrderStatus.quoted, all,
                    overloadedIds),
                _shippingCard(context, all),
                _promoCard(context),
              ];
              // Card per riga 3 (cancelled + storico)
              final row3 = [
                _statusCard(context, OrderStatus.cancelled, all,
                    overloadedIds),
                _historyCard(context),
              ];

              Widget rowGrid(List<Widget> children, {int cols = 4}) =>
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: ratio,
                    children: children,
                  );

              if (wide) {
                return Column(
                  children: [
                    rowGrid(row1, cols: 4),
                    const SizedBox(height: 10),
                    rowGrid(row2, cols: 4),
                    const SizedBox(height: 10),
                    rowGrid(row3, cols: 4),
                  ],
                );
              }
              // Mobile: tutto in 2 colonne, ordine come da spec
              return rowGrid([...row1, ...row2, ...row3], cols: 2);
            }),
            const SizedBox(height: 24),
            Text('Ordini di oggi',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (today.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Center(
                  child: Text('Nessun ordine oggi.',
                      style: TextStyle(color: palette.textSecondary)),
                ),
              )
            else
              ...today.map((o) => _OrderRow(
                    order: o,
                    palette: palette,
                    overloaded: overloadedIds.contains(o.id),
                  )),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  static const _months = [
    'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
    'lug', 'ago', 'set', 'ott', 'nov', 'dic',
  ];

  String _formatToday(DateTime d) {
    const giorni = [
      'lunedì', 'martedì', 'mercoledì', 'giovedì',
      'venerdì', 'sabato', 'domenica',
    ];
    return '${giorni[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// Card stato ordine (Ricevuto, In lavorazione, ecc.)
  Widget _statusCard(BuildContext context, OrderStatus s,
      List<CustomerOrder> all, Set<String> overloadedIds) {
    return _StatCard(
      label: s.label,
      value: '${all.where((o) => o.status == s).length}',
      sub: _subFor(s),
      icon: s.icon,
      color: _colorFor(s),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OperatorHistoryScreen(initialFilter: s)),
      ),
    );
  }

  /// Card "Spedizioni" — conta ordini con deliveryMethod=shipping
  /// non ancora ritirati/cancellati.
  Widget _shippingCard(BuildContext context, List<CustomerOrder> all) {
    final n = all.where((o) =>
        o.deliveryMethod == DeliveryMethod.shipping &&
        o.status != OrderStatus.cancelled &&
        o.status != OrderStatus.pickedUp).length;
    return _StatCard(
      label: 'Spedizioni',
      value: '$n',
      sub: 'Ordini con spedizione a domicilio da preparare',
      icon: Icons.local_shipping,
      color: const Color(0xFF1976D2),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const OperatorShippingScreen()),
      ),
    );
  }

  Widget _promoCard(BuildContext context) {
    return _StatCard(
      label: 'Crea Promozione',
      value: '✉',
      sub: 'Invia offerte ai clienti opted-in via WhatsApp',
      icon: Icons.campaign,
      color: const Color(0xFFF47521),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const OperatorPromotionScreen()),
      ),
    );
  }

  Widget _historyCard(BuildContext context) {
    return _StatCard(
      label: 'Storico',
      value: '${ordersState.orders.length}',
      sub: 'Lista completa di tutti gli ordini con ricerca e filtri',
      icon: Icons.history,
      color: const Color(0xFF1976D2),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OperatorHistoryScreen()),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;
  const _AlertBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sub-testo descrittivo per ciascuno stato
String _subFor(OrderStatus s) => switch (s) {
      OrderStatus.quoteRequested =>
          'Richieste di lavoro personalizzato in attesa di preventivo',
      OrderStatus.quoted =>
          'Preventivi inviati, in attesa che il cliente accetti e paghi',
      OrderStatus.submitted =>
          'Ordini ricevuti, da avviare in lavorazione',
      OrderStatus.inProduction =>
          'Ordini in lavorazione',
      OrderStatus.readyForPickup =>
          'Ordini pronti da ritirare in negozio',
      OrderStatus.pickedUp =>
          'Ordini ritirati e completati',
      OrderStatus.cancelled =>
          'Ordini annullati',
    };

/// Colore dedicato per ciascuno stato
Color _colorFor(OrderStatus s) => switch (s) {
      OrderStatus.quoteRequested => const Color(0xFF9C27B0), // viola
      OrderStatus.quoted => const Color(0xFFEAB300), // giallo/ambra
      OrderStatus.submitted => const Color(0xFFF47521), // arancione Silvestre
      OrderStatus.inProduction => const Color(0xFFD32F2F), // rosso
      OrderStatus.readyForPickup => const Color(0xFF2E7D32), // verde
      OrderStatus.pickedUp => const Color(0xFF607D8B), // blu-grigio
      OrderStatus.cancelled => const Color(0xFF424242), // grigio scuro
    };

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                )),
            const SizedBox(height: 6),
            Expanded(
              child: Text(sub,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: palette.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  final bool overloaded;
  const _OrderRow({
    required this.order,
    required this.palette,
    this.overloaded = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status.colorOn(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: overloaded
                  ? palette.warning
                  : palette.border,
              width: overloaded ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(order.status.icon, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${order.pickupCode}  •  ${order.customerName ?? order.userId.substring(0, 6)}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (overloaded) ...[
                          const SizedBox(width: 6),
                          const _OverloadBadge(),
                        ],
                      ],
                    ),
                    Text(
                      '${order.itemCount} articoli • ${_time(order.createdAt)}',
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              Text('€ ${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  )),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}

class _OverloadBadge extends StatelessWidget {
  const _OverloadBadge();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.warning, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 12, color: palette.warning),
          const SizedBox(width: 3),
          Text(
            'standby order overload',
            style: TextStyle(
              color: palette.warning,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
