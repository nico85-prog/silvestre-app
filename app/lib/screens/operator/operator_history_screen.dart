import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../state/orders_state.dart';
import '../../theme/app_theme.dart';
import 'operator_order_detail_screen.dart';

/// Storico completo di TUTTI gli ordini (passati e correnti),
/// sortato per data decrescente. Filtra per stato + cerca codice/nome/tel.
class OperatorHistoryScreen extends StatefulWidget {
  /// Filtro stato iniziale (es. quando aperto da una card della dashboard).
  final OrderStatus? initialFilter;
  final bool initialTodayOnly;

  const OperatorHistoryScreen({
    super.key,
    this.initialFilter,
    this.initialTodayOnly = false,
  });

  @override
  State<OperatorHistoryScreen> createState() => _OperatorHistoryScreenState();
}

class _OperatorHistoryScreenState extends State<OperatorHistoryScreen> {
  String _search = '';
  OrderStatus? _filterStatus;
  DateTime? _from;
  DateTime? _to;
  late final bool _todayOnly = widget.initialTodayOnly;

  @override
  void initState() {
    super.initState();
    _filterStatus = widget.initialFilter;
  }

  Future<void> _pickFromDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickToDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _to = d);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Storico ordini')),
      body: AnimatedBuilder(
      animation: ordersState,
      builder: (context, _) {
        final effectiveFilter = _filterStatus;

        // Ordini tutti, sortati per data decrescente
        var orders = List<CustomerOrder>.from(ordersState.orders);
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Filtri
        if (effectiveFilter != null) {
          orders =
              orders.where((o) => o.status == effectiveFilter).toList();
        }
        if (_todayOnly) {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final end = start.add(const Duration(days: 1));
          orders = orders
              .where((o) =>
                  o.createdAt.isAfter(start) &&
                  o.createdAt.isBefore(end))
              .toList();
        }
        if (_from != null) {
          final start = DateTime(_from!.year, _from!.month, _from!.day);
          orders = orders.where((o) => !o.createdAt.isBefore(start)).toList();
        }
        if (_to != null) {
          final end = DateTime(_to!.year, _to!.month, _to!.day)
              .add(const Duration(days: 1));
          orders = orders.where((o) => o.createdAt.isBefore(end)).toList();
        }
        if (_search.trim().isNotEmpty) {
          final q = _search.trim().toLowerCase();
          orders = orders.where((o) {
            return o.pickupCode.toLowerCase().contains(q) ||
                (o.customerName ?? '').toLowerCase().contains(q) ||
                (o.customerPhone ?? '').contains(q);
          }).toList();
        }

        // Totale ricavi del subset filtrato (esclude annullati)
        final totalRevenue = orders
            .where((o) => o.status != OrderStatus.cancelled)
            .fold<double>(0, (sum, o) => sum + o.total);

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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(_from == null
                          ? 'Da: tutte'
                          : 'Da: ${_fmtDate(_from!)}'),
                      onPressed: _pickFromDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(_to == null
                          ? 'A: oggi'
                          : 'A: ${_fmtDate(_to!)}'),
                      onPressed: _pickToDate,
                    ),
                  ),
                  if (_from != null || _to != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Pulisci date',
                      onPressed: () =>
                          setState(() { _from = null; _to = null; }),
                    ),
                ],
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
                    label: 'Tutti',
                    selected: effectiveFilter == null,
                    onTap: () => setState(() => _filterStatus = null),
                    color: palette.primary,
                  ),
                  for (final s in OrderStatus.values)
                    _FilterChip(
                      label: s.label,
                      selected: effectiveFilter == s,
                      onTap: () => setState(() => _filterStatus = s),
                      color: s.colorOn(context),
                    ),
                ],
              ),
            ),
            // Header riepilogo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: palette.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: palette.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${orders.length} ordini trovati',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary),
                      ),
                    ),
                    Text(
                      '€ ${totalRevenue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Text('Nessun ordine.',
                          style: TextStyle(color: palette.textSecondary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _HistoryTile(order: orders[i], palette: palette),
                    ),
            ),
          ],
        );
      },
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.5),
                width: selected ? 2 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _HistoryTile({required this.order, required this.palette});

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status.colorOn(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OperatorOrderDetailScreen(order: order)),
      ),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.pickupCode,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.label,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.customerName ?? '(senza nome)',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_fmtDate(order.createdAt)} · ${order.items.length} item',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '€ ${order.total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
