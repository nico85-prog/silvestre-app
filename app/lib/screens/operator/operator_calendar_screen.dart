import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../state/orders_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_theme.dart';
import 'operator_order_detail_screen.dart';

class OperatorCalendarScreen extends StatelessWidget {
  const OperatorCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return AnimatedBuilder(
      animation: Listenable.merge([ordersState, settingsState]),
      builder: (context, _) {
        final dailyLimit = settingsState.settings.dailyOrderLimit;
        final byDay = <DateTime, List<CustomerOrder>>{};
        for (final o in ordersState.orders) {
          final d = DateTime(
              o.createdAt.year, o.createdAt.month, o.createdAt.day);
          byDay.putIfAbsent(d, () => []).add(o);
        }
        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day)
            .subtract(const Duration(days: 7));
        final end = DateTime(today.year, today.month, today.day)
            .add(const Duration(days: 14));

        final days = <DateTime>[];
        for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
          days.add(d);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LegendBar(palette: palette, dailyLimit: dailyLimit),
            const SizedBox(height: 16),
            ...days.map((d) {
              final list = byDay[d] ?? const <CustomerOrder>[];
              final count = list.length;
              final ratio = dailyLimit == 0 ? 0.0 : count / dailyLimit;
              final color = ratio >= 1
                  ? palette.error
                  : ratio >= 0.8
                      ? palette.warning
                      : palette.success;
              final isToday = _isSameDay(d, today);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday ? palette.primary : palette.border,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(d, isToday),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$count/$dailyLimit',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Nessun ordine',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: palette.textSecondary)),
                        ),
                      )
                    else
                      ...list.map((o) => InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      OperatorOrderDetailScreen(order: o)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                              child: Row(
                                children: [
                                  Icon(o.status.icon,
                                      color: o.status.colorOn(context),
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(o.pickupCode,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: palette.textPrimary)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      o.customerName ?? '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: palette.textSecondary),
                                    ),
                                  ),
                                  Text(
                                    '€ ${o.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d, bool isToday) {
    const days = [
      'lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom',
    ];
    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    final prefix = isToday ? 'OGGI · ' : '';
    return '$prefix${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }
}

class _LegendBar extends StatelessWidget {
  final SilvestrePalette palette;
  final int dailyLimit;
  const _LegendBar({required this.palette, required this.dailyLimit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: palette.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 14,
              children: [
                _legend(palette.success, '<80%'),
                _legend(palette.warning, '≥80%'),
                _legend(palette.error, 'saturo'),
                Text('Limite: $dailyLimit/giorno',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
