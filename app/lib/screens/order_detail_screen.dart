import 'package:flutter/material.dart';
import '../models/order.dart';
import '../state/orders_state.dart';
import '../theme/app_theme.dart';

class OrderDetailScreen extends StatelessWidget {
  final CustomerOrder order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Ordine ${order.id.substring(4)}')),
      body: AnimatedBuilder(
        animation: ordersState,
        builder: (context, _) {
          final live = ordersState.orders.firstWhere(
            (o) => o.id == order.id,
            orElse: () => order,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 56, color: Colors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Codice di ritiro',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              )),
                          Text(
                            live.pickupCode,
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mostralo in negozio per ritirare',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Stato', style: _h2(palette)),
              const SizedBox(height: 10),
              _StatusTimeline(status: live.status, palette: palette),
              const SizedBox(height: 24),
              Text('Articoli (${live.itemCount})', style: _h2(palette)),
              const SizedBox(height: 10),
              ...live.items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.productName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    )),
                                Text(it.variantName,
                                    style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(
                            'x${it.quantity}',
                            style: TextStyle(color: palette.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '€ ${it.lineTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Text('Totale da pagare in negozio',
                        style: TextStyle(color: palette.textSecondary)),
                    const Spacer(),
                    Text(
                      '€ ${live.total.toStringAsFixed(2)}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (live.status == OrderStatus.submitted ||
                  live.status == OrderStatus.inProduction)
                OutlinedButton.icon(
                  icon: const Icon(Icons.science_outlined),
                  label: Text(live.status == OrderStatus.submitted
                      ? 'Simula: in lavorazione'
                      : 'Simula: pronto per il ritiro'),
                  onPressed: () {
                    final next = live.status == OrderStatus.submitted
                        ? OrderStatus.inProduction
                        : OrderStatus.readyForPickup;
                    ordersState.updateStatus(live.id, next);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  TextStyle _h2(SilvestrePalette p) => TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: p.textPrimary,
      );
}

class _StatusTimeline extends StatelessWidget {
  final OrderStatus status;
  final SilvestrePalette palette;
  const _StatusTimeline({required this.status, required this.palette});

  @override
  Widget build(BuildContext context) {
    const steps = [
      OrderStatus.submitted,
      OrderStatus.inProduction,
      OrderStatus.readyForPickup,
      OrderStatus.pickedUp,
    ];
    final currentIdx = steps.indexOf(status);

    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        final isDone = i <= currentIdx;
        final isCurrent = i == currentIdx;
        final color = isDone ? s.colorOn(context) : palette.border;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? color.withValues(alpha: 0.15)
                        : palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(s.icon, size: 14, color: color),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isDone ? color : palette.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.label,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isDone ? palette.textPrimary : palette.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
