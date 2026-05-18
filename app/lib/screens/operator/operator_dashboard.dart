import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../state/operator_nav_state.dart';
import '../../state/orders_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_theme.dart';
import 'operator_order_detail_screen.dart';

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
        final weekAgo = startOfDay.subtract(const Duration(days: 6));

        final today = all.where((o) =>
            o.createdAt.isAfter(startOfDay) && o.createdAt.isBefore(endOfDay));
        final week = all.where((o) => o.createdAt.isAfter(weekAgo));
        final pending = all.where((o) =>
            o.status == OrderStatus.submitted ||
            o.status == OrderStatus.inProduction);
        final ready = all.where((o) => o.status == OrderStatus.readyForPickup);
        final lateHours = settingsState.settings.lateOrderHours;
        final lateThreshold = now.subtract(Duration(hours: lateHours));
        final late = all.where((o) =>
            o.status == OrderStatus.inProduction &&
            o.createdAt.isBefore(lateThreshold));
        final dailyLimit = settingsState.settings.dailyOrderLimit;
        final todayCount = today.length;
        final limitReached = todayCount >= dailyLimit;
        final weekRevenue = week.fold<double>(0, (s, o) => s + o.total);

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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  label: 'Ordini oggi',
                  value: '$todayCount',
                  sub: 'di $dailyLimit max',
                  icon: Icons.today,
                  color: palette.primary,
                  onTap: () => operatorNavState.goToOrders(todayOnly: true),
                ),
                _StatCard(
                  label: 'Da fare',
                  value: '${pending.length}',
                  sub: 'ricevuti + in lavorazione',
                  icon: Icons.pending_actions,
                  color: palette.warning,
                  onTap: () => operatorNavState.goToOrders(
                      filter: OrderStatus.submitted),
                ),
                _StatCard(
                  label: 'Da ritirare',
                  value: '${ready.length}',
                  sub: 'pronti in negozio',
                  icon: Icons.local_mall,
                  color: palette.success,
                  onTap: () => operatorNavState.goToOrders(
                      filter: OrderStatus.readyForPickup),
                ),
                _StatCard(
                  label: 'Ultimi 7 gg',
                  value: '€ ${weekRevenue.toStringAsFixed(0)}',
                  sub: '${week.length} ordini',
                  icon: Icons.trending_up,
                  color: palette.secondary,
                  onTap: () => operatorNavState.goToOrders(),
                ),
              ],
            ),
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
              ...today.map((o) => _OrderRow(order: o, palette: palette)),
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
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11, color: palette.textSecondary),
                ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(Icons.chevron_right,
                        size: 14, color: palette.textSecondary),
                  ),
              ],
            ),
            const Spacer(),
            Text(value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                )),
            Text(sub,
                style:
                    TextStyle(fontSize: 11, color: palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _OrderRow({required this.order, required this.palette});

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
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Icon(order.status.icon, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.pickupCode}  •  ${order.customerName ?? order.userId.substring(0, 6)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
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
