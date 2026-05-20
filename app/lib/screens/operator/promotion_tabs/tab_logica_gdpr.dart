import 'package:flutter/material.dart';
import '../../../state/auth_state.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../state/promotions_state.dart';
import '../../../theme/app_theme.dart';
import '../whatsapp_batch_screen.dart';

/// Tab 1 — Logica & Conformità GDPR.
/// Compliance-first: l'operatore atterra QUI per primo, vede le regole
/// del sistema e le statistiche live prima di creare promozioni.
class PromoTabLogicaGdpr extends StatelessWidget {
  final SilvestrePalette palette;
  const PromoTabLogicaGdpr({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: marketingContactsState,
      builder: (context, _) {
        if (marketingContactsState.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Errore: ${marketingContactsState.error}',
                style: TextStyle(color: palette.error),
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statsCard(context),
            const SizedBox(height: 18),
            _heading('Regole di dedup automatico'),
            const SizedBox(height: 8),
            _dedupTable(context),
            const SizedBox(height: 18),
            _heading('Regola d\'oro'),
            const SizedBox(height: 6),
            _golden(context),
            const SizedBox(height: 18),
            _heading('Cosa NON puo\' mai succedere'),
            const SizedBox(height: 6),
            _neverTable(context),
            const SizedBox(height: 18),
            _heading('Auto-cleanup giornaliero'),
            const SizedBox(height: 6),
            _autoCleanup(context),
            const SizedBox(height: 24),
            _softOptInCta(context),
            const SizedBox(height: 24),
            _inboxResponses(context),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _inboxResponses(BuildContext context) {
    final awaiting = marketingContactsState.contacts
        .where((c) => c.isAwaiting)
        .toList()
      ..sort((a, b) =>
          (b.optInSentAt ?? DateTime(2000))
              .compareTo(a.optInSentAt ?? DateTime(2000)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Inbox risposte soft opt-in (🟡 In attesa)'),
        const SizedBox(height: 6),
        Text(
          'Quando un cliente risponde "SI" o "STOP" su WhatsApp, '
          'trovalo qui sotto e premi il bottone corrispondente.',
          style: TextStyle(
              fontSize: 12,
              color: palette.textSecondary,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        if (awaiting.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: Center(
              child: Text('Nessun contatto in attesa di risposta.',
                  style: TextStyle(color: palette.textSecondary)),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: awaiting.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final c = awaiting[i];
                return _InboxRow(contact: c, palette: palette);
              },
            ),
          ),
      ],
    );
  }

  Widget _heading(String text) => Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: palette.primary),
      );

  Widget _statsCard(BuildContext context) {
    final s = marketingContactsState;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: palette.primary),
              const SizedBox(width: 8),
              Text('Statistiche live',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          _statRow('🟢 Acconsentiti (yes)', s.optedInCount),
          _statRow('⚪ Nuovi mai contattati', s.newCount),
          _statRow('🟡 In attesa risposta', s.awaitingCount),
          _statRow('🔴 Rifiutati / STOP / scaduti', s.rejectedCount),
          Divider(color: palette.border),
          _statRow('📦 Totale contatti gestiti', s.totalCount, bold: true),
        ],
      ),
    );
  }

