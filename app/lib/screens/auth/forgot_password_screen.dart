import 'package:flutter/material.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authState.sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Recupera password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _sent
              ? _SentBlock(email: _email.text, palette: palette)
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text('Password dimenticata?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              )),
                      const SizedBox(height: 6),
                      Text(
                        'Scrivi l\'email del tuo account. Riceverai un link per impostare una nuova password.',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.mail_outline),
                          errorText: _error,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Email non valida'
                            : null,
                      ),
                      const SizedBox(height: 18),
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
                            : const Text('Invia link di recupero'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SentBlock extends StatelessWidget {
  final String email;
  final SilvestrePalette palette;
  const _SentBlock({required this.email, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mark_email_read_outlined,
                size: 60, color: palette.success),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Email inviata!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Abbiamo inviato un link per resettare la password a:\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 22),
        Text(
          'Controlla la posta in arrivo (anche lo spam). Il link scade in 1 ora.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: palette.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Torna al login'),
        ),
      ],
    );
  }
}
