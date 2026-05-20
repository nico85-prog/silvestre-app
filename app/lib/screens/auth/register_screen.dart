import 'package:flutter/material.dart';
import '../../state/auth_state.dart';
import '../../state/marketing_optin_intent.dart';
import '../../theme/app_theme.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _acceptTos = false;
  // Se l'utente è arrivato qui via QR negozio (?optin=marketing), pre-spuntiamo
  // il consenso marketing per fluidità. Default OFF altrimenti (GDPR).
  late bool _acceptMarketing = MarketingOptInIntent.peek();
  bool _acceptPortfolio = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Devi accettare Termini e Privacy per registrarti.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await authState.register(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
        phone: _phone.text,
        acceptTos: _acceptTos,
        acceptMarketing: _acceptMarketing,
        acceptPortfolio: _acceptPortfolio,
      );
      // Consume intent: registrazione fatta, l'opt-in è gia' applicato.
      MarketingOptInIntent.consume();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Crea un account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Benvenuto in Silvestre',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea il tuo account per ordinare le tue stampe.',
                  style: TextStyle(color: palette.textSecondary),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nome e cognome',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Nome troppo corto'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Email non valida'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefono (obbligatorio)',
                    helperText: 'Riceverai un messaggio WhatsApp quando '
                        'l\'ordine sara\' pronto al ritiro.',
                    helperMaxLines: 2,
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Numero di telefono obbligatorio';
                    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length < 8) {
                      return 'Numero non valido (min 8 cifre)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimo 6 caratteri'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Conferma password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v != _password.text)
                      ? 'Le password non coincidono'
                      : null,
                ),
                const SizedBox(height: 16),
                _ConsentBlock(palette: palette, children: [
                  _ConsentTile(
                    value: _acceptTos,
                    onChanged: (v) => setState(() => _acceptTos = v ?? false),
                    required: true,
                    titleBuilder: (palette) => Wrap(
                      children: [
                        Text('Accetto i ',
                            style: TextStyle(color: palette.textPrimary)),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TermsScreen()),
                          ),
                          child: Text('Termini di Servizio',
                              style: TextStyle(
                                color: palette.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                        Text(' e la ',
                            style: TextStyle(color: palette.textPrimary)),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen()),
                          ),
                          child: Text('Informativa Privacy',
                              style: TextStyle(
                                color: palette.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                        Text(' (obbligatorio)',
                            style: TextStyle(
                                color: palette.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Vuota — la box marketing evidenziata è fuori dal blocco
                  // _ConsentBlock per dargli più visibilità
                  _ConsentTile(
                    value: _acceptPortfolio,
                    onChanged: (v) =>
                        setState(() => _acceptPortfolio = v ?? false),
                    titleBuilder: (palette) => Text(
                      'Acconsento all\'uso anonimizzato di esempi delle mie '
                      'stampe nel portfolio del negozio (opzionale, revocabile).',
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _MarketingHighlightBox(
                  value: _acceptMarketing,
                  onChanged: (v) =>
                      setState(() => _acceptMarketing = v ?? false),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crea account'),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hai già un account?',
                        style: TextStyle(color: palette.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Accedi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentBlock extends StatelessWidget {
  final SilvestrePalette palette;
  final List<Widget> children;
  const _ConsentBlock({required this.palette, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(children: children),
    );
  }
}

/// Box marketing evidenziata, separata dai consensi tecnici per dargli
/// visibilità e invogliare l'utente a opt-in (rispettando il GDPR:
/// default OFF, opzionale, app funziona senza).
class _MarketingHighlightBox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _MarketingHighlightBox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final accent = palette.primary; // arancione Silvestre
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? accent.withValues(alpha: 0.16)
              : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? accent : accent.withValues(alpha: 0.35),
            width: value ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.card_giftcard,
                      color: accent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'RESTA AGGIORNATO SULLE PROMOZIONI',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: accent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Sì, voglio ricevere offerte esclusive, sconti e '
                      'novità via WhatsApp ed email',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _benefit(palette, accent, 'Sconti fino al -40% sulle stampe'),
                  _benefit(palette, accent, 'Anteprima nuovi prodotti'),
                  _benefit(palette, accent,
                      'Promo lampo riservate ai clienti app'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Opzionale — puoi disiscriverti quando vuoi dalle '
              'Impostazioni dell\'account.',
              style: TextStyle(
                fontSize: 11,
                color: palette.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefit(SilvestrePalette palette, Color accent, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget Function(SilvestrePalette palette) titleBuilder;
  final bool required;

  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.titleBuilder,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: titleBuilder(palette),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
