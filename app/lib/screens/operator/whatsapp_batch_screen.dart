import 'package:flutter/material.dart';
import '../../services/messaging_service.dart';
import '../../state/marketing_contacts_state.dart';
import '../../state/promotions_state.dart';
import '../../theme/app_theme.dart';

/// Schermo lista per WhatsApp manual batch.
/// L'operatore vede tutti i destinatari in una lista e per ognuno
/// clicca "Apri WhatsApp" → si apre WA pre-compilato + il contatto
/// viene marcato come inviato (sparisce dalla coda).
///
/// 2 modalita':
///   - channel='soft_optin': recipients DINAMICI (current ⚪ Nuovi);
///     un reset 🔴→⚪ rientra automaticamente nella coda.
///   - channel='whatsapp' (promo standard): recipients da snapshot
///     promotion.recipientIds (operator ha gia' deciso a chi mandare).
class WhatsAppBatchScreen extends StatefulWidget {
  final String promotionId;
  const WhatsAppBatchScreen({super.key, required this.promotionId});

  @override
  State<WhatsAppBatchScreen> createState() => _WhatsAppBatchScreenState();
}

class _WhatsAppBatchScreenState extends State<WhatsAppBatchScreen> {
  final Set<String> _opening = {}; // contactIds in fase di click

