import 'package:flutter/material.dart';
import '../models/order.dart';
import '../state/auth_state.dart';
import '../state/orders_state.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return AnimatedBuilder(
      animation: ordersState,
      builder: (context, _) {
        final user = authState.currentUser;
        final orders =
            user == null ? <CustomerOrder>[] : ordersState.forUser(user.id);

        if (orders.isEmpty) {
          return _EmptyOrders(palette: palette);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final o = orders[i];
            return _OrderCard(order: o, palette: palette);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _OrderCard({required this.order, required this.palette});

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status.colorOn(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
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
                Icon(order.status.icon, color: statusColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  order.status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${order.itemCount} ${order.itemCount == 1 ? "articolo" : "articoli"} • Codice ${order.pickupCode}',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.items.map((i) => i.productName).join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Totale  ',
                  style: TextStyle(
                      color: palette.textSecondary, fontSize: 13),
                ),
                Text(
                  '€ ${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: palette.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}';
}

class _EmptyOrders extends StatelessWidget {
  final SilvestrePalette palette;
  const _EmptyOrders({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Nessun ordine ancora',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'I tuoi ordini appariranno qui dopo il primo acquisto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
