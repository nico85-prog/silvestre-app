import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

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
            _howToUse(context),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _howToUse(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: palette.primary),
              const SizedBox(width: 8),
              Text('Come si usa il pannello',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Vai nella tab "👥 Tutti": ogni contatto ha il badge del suo '
            'stato corrente. Accanto al nome trovi i bottoni di azione '
            'contestuali:\n\n'
            '• ⚪ Nuovo → "OPT IN" verde → apre WhatsApp col messaggio di '
            'richiesta consenso, il contatto passa a 🟡\n'
            '• 🟡 In attesa → ✅ SI / ❌ STOP → registri la risposta '
            'ricevuta su WhatsApp\n'
            '• 🟢 Acconsentito → nessuna azione (è già in lista marketing)\n'
            '• 🔴 Rifiutato → 🔄 reset (se ha senso) o 🔒 NO RESET (se ha '
            'detto STOP esplicito)\n\n'
            'Per inviare una PROMOZIONE STANDARD (sconto, novità) a tutti '
            'gli 🟢 Acconsentiti, usa il bottone verde "+ NUOVA '
            'PROMOZIONE" in alto a destra.',
            style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: palette.textPrimary),
          ),
        ],
      ),
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
