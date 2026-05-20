import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Tab 🟡 In attesa — clienti a cui è stato inviato il soft opt-in ma
/// non hanno ancora risposto. L'operatore segna manualmente SI/STOP
/// quando li vede sulle proprie risposte WhatsApp Business.
class PromoTabInAttesa extends StatefulWidget {
  final SilvestrePalette palette;
  const PromoTabInAttesa({super.key, required this.palette});

  @override
  State<PromoTabInAttesa> createState() => _PromoTabInAttesaState();
}

class _PromoTabInAttesaState extends State<PromoTabInAttesa> {
  String _search = '';

  String _daysAgo(DateTime? d) {
    if (d == null) return '';
    final n = DateTime.now().difference(d).inDays;
    if (n == 0) return 'oggi';
    if (n == 1) return '1 giorno fa';
    return '$n giorni fa';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: marketingContactsState,
      builder: (context, _) {
        if (marketingContactsState.loading &&
            marketingContactsState.contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final palette = widget.palette;
        var list = marketingContactsState.contacts
            .where((c) => c.isAwaiting)
            .toList()
          ..sort((a, b) =>
              (b.optInSentAt ?? DateTime(2000))
                  .compareTo(a.optInSentAt ?? DateTime(2000)));
        if (_search.trim().isNotEmpty) {
          final q = _search.trim().toLowerCase();
          list = list
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.phone.contains(q))
              .toList();
        }

        return Column(
          children: [
            _explanationBanner(palette, list.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cerca per nome o telefono',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _search.trim().isEmpty
                              ? 'Nessun contatto in attesa di risposta.'
                              : 'Nessun risultato per la ricerca.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, i) =>
                          _InAttesaRow(
                              contact: list[i], palette: palette,
                              daysAgo: _daysAgo(list[i].optInSentAt)),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _explanationBanner(SilvestrePalette palette, int n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.warning, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top, color: palette.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🟡 IN ATTESA ($n)',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.warning,
                      fontSize: 13,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Questa lista contiene i clienti a cui hai già inviato '
                  'la richiesta di consenso marketing (soft opt-in) ma '
                  'che non hanno ancora risposto.\n\n'
                  'Quando vedi su WhatsApp Business che hanno risposto:\n'
                  '• ✅ "SI" → cliccalo qui e il cliente passa in '
                  '"🟢 Acconsentiti"\n'
                  '• ❌ "STOP" → cliccalo qui e il cliente passa in '
                  '"🔴 Rifiutati"\n\n'
                  'Dopo 30 giorni senza risposta, il sistema sposterà '
                  'automaticamente il contatto in "🔴 Rifiutati" '
                  '(quando attiveremo il cron job).',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: palette.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InAttesaRow extends StatefulWidget {
  final MarketingContact contact;
  final SilvestrePalette palette;
  final String daysAgo;
  const _InAttesaRow({
    required this.contact,
    required this.palette,
    required this.daysAgo,
  });

  @override
  State<_InAttesaRow> createState() => _InAttesaRowState();
}

class _InAttesaRowState extends State<_InAttesaRow> {
  bool _busy = false;

  Future<void> _askReasonAndReject(
      BuildContext context, MarketingContact c) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Marca ${c.name} come Rifiutato'),
        content: const Text(
          'Indica il motivo per cui il cliente finisce in 🔴 Rifiutati. '
          'Questo determina se sarà possibile riprovare in futuro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, RejectionReason.manualOperator),
            style: TextButton.styleFrom(
                foregroundColor: widget.palette.warning),
            child: const Text('NO generico (riprovabile dopo)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, RejectionReason.stop),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.palette.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP esplicito (mai più)'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await marketingContactsState.markOptInNo(c.id, reason: reason);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final c = widget.contact;
    final isFromCsv = c.source.startsWith('csv');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🟡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(isFromCsv ? '📇' : '📱',
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: palette.textPrimary)),
                Text(
                    '${c.phone} · inviato ${widget.daysAgo}',
                    style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontFamily: 'Consolas')),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              tooltip: 'SI ricevuto',
              icon: const Icon(Icons.check_circle, size: 24),
              color: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _act(
                  () => marketingContactsState.markOptInYes(c.id)),
            ),
            IconButton(
              tooltip: 'STOP / NO ricevuto',
              icon: const Icon(Icons.cancel, size: 24),
              color: palette.error,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _askReasonAndReject(context, c),
            ),
            IconButton(
              tooltip: 'Riporta in ⚪ Nuovi (per riprovare soft opt-in)',
              icon: const Icon(Icons.restart_alt, size: 22),
              color: palette.textSecondary,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _act(
                  () => marketingContactsState.resetToNuovo(c.id)),
            ),
          ],
        ],
      ),
    );
  }
}
