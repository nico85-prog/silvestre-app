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

          // Stati speciali per richieste preventivo
          if (live.status == OrderStatus.quoteRequested) {
            return _CustomRequestWaiting(order: live, palette: palette);
          }
          if (live.status == OrderStatus.quoted) {
            return _QuoteDecision(order: live, palette: palette);
          }

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
              if (live.isCustomRequest) ...[
                const SizedBox(height: 20),
                _CustomRequestSummary(order: live, palette: palette),
              ],
              const SizedBox(height: 20),
              Text('Stato', style: _h2(palette)),
              const SizedBox(height: 10),
              _StatusTimeline(status: live.status, palette: palette),
              if (live.items.isNotEmpty) ...[
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
                              '\u20ac ${it.lineTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
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
                      '\u20ac ${live.total.toStringAsFixed(2)}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
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

class _CustomRequestSummary extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _CustomRequestSummary({required this.order, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high, color: palette.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Lavoro personalizzato',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (order.customRequestTitle != null)
            Text(
              order.customRequestTitle!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
                fontSize: 15,
              ),
            ),
          if (order.customRequestDescription != null) ...[
            const SizedBox(height: 4),
            Text(
              order.customRequestDescription!,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          if (order.quoteEta != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: palette.textSecondary),
                const SizedBox(width: 4),
                Text('Tempi: ${order.quoteEta}',
                    style: TextStyle(
                        color: palette.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomRequestWaiting extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _CustomRequestWaiting(
      {required this.order, required this.palette});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.hourglass_top, size: 56, color: palette.warning),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'In attesa di preventivo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Abbiamo ricevuto la tua richiesta. Il negozio ti risponder\u00e0 '
          'con un preventivo entro 24-48h lavorative.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 26),
        _CustomRequestSummary(order: order, palette: palette),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Annulla richiesta'),
          style: OutlinedButton.styleFrom(foregroundColor: palette.error),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Annullare la richiesta?'),
                content: const Text(
                    'Il negozio non potr\u00e0 pi\u00f9 risponderti col preventivo. Sicuro?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('S\u00ec, annulla'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await ordersState.declineQuote(order.id);
            }
          },
        ),
      ],
    );
  }
}

class _QuoteDecision extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _QuoteDecision({required this.order, required this.palette});

  Future<void> _accept(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accettare il preventivo?'),
        content: Text(
          'Confermi di accettare il preventivo di \u20ac ${order.quoteAmount?.toStringAsFixed(2)} '
          'con tempi di ${order.quoteEta}? Pagherai in negozio al ritiro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('S\u00ec, accetto'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ordersState.acceptQuote(order.id);
    }
  }

  Future<void> _decline(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rifiutare il preventivo?'),
        content: const Text(
            'La richiesta sar\u00e0 cancellata. Potrai sempre farne una nuova.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('S\u00ec, rifiuta'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ordersState.declineQuote(order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.request_quote, size: 56, color: palette.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Preventivo ricevuto',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.primary, palette.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Importo proposto',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '\u20ac ${order.quoteAmount?.toStringAsFixed(2) ?? "-"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tempi di consegna',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                order.quoteEta ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (order.quoteOperatorNote != null &&
            order.quoteOperatorNote!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sticky_note_2_outlined,
                    color: palette.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.quoteOperatorNote!,
                    style: TextStyle(color: palette.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        _CustomRequestSummary(order: order, palette: palette),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Accetto il preventivo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _accept(context),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Rifiuto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.error,
            side: BorderSide(color: palette.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _decline(context),
        ),
      ],
    );
  }
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