  String _buildMessage(Promotion promo, MarketingContact contact) {
    final firstName = contact.name.split(' ').first;
    if (promo.channel == 'soft_optin') {
      return 'Ciao $firstName, ti scriviamo da Silvestre Fotoservizi 📸. '
          'Hai usato i nostri servizi in passato e vorremmo restare in '
          'contatto via WhatsApp con sconti riservati e novità.\n\n'
          'Rispondi SI per iscriverti, oppure ignora questo messaggio '
          'per uscire dalla lista.\n\n'
          'In qualunque momento puoi disiscriverti rispondendo STOP.';
    }
    final df = promo.validFrom != null ? _fmtDate(promo.validFrom!) : '____';
    final dt = promo.validTo != null ? _fmtDate(promo.validTo!) : '____';
    return '🎁 ${promo.title}\n\n'
        'Ciao $firstName,\n${promo.details}\n\n'
        '💰 ${promo.cost}\n'
        '📅 Valida dal $df al $dt\n\n'
        'Silvestre Fotoservizi · Via V. Emanuele III, 205 — '
        'Frattamaggiore (NA)\n'
        'Per disiscriverti rispondi STOP.';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Click su Apri WhatsApp: marca come inviato + apre WA precompilato.
  /// Per soft_optin: markOptInSent (passa a 🟡), poi markSent sulla promo.
  /// Per promo standard: solo markSent sulla promo.
  Future<void> _openAndMark(
      Promotion promo, MarketingContact contact) async {
    if (_opening.contains(contact.id)) return;
    setState(() => _opening.add(contact.id));
    final message = _buildMessage(promo, contact);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. apri WhatsApp (fire-and-forget: l'utente deve premere Invia in WA)
      await MessagingService.sendWhatsApp(
        phone: contact.phone,
        message: message,
      );
      // 2. marca soft opt-in inviato (passa il contatto a 🟡 In attesa)
      if (promo.channel == 'soft_optin') {
        await marketingContactsState.markOptInSent(contact.id);
      }
      // 3. tracking sulla promo
      await promotionsState.markSent(promo.id, contact.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) setState(() => _opening.remove(contact.id));
    }
  }

  Future<bool> _confirmCancel() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annullare la campagna?'),
        content: const Text(
          'Gli invii gia\' effettuati restano. Potrai sempre riprenderla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, continua'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sì, annulla'),
          ),
        ],
      ),
    );
    return r == true;
  }

  /// Calcola la lista dei destinatari da mostrare.
  /// soft_optin: tutti i ⚪ Nuovi correnti (dinamico).
  /// promo: recipientIds del promo - sentIds.
  List<MarketingContact> _computeRecipients(Promotion promo) {
    final all = marketingContactsState.contacts;
    if (promo.channel == 'soft_optin') {
      return all.where((c) => c.isNew).toList()
        ..sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    // promo standard: recipientIds snapshot - sentIds
    final pending = promo.recipientIds
        .where((id) => !promo.sentIds.contains(id))
        .toSet();
    return all.where((c) => pending.contains(c.id)).toList()
      ..sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return AnimatedBuilder(
      animation:
          Listenable.merge([promotionsState, marketingContactsState]),
      builder: (context, _) {
        Promotion? promo;
        try {
          promo = promotionsState.promotions
              .firstWhere((p) => p.id == widget.promotionId);
        } catch (_) {
          promo = null;
        }
        if (promo == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invio WhatsApp')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (promo.status == 'completed') {
          return _completedScreen(context, palette, promo);
        }
        if (promo.status == 'cancelled') {
          return _cancelledScreen(context, palette, promo);
        }

        final recipients = _computeRecipients(promo);
        final sentCount = promo.sentIds.length;
        final remaining = recipients.length;
        final total = sentCount + remaining;
        final progress = total == 0 ? 1.0 : sentCount / total;

        // Auto-complete se nessuno piu' da inviare (solo per snapshot promo)
        if (promo.channel != 'soft_optin' && remaining == 0 &&
            promo.status == 'in_progress') {
          promotionsState.markCompleted(promo.id).catchError((_) {});
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(promo.channel == 'soft_optin'
                ? 'Campagna Soft Opt-in'
                : 'Invio WhatsApp'),
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  if (await _confirmCancel()) {
                    await promotionsState.cancel(promo!.id);
                    if (!mounted) return;
                    nav.pop();
                  }
                },
                icon: const Icon(Icons.stop_circle),
                label: const Text('Annulla'),
              ),
            ],
          ),
          body: Column(
            children: [
              _progressCard(palette, promo, sentCount, remaining,
                  total, progress),
              _hint(palette, promo),
              Expanded(
                child: recipients.isEmpty
                    ? _emptyState(palette, promo)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: recipients.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final c = recipients[i];
                          return _ContactRow(
                            contact: c,
                            palette: palette,
                            opening: _opening.contains(c.id),
                            onOpenWhatsApp: () =>
                                _openAndMark(promo!, c),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _progressCard(SilvestrePalette palette, Promotion promo,
      int sentCount, int remaining, int total, double progress) {
    final isSoftOptIn = promo.channel == 'soft_optin';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSoftOptIn ? Icons.campaign : Icons.send,
                  color: palette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSoftOptIn ? 'Richiesta consenso marketing' : promo.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statBlock(palette, 'Inviati', sentCount,
                  const Color(0xFF2E7D32)),
              const SizedBox(width: 14),
              _statBlock(palette, 'Ancora da inviare', remaining,
                  palette.warning),
              const SizedBox(width: 14),
              _statBlock(palette, 'Totale', total, palette.primary),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(progress * 100).toStringAsFixed(1)}% completato',
              style: TextStyle(
                  fontSize: 11,
                  color: palette.textSecondary,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _statBlock(
      SilvestrePalette palette, String label, int n, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        Text('$n',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color)),
      ],
    );
  }

  Widget _hint(SilvestrePalette palette, Promotion promo) {
    final isSoftOptIn = promo.channel == 'soft_optin';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: palette.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSoftOptIn
                    ? 'Cliccando "Apri WhatsApp" il contatto passa subito da '
                        '⚪ Nuovo a 🟡 In attesa. Consigliato 50-100/giorno per '
                        'non triggerare l\'anti-spam.'
                    : 'Cliccando "Apri WhatsApp" il contatto viene marcato come '
                        'inviato e sparisce dalla lista.',
                style: TextStyle(fontSize: 11, color: palette.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(SilvestrePalette palette, Promotion promo) {
    final isSoftOptIn = promo.channel == 'soft_optin';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration,
                size: 64, color: const Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            Text(
              isSoftOptIn
                  ? 'Nessun cliente ⚪ Nuovo da contattare al momento!'
                  : 'Tutti i destinatari sono stati contattati!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isSoftOptIn
                  ? 'Per riportare clienti dallo stato 🔴 a ⚪ Nuovo usa il '
                      'pulsante "Riporta in Nuovi" nella Tab 🔴 Rifiutati.'
                  : 'Puoi chiudere questa schermata.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: palette.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completedScreen(
      BuildContext context, SilvestrePalette palette, Promotion promo) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invio completato')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  size: 96, color: const Color(0xFF2E7D32)),
              const SizedBox(height: 20),
              Text('Campagna completata!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary)),
              const SizedBox(height: 8),
              Text(
                  'Inviati ${promo.sentIds.length} messaggi via WhatsApp '
                  'a "${promo.title}".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Torna al pannello'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cancelledScreen(
      BuildContext context, SilvestrePalette palette, Promotion promo) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campagna annullata')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, size: 96, color: palette.warning),
              const SizedBox(height: 20),
              Text('Campagna annullata',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary)),
              const SizedBox(height: 8),
              Text(
                  '${promo.sentIds.length} messaggi erano stati inviati.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Torna al pannello'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final MarketingContact contact;
  final SilvestrePalette palette;
  final bool opening;
  final VoidCallback onOpenWhatsApp;

  const _ContactRow({
    required this.contact,
    required this.palette,
    required this.opening,
    required this.onOpenWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isFromCsv = contact.source.startsWith('csv');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          const Text('⚪', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(isFromCsv ? '📇' : '📱',
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: palette.textPrimary)),
                Text(contact.phone,
                    style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontFamily: 'Consolas')),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: opening
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.chat, size: 14),
            onPressed: opening ? null : onOpenWhatsApp,
            label: const Text(
              'Apri WhatsApp',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
