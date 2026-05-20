import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Tab 4 — Contatti Esclusi (re-include).
/// Lista dei contatti che l'operatore ha escluso manualmente da questa
/// campagna. Solo 🟢 Acconsentiti possono comparire (per costruzione
/// non si può escludere chi non era già in Tab 3).
class PromoTabEsclusi extends StatefulWidget {
  final SilvestrePalette palette;
  final Set<String> excludedIds;
  final ValueChanged<String> onReinclude;

  const PromoTabEsclusi({
    super.key,
    required this.palette,
    required this.excludedIds,
    required this.onReinclude,
  });

  @override
  State<PromoTabEsclusi> createState() => _PromoTabEsclusiState();
}

class _PromoTabEsclusiState extends State<PromoTabEsclusi> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: marketingContactsState,
      builder: (context, _) {
        final palette = widget.palette;
        var excluded = marketingContactsState.contacts
            .where((c) => widget.excludedIds.contains(c.id))
            .toList();
        if (_search.trim().isNotEmpty) {
          final q = _search.trim().toLowerCase();
          excluded = excluded
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.phone.contains(q))
              .toList();
        }

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.warning),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block,
                      color: palette.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contatti che hai escluso manualmente da QUESTA '
                      'campagna. Premi RE-INCLUDI per rimetterli in Tab 3. '
                      'I 🔴 rifiutati (STOP) non compaiono qui — sono '
                      'esclusi a sistema.',
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  '${excluded.length} contatti esclusi',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: excluded.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _search.trim().isEmpty
                              ? 'Nessun contatto escluso da questa campagna.'
                              : 'Nessun risultato per la ricerca.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: excluded.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final c = excluded[i];
                        final isFromCsv = c.source.startsWith('csv');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            children: [
                              Text(isFromCsv ? '📞' : '📱',
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.check_circle,
                                    size: 16),
                                label: const Text(
                                  'RE-INCLUDI',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                ),
                                onPressed: () => widget.onReinclude(c.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
