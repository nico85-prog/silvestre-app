import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../state/orders_state.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_picker_section.dart';
import 'quote_accept_screen.dart';

/// Form per richiedere un preventivo per "lavoro personalizzato"
/// (qualcosa che il cliente vuole ma non c'è nel catalogo standard).
class CustomRequestScreen extends StatefulWidget {
  const CustomRequestScreen({super.key});

  @override
  State<CustomRequestScreen> createState() => _CustomRequestScreenState();
}

class _CustomRequestScreenState extends State<CustomRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  List<String> _photoUrls = [];
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = authState.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final pickupCode = await ordersState.submitCustomRequest(
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        photoUrls: _photoUrls,
        customerName: user.displayName,
        customerPhone: user.phone,
      );
      if (!mounted) return;
      await _showConfirmation(pickupCode);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showConfirmation(String code) async {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: palette.success),
            const SizedBox(width: 8),
            const Text('Richiesta inviata'),
          ],
        ),
        content: Text(
          'Il negozio ha ricevuto la tua richiesta (codice $code). '
          'Ti risponderemo con un preventivo nel più breve tempo possibile. '
          'Lo trovi in tab Ordini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Lavoro personalizzato')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CTA per chi ha già ricevuto un preventivo via WhatsApp
                OutlinedButton.icon(
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text(
                      'Ho già un codice preventivo (procedi al pagamento)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: palette.primary, width: 1.5),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EnterQuoteCodeScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.primary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: palette.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cerchi qualcosa che non vedi nel catalogo? '
                          'Descrivici cosa ti serve e ti rispondiamo con un preventivo '
                          'su misura. Senza impegno.',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titolo della richiesta',
                    hintText: 'Es. Stampa su pellicola adesiva 1m x 50cm',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Almeno 3 caratteri'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Descrivi cosa ti serve',
                    hintText:
                        'Materiale, dimensioni, quantità, scadenza, qualsiasi dettaglio utile.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Almeno 10 caratteri — più dettagli ci dai, più preciso il preventivo'
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  'Foto di riferimento (opzionale)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                PhotoPickerSection(
                  initialUrls: _photoUrls,
                  onChanged: (urls) => setState(() => _photoUrls = urls),
                  subtitle:
                      'Foto d\'esempio, schizzi, immagini ispiratrici. Ci aiutano a capire.',
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Invia richiesta'),
                  onPressed: _submitting ? null : _submit,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Riceverai il preventivo entro 24-48h lavorative.',
                    style: TextStyle(
                        fontSize: 12, color: palette.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
