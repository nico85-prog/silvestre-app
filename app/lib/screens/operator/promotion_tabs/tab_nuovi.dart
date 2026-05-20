import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Tab ⚪ Nuovi — clienti della rubrica storica mai contattati per il marketing.
/// Categoria A della tabella in Tab 1: candidati alla campagna soft opt-in.
class PromoTabNuovi extends StatefulWidget {
  final SilvestrePalette palette;
  const PromoTabNuovi({super.key, required this.palette});

  @override
  State<PromoTabNuovi> createState() => _PromoTabNuoviState();
}

class _PromoTabNuoviState extends State<PromoTabNuovi> {
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
            .where((c) => c.isNew)
            .toList();
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
                      child: Text(
                        _search.trim().isEmpty
                            ? 'Tutti i contatti sono già stati gestiti.'
                            : 'Nessun risultato per la ricerca.',
                        style: TextStyle(color: palette.textSecondary),
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
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fiber_new, color: Colors.grey, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚪ NUOVI ($n)',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      fontSize: 13,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Questa lista contiene i contatti della rubrica storica '
                  'che non hanno ancora ricevuto la richiesta di consenso '
                  'marketing (il "soft opt-in") e non sono mai entrati '
                  'nell\'app.\n\n'
                  'Sono i candidati naturali della campagna di soft '
                  'opt-in: dalla Tab 1 puoi lanciarla con il pulsante '
                  '"🚀 LANCIA CAMPAGNA SOFT OPT-IN".\n\n'
                  'Quando il messaggio viene inviato passano '
                  'automaticamente nella tab successiva "🟡 In attesa".',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          const Text('⚪', style: TextStyle(fontSize: 14)),
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
                Text(c.phone,
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
