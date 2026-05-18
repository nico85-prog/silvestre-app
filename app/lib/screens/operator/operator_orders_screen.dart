import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../state/operator_nav_state.dart';
import '../../state/orders_state.dart';
import '../../theme/app_theme.dart';
import 'operator_order_detail_screen.dart';

class OperatorOrdersScreen extends StatefulWidget {
  const OperatorOrdersScreen({super.key});

  @override
  State<OperatorOrdersScreen> createState() => _OperatorOrdersScreenState();
}

class _OperatorOrdersScreenState extends State<OperatorOrdersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return AnimatedBuilder(
      animation: Listenable.merge([ordersState, operatorNavState]),
      builder: (context, _) {
        final filter = operatorNavState.ordersFilter;
        final todayOnly = operatorNavState.ordersTodayOnly;

        var orders = ordersState.orders;
        if (filter != null) {
          orders = orders.where((o) => o.status == filter).toList();
        }
        if (todayOnly) {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final end = start.add(const Duration(days: 1));
          orders = orders
              .where((o) =>
                  o.createdAt.isAfter(start) && o.createdAt.isBefore(end))
              .toList();
        }
        if (_search.trim().isNotEmpty) {
          final q = _search.trim().toLowerCase();
          orders = orders.where((o) {
            return o.pickupCode.toLowerCase().contains(q) ||
                (o.customerName ?? '').toLowerCase().contains(q) ||
                (o.customerPhone ?? '').contains(q);
          }).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cerca per codice, nome, telefono',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _FilterChip(
                    label: todayOnly ? 'Oggi' : 'Tutti',
                    selected: filter == null,
                    onTap: () => operatorNavState.clearFilter(),
                    color: palette.primary,
                  ),
                  for (final s in OrderStatus.values)
                    _FilterChip(
                      label: s.label,
                      selected: filter == s,
                      onTap: () =>
                          operatorNavState.goToOrders(filter: s),
                      color: s.colorOn(context),
                    ),
                ],
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun ordine corrisponde ai filtri.',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = orders[i];
                        return _OrderTile(order: o, palette: palette);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : palette.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _OrderTile({required this.order, required this.palette});

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status.colorOn(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OperatorOrderDetailScreen(order: order)),
      ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(order.status.icon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        order.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  order.pickupCode,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.customerName ?? '(senza nome)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            if (order.customerPhone != null)
              Text(order.customerPhone!,
                  style: TextStyle(
                      color: palette.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              order.items.map((i) => '${i.quantity}x ${i.productName}').join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatDateTime(order.createdAt),
                  style: TextStyle(
                      fontSize: 12, color: palette.textSecondary),
                ),
                const Spacer(),
                Text(
                  '€ ${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")} '
      '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}
