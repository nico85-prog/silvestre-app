import 'package:flutter/material.dart';
import '../../state/auth_state.dart';
import '../../state/marketing_contacts_state.dart';
import '../../state/promotions_state.dart';
import '../../theme/app_theme.dart';
import 'whatsapp_batch_screen.dart';

/// Schermo dedicato alla creazione di una nuova promozione.
/// Aperto dal pulsante "+" del pannello Crea Promozione.
/// I destinatari sono SEMPRE tutti i 🟢 Acconsentiti correnti
/// (la lista viene letta al momento del lancio campagna).
class NewPromotionScreen extends StatefulWidget {
  const NewPromotionScreen({super.key});

  @override
  State<NewPromotionScreen> createState() => _NewPromotionScreenState();
}

class _NewPromotionScreenState extends State<NewPromotionScreen> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _cost = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  bool _creating = false;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _cost.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _title.text.trim().isNotEmpty &&
      _details.text.trim().isNotEmpty &&
      _cost.text.trim().isNotEmpty &&
      _from != null &&
      _to != null;

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? (_from ?? now) : (_to ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _buildPreview() {
    final t = _title.text.trim();
    final d = _details.text.trim();
    final c = _cost.text.trim();
    final df = _from != null ? _fmtDate(_from!) : '____';
    final dt = _to != null ? _fmtDate(_to!) : '____';
    return '🎁 ${t.isEmpty ? "[titolo]" : t}\n\n'
        '${d.isEmpty ? "[dettagli]" : d}\n\n'
        '💰 ${c.isEmpty ? "[costo]" : c}\n'
        '📅 Valida dal $df al $dt\n\n'
        'Silvestre Fotoservizi · Via V. Emanuele III, 205 — '
        'Frattamaggiore (NA)\n'
        'Per disiscriverti rispondi STOP.';
  }

  Future<void> _launch() async {
    final user = authState.currentUser;
    if (user == null) return;
    final recipients = marketingContactsState.contacts
        .where((c) => c.isOptedIn)
        .map((c) => c.id)
        .toList();
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nessun cliente acconsentito a cui inviare la promozione.'),
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma invio'),
        content: Text(
          'Stai per creare una campagna WhatsApp diretta a '
          '${recipients.length} clienti acconsentiti.\n\n'
          'Per ogni contatto WhatsApp si aprirà con il messaggio '
          'precompilato. Tu premi Invia in WhatsApp, poi torni in app '
          'e premi "Inviato, prossimo".\n\n'
          'Vuoi procedere?',
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
    if (confirm != true || !mounted) return;
    setState(() => _creating = true);
    try {
      final id = await promotionsState.createWhatsAppCampaign(
        title: _title.text.trim(),
        details: _details.text.trim(),
        cost: _cost.text.trim(),
        validFrom: _from,
        validTo: _to,
        recipientIds: recipients,
        operatorUid: user.id,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WhatsAppBatchScreen(promotionId: id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Promozione')),
      body: AnimatedBuilder(
        animation: marketingContactsState,
        builder: (context, _) {
          final accCount = marketingContactsState.optedInCount;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF2E7D32)
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group,
                        color: Color(0xFF2E7D32), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Destinatari: $accCount clienti acconsentiti',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: palette.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Titolo promozione',
                  hintText: 'Es. Stampe in tela -30%',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _details,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Dettagli',
                  hintText:
                      'Spiega cosa offre la promo, condizioni, ecc.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cost,
                decoration: const InputDecoration(
                  labelText: 'Costo / Sconto',
                  hintText: 'Es. -30%, da 10€, gratis',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(
                        _from == null
                            ? 'Valida dal...'
                            : 'Dal ${_fmtDate(_from!)}',
                      ),
                      onPressed: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_busy),
                      label: Text(
                        _to == null
                            ? '... al ...'
                            : 'Al ${_fmtDate(_to!)}',
                      ),
                      onPressed: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                    Text(_buildPreview(),
                        style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 13,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  icon: _creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed:
                      (_isValid && !_creating && accCount > 0) ? _launch : null,
                  label: const Text(
                    'INVIA VIA WHATSAPP',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (!_isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Compila tutti i campi obbligatori per abilitare l\'invio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
