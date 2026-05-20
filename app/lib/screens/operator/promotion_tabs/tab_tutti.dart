import 'package:flutter/material.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Tab 👥 Tutti — vista d'insieme di tutti i contatti del sistema con
/// badge di stato e filtri rapidi. Utile per ricerca globale e audit.
class PromoTabTutti extends StatefulWidget {
  final SilvestrePalette palette;
  const PromoTabTutti({super.key, required this.palette});

  @override
  State<PromoTabTutti> createState() => _PromoTabTuttiState();
}

class _PromoTabTuttiState extends State<PromoTabTutti> {
  String _search = '';
  String _statusFilter = 'all'; // 'all' | 'yes' | 'new' | 'awaiting' | 'no'

  String _statusOf(MarketingContact c) {
    if (c.isOptedIn) return 'yes';
    if (c.isNew) return 'new';
    if (c.isAwaiting) return 'awaiting';
    if (c.isRejected) return 'no';
    return 'unknown';
  }

  String _emojiOf(String status) => switch (status) {
        'yes' => '🟢',
        'new' => '⚪',
        'awaiting' => '🟡',
        'no' => '🔴',
        _ => '⚫',
      };

  String _labelOf(String status) => switch (status) {
        'yes' => 'Acconsentito',
        'new' => 'Nuovo',
        'awaiting' => 'In attesa',
        'no' => 'Rifiutato',
        _ => '',
      };

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
        var list = marketingContactsState.contacts.toList();
        // Ordinamento naturale: per nome
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (_statusFilter != 'all') {
          list = list.where((c) => _statusOf(c) == _statusFilter).toList();
        }
        if (_search.trim().isNotEmpty) {
          final q = _search.trim().toLowerCase();
          list = list
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.phone.contains(q) ||
                  c.email.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            _explanationBanner(palette),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cerca per nome, telefono o email',
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Tutti', 'all', palette),
                    const SizedBox(width: 6),
                    _chip('🟢 Acconsentiti', 'yes', palette),
                    const SizedBox(width: 6),
                    _chip('⚪ Nuovi', 'new', palette),
                    const SizedBox(width: 6),
                    _chip('🟡 In attesa', 'awaiting', palette),
                    const SizedBox(width: 6),
                    _chip('🔴 Rifiutati', 'no', palette),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 18, color: palette.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${list.length} contatti'
                      '${_statusFilter == 'all' && _search.isEmpty ? ' totali' : ' trovati'}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nessun contatto corrisponde ai filtri.',
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

  Widget _explanationBanner(SilvestrePalette palette) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.people, color: palette.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👥 TUTTI I CONTATTI',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                      fontSize: 13,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vista d\'insieme di tutta la base contatti, '
                  'indipendentemente dallo stato. Usa la barra di ricerca '
                  'per trovare un cliente per nome, telefono o email; '
                  'usa i chip in alto per filtrare per stato. Le 4 tab '
                  'dedicate restano disponibili per la gestione '
                  'specifica di ciascuna categoria.',
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
    final selected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Color _bgColorOf(String status, SilvestrePalette palette) =>
      switch (status) {
        'yes' => const Color(0xFF2E7D32).withValues(alpha: 0.07),
        'new' => palette.surface,
        'awaiting' => palette.warning.withValues(alpha: 0.07),
        'no' => palette.error.withValues(alpha: 0.06),
        _ => palette.surface,
      };

  Color _borderColorOf(String status, SilvestrePalette palette) =>
      switch (status) {
        'yes' => const Color(0xFF2E7D32).withValues(alpha: 0.4),
        'new' => palette.border,
        'awaiting' => palette.warning.withValues(alpha: 0.5),
        'no' => palette.error.withValues(alpha: 0.4),
        _ => palette.border,
      };

  Color _statusColorOf(String status, SilvestrePalette palette) =>
      switch (status) {
        'yes' => const Color(0xFF2E7D32),
        'new' => palette.textSecondary,
        'awaiting' => palette.warning,
        'no' => palette.error,
        _ => palette.textSecondary,
      };

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _daysAgo(DateTime d) {
    final n = DateTime.now().difference(d).inDays;
    if (n == 0) return 'oggi';
    if (n == 1) return '1gg fa';
    return '${n}gg fa';
  }

  Widget _row(SilvestrePalette palette, MarketingContact c) {
    final status = _statusOf(c);
    final emoji = _emojiOf(status);
    final label = _labelOf(status);
    final isFromCsv = c.source.startsWith('csv');
    final statusColor = _statusColorOf(status, palette);

    // Costruisco eventuale info contestuale (data invio / rifiuto)
    String? contextInfo;
    if (status == 'awaiting' && c.optInSentAt != null) {
      contextInfo = 'soft opt-in inviato ${_daysAgo(c.optInSentAt!)}';
    } else if (status == 'no' && c.optInRepliedAt != null) {
      contextInfo = 'rifiutato il ${_fmtDate(c.optInRepliedAt!)}';
    } else if (status == 'yes' && c.optInRepliedAt != null) {
      contextInfo = 'acconsentito il ${_fmtDate(c.optInRepliedAt!)}';
    } else if (status == 'new') {
      contextInfo = 'mai contattato';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _bgColorOf(status, palette),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColorOf(status, palette)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(isFromCsv ? '📞' : '📱',
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(c.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: palette.textPrimary)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(label.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
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
                if (contextInfo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(contextInfo,
                        style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
