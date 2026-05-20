import 'package:flutter/material.dart';
import '../../services/messaging_service.dart';
import '../../state/marketing_contacts_state.dart';
import '../../state/promotions_state.dart';
import '../../theme/app_theme.dart';

/// Schermo dedicato all'invio WhatsApp manual batch.
/// Per ogni contatto: 1) "Apri WhatsApp" → MessagingService apre WA pre-compilato,
/// 2) operatore preme Invia in WA, 3) torna in app, 4) "✓ Inviato, prossimo".
/// Stato persistito in Firestore (campo sentIds) → resume cross-sessione.
class WhatsAppBatchScreen extends StatefulWidget {
  final String promotionId;
  const WhatsAppBatchScreen({super.key, required this.promotionId});

  @override
  State<WhatsAppBatchScreen> createState() => _WhatsAppBatchScreenState();
}

class _WhatsAppBatchScreenState extends State<WhatsAppBatchScreen> {
  bool _opening = false;
  bool _markingSent = false;

  /// Costruisce il messaggio dalla promo + nome destinatario.
  String _buildMessage(Promotion promo, MarketingContact contact) {
    final firstName = contact.name.split(' ').first;
    if (promo.channel == 'soft_optin') {
      // Template FISSO non modificabile per il soft opt-in iniziale.
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

  Future<void> _sendCurrent(Promotion promo, MarketingContact contact) async {
    setState(() => _opening = true);
    final message = _buildMessage(promo, contact);
    final ok = await MessagingService.sendWhatsApp(
      phone: contact.phone,
      message: message,
    );
    if (!mounted) return;
    setState(() => _opening = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossibile aprire WhatsApp per ${contact.phone}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _markSentAndAdvance(Promotion promo, String contactId) async {
    setState(() => _markingSent = true);
    try {
      await promotionsState.markSent(promo.id, contactId);
      // Soft opt-in: aggiorna anche optInSentAt sul contatto → passa
      // automaticamente da ⚪ Nuovo a 🟡 In attesa.
      if (promo.channel == 'soft_optin') {
        await marketingContactsState.markOptInSent(contactId);
      }
      // Se questo era l'ultimo, marca completata
      final updated = promotionsState.promotions.firstWhere(
        (p) => p.id == promo.id,
        orElse: () => promo,
      );
      if (updated.sentCount + 1 >= updated.totalCount) {
        await promotionsState.markCompleted(promo.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingSent = false);
    }
  }

  Future<bool> _confirmCancel() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annullare la campagna?'),
        content: const Text(
          'Gli invii gia\' effettuati restano. Potrai sempre riprenderla '
          'dalla dashboard.',
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

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [promotionsState, marketingContactsState]),
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
        // In progress
        final pending = promo.recipientIds
            .where((id) => !promo!.sentIds.contains(id))
            .toList();
        if (pending.isEmpty) {
          // Just finished - mark completed
          promotionsState.markCompleted(promo.id).catchError((_) {});
          return _completedScreen(context, palette, promo);
        }
        final currentId = pending.first;
        MarketingContact? current;
        try {
          current = marketingContactsState.contacts
              .firstWhere((c) => c.id == currentId);
        } catch (_) {
          // Contatto scomparso (es. eliminato). Marca come "skipped" passando avanti
          promotionsState.markSent(promo.id, currentId).catchError((_) {});
          return Scaffold(
            appBar: AppBar(title: const Text('Invio WhatsApp')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invio WhatsApp'),
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _progressCard(palette, promo),
              const SizedBox(height: 16),
              _contactCard(palette, current, promo),
              const SizedBox(height: 16),
              _messagePreview(palette, _buildMessage(promo, current)),
              const SizedBox(height: 16),
              _actions(palette, promo, current),
              const SizedBox(height: 24),
              _antiSpamHint(palette),
            ],
          ),
        );
      },
    );
  }

  Widget _progressCard(SilvestrePalette palette, Promotion promo) {
    return Container(
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
              Icon(Icons.send, color: palette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${promo.sentCount} / ${promo.totalCount} inviati',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                      fontSize: 16),
                ),
              ),
              Text(
                '${(promo.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                    fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: promo.progress,
              minHeight: 8,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(
      SilvestrePalette palette, MarketingContact c, Promotion promo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            child: const Icon(Icons.chat),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATARIO ${promo.sentCount + 1} / ${promo.totalCount}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: palette.textSecondary),
                ),
                Text(
                  c.name,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary),
                ),
                Text(
                  c.phone,
                  style: TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 14,
                      color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagePreview(SilvestrePalette palette, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7FFDB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF25D366)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: Color(0xFF075E54), size: 18),
              const SizedBox(width: 6),
              const Text('Anteprima messaggio',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF075E54),
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _actions(
      SilvestrePalette palette, Promotion promo, MarketingContact c) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _opening
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.open_in_new),
            onPressed: _opening ? null : () => _sendCurrent(promo, c),
            label: const Text(
              '1. APRI WHATSAPP CON MESSAGGIO',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Premi "Invia" su WhatsApp, poi torna qui per il prossimo',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              color: palette.textSecondary,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _markingSent
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle),
            onPressed: _markingSent
                ? null
                : () => _markSentAndAdvance(promo, c.id),
            label: const Text(
              '2. INVIATO, PROSSIMO →',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => _markSentAndAdvance(promo, c.id),
          child: const Text('Salta questo contatto'),
        ),
      ],
    );
  }

  Widget _antiSpamHint(SilvestrePalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              'Consigliato max 50-100 invii al giorno per non '
              'triggerare l\'anti-spam WhatsApp. Riprendi domani dalla '
              'dashboard.',
              style: TextStyle(fontSize: 11, color: palette.textPrimary),
            ),
          ),
        ],
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
                  'Inviati ${promo.sentCount} messaggi via WhatsApp '
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
              Icon(Icons.cancel,
                  size: 96, color: palette.warning),
              const SizedBox(height: 20),
              Text('Campagna annullata',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary)),
              const SizedBox(height: 8),
              Text(
                  '${promo.sentCount} di ${promo.totalCount} messaggi erano '
                  'già stati inviati.',
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
