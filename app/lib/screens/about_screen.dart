import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi siamo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/brand/silvestre_logo.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Silvestre Fotoservizi',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DAL 1970',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Card(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La nostra storia',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apriamo a Frattamaggiore nel 1970 con un\'idea semplice: '
                  'i ricordi più belli meritano qualcosa di tangibile. '
                  'Da allora abbiamo accompagnato matrimoni, battesimi, '
                  'lauree, viaggi e ogni piccolo grande momento delle famiglie '
                  'del nostro territorio.',
                  style: TextStyle(
                    color: palette.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Oggi la stessa cura artigianale incontra la comodità '
                  'dell\'app: scegli quello che vuoi stampare, carichi le foto, '
                  'lo prepariamo noi. Tu vieni a ritirarlo quando ti fa comodo.',
                  style: TextStyle(
                    color: palette.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I nostri impegni',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _Bullet(
                  icon: Icons.high_quality,
                  text: 'Materiali professionali e durevoli: carte fotografiche, '
                      'tele canvas, ceramiche di prima qualità.',
                  palette: palette,
                ),
                _Bullet(
                  icon: Icons.lock_outline,
                  text: 'Le tue foto sono tue. Le cancelliamo automaticamente '
                      '30 giorni dopo il ritiro.',
                  palette: palette,
                ),
                _Bullet(
                  icon: Icons.handshake_outlined,
                  text: 'Ritiro in negozio: paghi solo quando vedi il lavoro, '
                      'e se qualcosa non va lo rifacciamo subito.',
                  palette: palette,
                ),
                _Bullet(
                  icon: Icons.bolt,
                  text: 'Pronti in 24-48 ore lavorative per stampe semplici, '
                      '3-5 giorni per fotolibri e tele.',
                  palette: palette,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vieni a trovarci',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _Row(
                  icon: Icons.location_on_outlined,
                  text:
                      'Via Vittorio Emanuele III, 205\n80027 Frattamaggiore (NA)',
                  palette: palette,
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: Icons.access_time,
                  text: 'Lunedì – Sabato · 09:00 – 13:00',
                  palette: palette,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text('Chiama'),
                        onPressed: () =>
                            MessagingService.callPhone('+393478260320'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.mail_outline),
                        label: const Text('Email'),
                        onPressed: () => MessagingService.sendEmail(
                          email: 'fotosilvestre1970@gmail.com',
                          subject: 'Richiesta info',
                          body: 'Ciao Silvestre, vorrei sapere...',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Grazie per averci scelto.',
              style: TextStyle(
                color: palette.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final SilvestrePalette palette;
  final Widget child;
  const _Card({required this.palette, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  final SilvestrePalette palette;
  const _Bullet(
      {required this.icon, required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: palette.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final SilvestrePalette palette;
  const _Row({required this.icon, required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: palette.textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: palette.textPrimary, height: 1.4),
          ),
        ),
      ],
    );
  }
}
