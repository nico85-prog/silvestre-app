import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Tab 🟢 Acconsentiti — clienti che hanno dato il consenso marketing
/// (categoria B della tabella in Tab 1).
class PromoTabAcconsentiti extends StatefulWidget {
  final SilvestrePalette palette;
  const PromoTabAcconsentiti({super.key, required this.palette});

  @override
  State<PromoTabAcconsentiti> createState() =>
      _PromoTabAcconsentitiState();
}

class _PromoTabAcconsentitiState extends State<PromoTabAcconsentiti> {
  String _search = '';
  String _sourceFilter = 'all'; // 'all' | 'app' | 'csv'

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
            .where((c) => c.isOptedIn)
            .toList();
        if (_sourceFilter == 'csv') {
          list = list.where((c) => c.source.startsWith('csv')).toList();
        } else if (_sourceFilter == 'app') {
          list = list.where((c) => !c.source.startsWith('csv')).toList();
        }
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  _chip('Tutti', 'all', palette),
                  const SizedBox(width: 6),
                  _chip('📱 App', 'app', palette),
                  const SizedBox(width: 6),
                  _chip('📞 CSV', 'csv', palette),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        _search.trim().isEmpty
                            ? 'Nessun cliente con consenso marketing attivo.'
                            : 'Nessun risultato per la ricerca.',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
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
        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E7D32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user,
              color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🟢 ACCONSENTITI ($n)',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                      fontSize: 13,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Questa lista contiene i clienti che hanno dato il '
                  'consenso esplicito a ricevere promozioni marketing. '
                  'Possono essere:\n'
                  '• 📱 Utenti registrati nell\'app con la box marketing '
                  'spuntata, oppure\n'
                  '• 📞 Contatti del CSV che hanno risposto "SI" alla '
                  'campagna di soft opt-in.\n\n'
                  'Solo loro possono ricevere legalmente le promozioni '
                  'standard create dal pulsante "+" in basso a destra.',
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

  Widget _chip(String label, String value, SilvestrePalette palette) {
    final selected = _sourceFilter == value;
    return InkWell(
      onTap: () => setState(() => _sourceFilter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? palette.primary.withValues(alpha: 0.15)
              : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? palette.primary : palette.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? palette.primary
                    : palette.textSecondary)),
      ),
    );
  }

  Widget _row(SilvestrePalette palette, MarketingContact c) {
    final isFromCsv = c.source.startsWith('csv');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🟢', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(isFromCsv ? '📞' : '📱',
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
                if (c.email.isNotEmpty)
                  Text(c.email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: palette.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