  Widget _statRow(String label, int n, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: palette.textPrimary)),
          ),
          Text(
            '$n',
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: bold ? 16 : 14,
              fontWeight: FontWeight.w800,
              color: bold ? palette.primary : palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dedupTable(BuildContext context) {
    return Table(
      border: TableBorder.all(color: palette.border),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(2.5),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.1)),
          children: [
            _th('Categoria cliente'),
            _th('Soft opt-in?'),
            _th('Motivo'),
          ],
        ),
        _row('A — Solo rubrica, mai entrato in app',
            '✅ SÌ',
            'Mai chiesto consenso, soft opt-in è richiesta legittima'),
        _row('B — App con marketing=true',
            '❌ NO',
            'Già opted-in, e\' gia\' in lista marketing'),
        _row('C — App con marketing=false',
            '🚫 NO ASSOLUTO',
            'Ha esplicitamente rifiutato — GDPR vieta nuova richiesta'),
        _row('D — Rubrica + App con marketing=false',
            '❌ NO',
            'Vale la scelta esplicita più recente (in app)'),
      ],
    );
  }

  Widget _golden(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: palette.primary, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: palette.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La scelta esplicita del cliente in app vince SEMPRE sullo stato ereditato dalla rubrica.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: palette.primary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _neverTable(BuildContext context) {
    final items = [
      'Mandare promo a 🟡 In attesa o ⚪ Nuovo (Tab 3 li filtra)',
      'Mandare soft opt-in a chi ha rifiutato in app',
      'Riprovare soft opt-in dopo STOP del cliente',
      'Mandare soft opt-in due volte allo stesso 🟡 In attesa',
    ];
    return Column(
      children: items
          .map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.block, color: palette.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 13, color: palette.textPrimary)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _autoCleanup(BuildContext context) {
    return Text(
      'Cron job giornaliero alle 03:00: i contatti optInStatus=pending '
      'con optInSentAt > 30 giorni vengono marcati optInStatus=no '
      'definitivo. Nessuna azione manuale richiesta.',
      style: TextStyle(
          fontSize: 13,
          color: palette.textPrimary,
          height: 1.4,
          fontStyle: FontStyle.italic),
    );
  }

  Widget _softOptInCta(BuildContext context) {
    final s = marketingContactsState;
    final accent = palette.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: accent),
              const SizedBox(width: 8),
              Text('CAMPAGNA SOFT OPT-IN',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hai ${s.newCount} clienti ⚪ Nuovi da contattare per la '
            'richiesta di consenso.\n'
            'Pace consigliato: 50-100 messaggi/giorno (anti-spam WhatsApp).',
            style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: palette.textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.rocket_launch),
              label: const Text(
                'LANCIA / RIPRENDI CAMPAGNA SOFT OPT-IN',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: () => _launchSoftOptIn(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSoftOptIn(BuildContext context) async {
    final user = authState.currentUser;
    if (user == null) return;

    // Check campagna soft opt-in gia' in corso → resume
    final inProgress = promotionsState.promotions.where((p) =>
        p.channel == 'soft_optin' && p.status == 'in_progress').toList();
    if (inProgress.isNotEmpty) {
      final p = inProgress.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WhatsAppBatchScreen(promotionId: p.id),
        ),
      );
      return;
    }

    // Recipients: SOLO ⚪ Nuovi (mai contattati)
    final recipients = marketingContactsState.contacts
        .where((c) => c.isNew)
        .map((c) => c.id)
        .toList();
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessun cliente ⚪ Nuovo da contattare. Tutti i pending sono '
            'già stati contattati o hanno risposto.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lancia campagna soft opt-in'),
        content: Text(
          'Stai per iniziare la campagna di richiesta consenso a '
          '${recipients.length} clienti ⚪ Nuovi.\n\n'
          'Per ogni contatto:\n'
          '1. L\'app apre WhatsApp con messaggio FISSO precompilato\n'
          '2. Tu premi Invia su WhatsApp\n'
          '3. Torni in app e premi "Inviato, prossimo"\n\n'
          'Consigliato 50-100/giorno. Puoi sempre interrompere e '
          'riprendere il giorno dopo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO, INDIETRO'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.rocket_launch),
            label: const Text('SÌ, LANCIA'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      final id = await promotionsState.createSoftOptInCampaign(
        recipientIds: recipients,
        operatorUid: user.id,
      );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WhatsAppBatchScreen(promotionId: id),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: palette.primary)),
      );

  TableRow _row(String a, String b, String c) => TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(a,
                style:
                    TextStyle(fontSize: 12, color: palette.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(b,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(c,
                style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: palette.textSecondary)),
          ),
        ],
      );
}

class _InboxRow extends StatefulWidget {
  final MarketingContact contact;
  final SilvestrePalette palette;
  const _InboxRow({required this.contact, required this.palette});

  @override
  State<_InboxRow> createState() => _InboxRowState();
}

class _InboxRowState extends State<_InboxRow> {
  bool _busy = false;

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

  String _daysAgo(DateTime? d) {
    if (d == null) return '';
    final n = DateTime.now().difference(d).inDays;
    if (n == 0) return 'oggi';
    if (n == 1) return '1 gg fa';
    return '$n gg fa';
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final c = widget.contact;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          const Text('🟡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: palette.textPrimary)),
                Text(
                    '${c.phone} · inviato ${_daysAgo(c.optInSentAt)}',
                    style: TextStyle(
                        fontSize: 10,
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
              icon: const Icon(Icons.check_circle, size: 22),
              color: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _act(
                  () => marketingContactsState.markOptInYes(c.id)),
            ),
            IconButton(
              tooltip: 'STOP ricevuto',
              icon: const Icon(Icons.cancel, size: 22),
              color: palette.error,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _act(
                  () => marketingContactsState.markOptInNo(c.id)),
            ),
          ],
        ],
      ),
    );
  }
}
