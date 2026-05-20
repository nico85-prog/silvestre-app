import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Tab 🔴 Rifiutati — clienti che hanno detto STOP, hanno deselezionato
/// il marketing in app, oppure non hanno risposto al soft opt-in entro
/// 30 giorni. Sono in lista solo per audit GDPR: non riceveranno mai più
/// nessuna comunicazione marketing.
class PromoTabRifiutati extends StatefulWidget {
  final SilvestrePalette palette;
  const PromoTabRifiutati({super.key, required this.palette});

  @override
  State<PromoTabRifiutati> createState() => _PromoTabRifiutatiState();
}

class _PromoTabRifiutatiState extends State<PromoTabRifiutati> {
  String _search = '';

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
            .where((c) => c.isRejected)
            .toList()
          ..sort((a, b) => (b.optInRepliedAt ?? DateTime(2000))
              .compareTo(a.optInRepliedAt ?? DateTime(2000)));
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
                              ? 'Nessun contatto rifiutato.'
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
                          _row(palette, list[i]),
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
        color: palette.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.error, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block, color: palette.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔴 RIFIUTATI ($n)',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.error,
                      fontSize: 13,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Questa lista contiene i clienti che NON devono mai '
                  'ricevere comunicazioni marketing. Sono finiti qui '
                  'per uno di questi motivi:\n'
                  '• Hanno risposto "STOP" al messaggio di soft opt-in\n'
                  '• Si sono registrati nell\'app senza spuntare il '
                  'consenso marketing\n'
                  '• Hanno disattivato il marketing dalle Impostazioni '
                  'account\n'
                  '• Non hanno risposto al soft opt-in entro 30 giorni '
                  '(scadenza automatica)\n\n'
                  'La presenza di questa lista è importante per '
                  'dimostrare al Garante Privacy, in caso di verifica, '
                  'che il sistema rispetta le scelte di rifiuto dei '
                  'clienti. Sono in sola lettura: per costruzione il '
                  'pannello non permette di reinserirli in nessuna '
                  'campagna marketing.',
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

  Widget _row(SilvestrePalette palette, MarketingContact c) {
    final isFromCsv = c.source.startsWith('csv');
    final when = c.optInRepliedAt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          const Text('🔴', style: TextStyle(fontSize: 14)),
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
                    c.phone +
                        (when != null
                            ? ' · rifiutato il ${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year}'
                            : ''),
                    style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontFamily: 'Consolas')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
