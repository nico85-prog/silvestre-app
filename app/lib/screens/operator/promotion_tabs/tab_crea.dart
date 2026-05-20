import 'package:flutter/material.dart';
import '../../../state/auth_state.dart';
import '../../../state/marketing_contacts_state.dart';
import '../../../state/promotions_state.dart';
import '../../../theme/app_theme.dart';
import '../whatsapp_batch_screen.dart';

/// Tab 2 — Crea Promozione (form + invio).
/// PLACEHOLDER: scaffold con tutti i campi visibili. La logica di invio
/// (FCM, Email, WhatsApp batch) verra' completata nella fase B/C.
class PromoTabCrea extends StatelessWidget {
  final SilvestrePalette palette;
  final TextEditingController titleController;
  final TextEditingController detailsController;
  final TextEditingController costController;
  final DateTime? validFrom;
  final DateTime? validTo;
  final ValueChanged<DateTime?> onValidFromChanged;
  final ValueChanged<DateTime?> onValidToChanged;
  final List<String> photoUrls;
  final VoidCallback onPhotosChanged;
  final Set<String> excludedFromCampaign;
  final ValueChanged<int> onJumpToTab;

  const PromoTabCrea({
    super.key,
    required this.palette,
    required this.titleController,
    required this.detailsController,
    required this.costController,
    required this.validFrom,
    required this.validTo,
    required this.onValidFromChanged,
    required this.onValidToChanged,
    required this.photoUrls,
    required this.onPhotosChanged,
    required this.excludedFromCampaign,
    required this.onJumpToTab,
  });

  bool get _isFormValid =>
      titleController.text.trim().isNotEmpty &&
      detailsController.text.trim().isNotEmpty &&
      costController.text.trim().isNotEmpty &&
      validFrom != null &&
      validTo != null;

  int _recipientsCount() {
    final all = marketingContactsState.contacts
        .where((c) => c.isOptedIn)
        .map((c) => c.id)
        .toSet();
    return all.difference(excludedFromCampaign).length;
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? (validFrom ?? now) : (validTo ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      if (isFrom) {
        onValidFromChanged(picked);
      } else {
        onValidToChanged(picked);
      }
    }
  }

  Future<void> _confirmAndSend(BuildContext context, String channel) async {
    final n = _recipientsCount();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma invio'),
        content: Text(
          'Stai per inviare la promozione a $n contatti via $channel.\n\n'
          'Hai impostato correttamente i contatti inclusi (Tab 3) ed '
          'esclusi (Tab 4)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO, INDIETRO'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send),
            label: const Text('SÌ, INVIA'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (result != true || !context.mounted) return;

    // Dispatch per canale
    if (channel == 'WhatsApp') {
      await _startWhatsAppBatch(context);
    } else if (channel == 'Push App') {
      _showSetupRequired(context, 'Push App (FCM)',
          'Per attivare le push notification serve:\n\n'
          '1. Attivare il piano Firebase Blaze (pay-as-you-go, ~0€/mese sotto soglia)\n'
          '2. Deploy della Cloud Function che invia push agli utenti app opted-in\n\n'
          'Quando vuoi attivarlo, chiedimi di configurare la Cloud Function.');
    }
  }

  void _showSetupRequired(
      BuildContext context, String channel, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configura $channel'),
        content: Text(body),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  Future<void> _startWhatsAppBatch(BuildContext context) async {
    final user = authState.currentUser;
    if (user == null) return;
    final recipients = marketingContactsState.contacts
        .where((c) => c.isOptedIn)
        .map((c) => c.id)
        .where((id) => !excludedFromCampaign.contains(id))
        .toList();
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun destinatario selezionato.'),
        ),
      );
      return;
    }
    try {
      final id = await promotionsState.createWhatsAppCampaign(
        title: titleController.text.trim(),
        details: detailsController.text.trim(),
        cost: costController.text.trim(),
        validFrom: validFrom,
        validTo: validTo,
        photoUrls: photoUrls,
        recipientIds: recipients,
        operatorUid: user.id,
      );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WhatsAppBatchScreen(promotionId: id),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: marketingContactsState,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: titleController,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Titolo promozione',
                hintText: 'Es. Stampe in tela -30%',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Dettagli promozione',
                hintText: 'Spiega cosa offre la promo, condizioni, ecc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Costo / Sconto',
                hintText: 'Es. -30%, da 10€, gratis',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(
                      validFrom == null
                          ? 'Valida dal...'
                          : 'Dal ${_fmtDate(validFrom!)}',
                    ),
                    onPressed: () => _pickDate(context, true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_busy),
                    label: Text(
                      validTo == null
                          ? '... al ...'
                          : 'Al ${_fmtDate(validTo!)}',
                    ),
                    onPressed: () => _pickDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.preview, color: palette.primary),
                      const SizedBox(width: 8),
                      Text('Anteprima messaggio',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: palette.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildPreview(),
                    style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: palette.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.group, color: palette.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Destinatari: ${_recipientsCount()} '
                      '(${marketingContactsState.optedInCount} acconsentiti '
                      '- ${excludedFromCampaign.length} esclusi)',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onJumpToTab(2),
                    child: const Text('Gestisci'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Invia tramite',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary)),
            const SizedBox(height: 8),
            _sendButton(
              context,
              icon: Icons.chat,
              label: 'WhatsApp (manual batch)',
              color: const Color(0xFF25D366),
              subtitle: '50-100/giorno, 1 click invio per contatto',
              channel: 'WhatsApp',
            ),
            const SizedBox(height: 8),
            _sendButton(
              context,
              icon: Icons.notifications_active,
              label: 'Push App (FCM)',
              color: const Color(0xFF1976D2),
              subtitle: 'Istantaneo, gratis, raggiunge solo utenti app',
              channel: 'Push App',
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _buildPreview() {
    final t = titleController.text.trim();
    final d = detailsController.text.trim();
    final c = costController.text.trim();
    final df = validFrom != null ? _fmtDate(validFrom!) : '____';
    final dt = validTo != null ? _fmtDate(validTo!) : '____';
    return '🎁 ${t.isEmpty ? "[titolo]" : t}\n\n'
        '${d.isEmpty ? "[dettagli]" : d}\n\n'
        '💰 ${c.isEmpty ? "[costo]" : c}\n'
        '📅 Valida dal $df al $dt\n\n'
        'Silvestre Fotoservizi · Via V. Emanuele III, 205 — '
        'Frattamaggiore (NA)\n'
        'Per disiscriverti rispondi STOP.';
  }

  Widget _sendButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String subtitle,
    required String channel,
  }) {
    final enabled = _isFormValid && _recipientsCount() > 0;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(icon),
          ),
          title: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color)),
          subtitle: Text(subtitle,
              style: TextStyle(
                  fontSize: 11, color: palette.textSecondary)),
          trailing: Icon(Icons.send, color: color),
          enabled: enabled,
          onTap: enabled ? () => _confirmAndSend(context, channel) : null,
        ),
      ),
    );
  }
}
