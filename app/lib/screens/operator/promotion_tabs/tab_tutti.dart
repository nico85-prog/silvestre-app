import 'package:flutter/material.dart';
import '../../../services/messaging_service.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../theme/app_theme.dart';

/// Template fisso del messaggio soft opt-in.
String _buildSoftOptInMessage(String fullName) {
  final firstName = fullName.split(' ').first;
  return 'Ciao $firstName, ti scriviamo da Silvestre Fotoservizi 📸. '
      'Hai usato i nostri servizi in passato e vorremmo restare in '
      'contatto via WhatsApp con sconti riservati e novità.\n\n'
      'Rispondi SI per iscriverti, oppure ignora questo messaggio '
      'per uscire dalla lista.\n\n'
      'In qualunque momento puoi disiscriverti rispondendo STOP.';
}

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
                      '${_search.isEmpty ? ' totali' : ' trovati'}',
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
                  'per trovare un cliente per nome, telefono o email. '
                  'Per gestire una categoria specifica usa le tab dedicate '
                  '(🟢 Acconsentiti, ⚪ Nuovi, 🟡 In attesa, 🔴 Rifiutati).',
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

  Widget _row(SilvestrePalette palette, MarketingContact c) {
    final status = _statusOf(c);
    return _ContactActionRow(
      contact: c,
      palette: palette,
      status: status,
      emoji: _emojiOf(status),
      label: _labelOf(status),
      bgColor: _bgColorOf(status, palette),
      borderColor: _borderColorOf(status, palette),
      statusColor: _statusColorOf(status, palette),
    );
  }
}

/// Riga con badge stato + bottoni di azione contestuali allo stato.
class _ContactActionRow extends StatefulWidget {
  final MarketingContact contact;
  final SilvestrePalette palette;
  final String status;
  final String emoji;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color statusColor;

  const _ContactActionRow({
    required this.contact,
    required this.palette,
    required this.status,
    required this.emoji,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.statusColor,
  });

  @override
  State<_ContactActionRow> createState() => _ContactActionRowState();
}

class _ContactActionRowState extends State<_ContactActionRow> {
  bool _busy = false;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _daysAgo(DateTime d) {
    final n = DateTime.now().difference(d).inDays;
    if (n == 0) return 'oggi';
    if (n == 1) return '1gg fa';
    return '${n}gg fa';
  }

  /// Click "OPT IN": apre WhatsApp col template + marca optInSent.
  Future<void> _optIn() async {
    setState(() => _busy = true);
    final c = widget.contact;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MessagingService.sendWhatsApp(
        phone: c.phone,
        message: _buildSoftOptInMessage(c.name),
      );
      await marketingContactsState.markOptInSent(c.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markYes() async {
    setState(() => _busy = true);
    try {
      await marketingContactsState.markOptInYes(widget.contact.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askReasonAndReject() async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Marca ${widget.contact.name} come Rifiutato'),
        content: const Text(
          'Indica il motivo. Questo determina se il contatto sara\' '
          'resettabile in futuro.',
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
            child: const Text('NO generico (riprovabile)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, RejectionReason.stop),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.palette.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP esplicito'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await marketingContactsState.markOptInNo(widget.contact.id,
          reason: reason);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: widget.palette.error, size: 32),
        title: const Text('⚠ Reset GDPR'),
        content: Text(
          'Riportare ${widget.contact.name} da 🔴 Rifiutato a ⚪ Nuovo? '
          'Procedi solo se il rifiuto era per scadenza 30gg senza '
          'risposta, NON per uno STOP esplicito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.palette.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Riporta in ⚪ Nuovi'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await marketingContactsState.resetToNuovo(widget.contact.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _actions() {
    if (_busy) {
      return const SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    switch (widget.status) {
      case 'new':
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.chat, size: 14),
          onPressed: _optIn,
          label: const Text('OPT IN',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800)),
        );
      case 'awaiting':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'SI ricevuto',
              icon: const Icon(Icons.check_circle, size: 22),
              color: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _markYes,
            ),
            IconButton(
              tooltip: 'STOP / NO',
              icon: const Icon(Icons.cancel, size: 22),
              color: widget.palette.error,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _askReasonAndReject,
            ),
          ],
        );
      case 'no':
        if (RejectionReason.isResettable(widget.contact.rejectionReason)) {
          return IconButton(
            tooltip: 'Riporta in ⚪ Nuovi',
            icon: const Icon(Icons.restart_alt, size: 22),
            color: widget.palette.warning,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _confirmReset,
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: widget.palette.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: widget.palette.error),
          ),
          child: Tooltip(
            message:
                'Reset non autorizzato dal cliente (vincolo GDPR)',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 11, color: widget.palette.error),
                const SizedBox(width: 2),
                Text('NO RESET',
                    style: TextStyle(
                        color: widget.palette.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 8.5,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
        );
      default:
        // 🟢 yes → no action
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    final isFromCsv = c.source.startsWith('csv');
    String? contextInfo;
    if (widget.status == 'awaiting' && c.optInSentAt != null) {
      contextInfo = 'soft opt-in inviato ${_daysAgo(c.optInSentAt!)}';
    } else if (widget.status == 'no' && c.optInRepliedAt != null) {
      contextInfo =
          'rifiutato il ${_fmtDate(c.optInRepliedAt!)} · '
          '${RejectionReason.label(c.rejectionReason)}';
    } else if (widget.status == 'yes' && c.optInRepliedAt != null) {
      contextInfo = 'acconsentito il ${_fmtDate(c.optInRepliedAt!)}';
    } else if (widget.status == 'new') {
      contextInfo = 'mai contattato';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.borderColor),
      ),
      child: Row(
        children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(isFromCsv ? '📇' : '📱',
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
                              color: widget.palette.textPrimary)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: widget.statusColor
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(widget.label.toUpperCase(),
                          style: TextStyle(
                              color: widget.statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                Text(c.phone,
                    style: TextStyle(
                        fontSize: 11,
                        color: widget.palette.textSecondary,
                        fontFamily: 'Consolas')),
                if (c.email.isNotEmpty)
                  Text(c.email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.palette.textSecondary)),
                if (contextInfo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(contextInfo,
                        style: TextStyle(
                            fontSize: 10,
                            color: widget.statusColor,
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actions(),
        ],
      ),
    );
  }
}
