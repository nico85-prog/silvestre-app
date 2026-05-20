import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Tab 3 — Destinatari Promozione (SOLO 🟢 Acconsentiti).
/// I 🟡 In attesa, ⚪ Nuovi, 🔴 Rifiutati NON sono visibili qui by design:
/// impossibile includerli per errore in una promo standard.
class PromoTabDestinatari extends StatefulWidget {
  final SilvestrePalette palette;
  final Set<String> excludedIds;
  final ValueChanged<String> onExclude;
  final ValueChanged<String> onInclude;
  final ValueChanged<Iterable<String>> onExcludeAll;
  final ValueChanged<Iterable<String>> onIncludeAll;

  const PromoTabDestinatari({
    super.key,
    required this.palette,
    required this.excludedIds,
    required this.onExclude,
    required this.onInclude,
    required this.onExcludeAll,
    required this.onIncludeAll,
  });

  @override
  State<PromoTabDestinatari> createState() => _PromoTabDestinatariState();
}

class _PromoTabDestinatariState extends State<PromoTabDestinatari> {
  String _search = '';
  String _sourceFilter = 'all'; // 'all' | 'app' | 'csv'

  List<MarketingContact> _filtered() {
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
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.phone.contains(q)).toList();
    }
    return list;
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
        final list = _filtered();
        final allIds = list.map((c) => c.id).toSet();
        final includedCount =
            allIds.difference(widget.excludedIds).length;

        return Column(
          children: [
            _shieldBanner(palette),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text('INCLUDI TUTTI (${list.length})'),
                      onPressed: list.isEmpty
                          ? null
                          : () => widget.onIncludeAll(allIds),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.error,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('ESCLUDI TUTTI'),
                      onPressed: list.isEmpty
                          ? null
                          : () => widget.onExcludeAll(allIds),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group, size: 18, color: palette.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$includedCount inclusi / ${list.length} acconsentiti',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                          'Nessun cliente con consenso marketing attivo.',
                          style: TextStyle(color: palette.textSecondary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final c = list[i];
                        final excluded = widget.excludedIds.contains(c.id);
                        return _ContactRow(
                          contact: c,
                          excluded: excluded,
                          palette: palette,
                          onInclude: () => widget.onInclude(c.id),
                          onExclude: () => widget.onExclude(c.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _shieldBanner(SilvestrePalette palette) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E7D32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Questa lista contiene SOLO clienti con consenso marketing '
              'attivo. I 🟡 In attesa e ⚪ Nuovi sono gestiti dalla campagna '
              'soft opt-in (Tab 1).',
              style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: palette.textPrimary),
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
}

class _ContactRow extends StatelessWidget {
  final MarketingContact contact;
  final bool excluded;
  final SilvestrePalette palette;
  final VoidCallback onInclude;
  final VoidCallback onExclude;

  const _ContactRow({
    required this.contact,
    required this.excluded,
    required this.palette,
    required this.onInclude,
    required this.onExclude,
  });

  @override
  Widget build(BuildContext context) {
    final isFromCsv = contact.source.startsWith('csv');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: excluded
            ? palette.surface
            : const Color(0xFF2E7D32).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: excluded
                ? palette.border
                : const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            excluded
                ? Icons.check_box_outline_blank
                : Icons.check_box,
            color: excluded
                ? palette.textSecondary
                : const Color(0xFF2E7D32),
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(isFromCsv ? '📞' : '📱', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: palette.textPrimary),
                ),
                Text(
                  contact.phone,
                  style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                      fontFamily: 'Consolas'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, size: 20),
            color: const Color(0xFF2E7D32),
            tooltip: 'Includi',
            onPressed: excluded ? onInclude : null,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, size: 20),
            color: palette.error,
            tooltip: 'Escludi',
            onPressed: excluded ? null : onExclude,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
