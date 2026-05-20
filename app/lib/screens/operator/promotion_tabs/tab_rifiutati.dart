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
    return _RejectedRow(contact: c, palette: palette);
  }
}

class _RejectedRow extends StatefulWidget {
  final MarketingContact contact;
  final SilvestrePalette palette;
  const _RejectedRow({required this.contact, required this.palette});

  @override
  State<_RejectedRow> createState() => _RejectedRowState();
}

class _RejectedRowState extends State<_RejectedRow> {
  bool _busy = false;

  String _elapsedFrom(DateTime? d) {
    if (d == null) return 'data sconosciuta';
    final now = DateTime.now();
    final days = now.difference(d).inDays;
    if (days == 0) return 'oggi';
    if (days == 1) return '1 giorno fa';
    if (days < 30) return '$days giorni fa';
    final months = (days / 30).floor();
    if (months < 12) return '$months mes${months == 1 ? "e" : "i"} fa';
    final years = (days / 365).floor();
    return '$years ann${years == 1 ? "o" : "i"} fa';
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final palette = widget.palette;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded,
              color: palette.error, size: 36),
          title: const Text('⚠ Attenzione GDPR'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stai per riportare ${widget.contact.name} '
                'dallo stato 🔴 Rifiutato a ⚪ Nuovo.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Il sistema NON ricorda perché è stato rifiutato. Procedi SOLO se sei certo che:',
                style: TextStyle(
                    fontSize: 13, color: palette.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                '✅ Era finito qui per scadenza 30 giorni senza risposta '
                'al soft opt-in (riprovo OK dopo qualche mese)',
                style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2E7D32),
                    height: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                '❌ NON ha mai risposto STOP esplicitamente '
                '(riprovare = violazione GDPR sanzionabile)',
                style: TextStyle(
                    fontSize: 12, color: palette.error, height: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                '❌ NON si è registrato in app togliendo il consenso '
                'marketing (scelta esplicita intoccabile)',
                style: TextStyle(
                    fontSize: 12, color: palette.error, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Confermando, ti assumi la responsabilità che questo cliente '
                'non abbia dato un rifiuto esplicito.',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: palette.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.palette.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Riporta in ⚪ Nuovi'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await marketingContactsState.resetToNuovo(widget.contact.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              '${widget.contact.name} riportato in ⚪ Nuovi.')),
        );
      }
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
    final when = c.optInRepliedAt;
    final reasonLabel = RejectionReason.label(c.rejectionReason);
    final resettable = RejectionReason.isResettable(c.rejectionReason);
    final elapsed = _elapsedFrom(when);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                Text(c.phone,
                    style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontFamily: 'Consolas')),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 11, color: palette.textSecondary),
                    const SizedBox(width: 3),
                    Text(elapsed,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Motivo: $reasonLabel',
                      style: TextStyle(
                          fontSize: 10.5,
                          color: resettable
                              ? palette.warning
                              : palette.error,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (resettable)
            IconButton(
              tooltip: 'Riporta in ⚪ Nuovi (con conferma GDPR)',
              icon: const Icon(Icons.restart_alt, size: 22),
              color: palette.warning,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: _confirmReset,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.error),
              ),
              child: Tooltip(
                message:
                    'Reset non autorizzato dal cliente (vincolo GDPR)',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock,
                        size: 12, color: palette.error),
                    const SizedBox(width: 3),
                    Text('NO RESET',
                        style: TextStyle(
                            color: palette.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
