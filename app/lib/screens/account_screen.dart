import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../state/orders_state.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_picker_sheet.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: authState,
      builder: (context, _) {
        final user = authState.currentUser;
        if (user == null) return const SizedBox.shrink();

        final initials = user.displayName
            .split(' ')
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        Text(user.email,
                            style: TextStyle(color: palette.textSecondary)),
                        if (user.phone != null)
                          Text(user.phone!,
                              style: TextStyle(color: palette.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('Account', palette: palette),
            _Tile(
              icon: Icons.edit_outlined,
              title: 'Modifica profilo',
              onTap: () => _showEditProfile(context, palette),
            ),
            _Tile(
              icon: Icons.location_on_outlined,
              title: 'Negozio di ritiro',
              subtitle: 'Via Vittorio Emanuele III, 205 — Frattamaggiore',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            _SectionTitle('App', palette: palette),
            _Tile(
              icon: Icons.palette_outlined,
              title: 'Tema',
              onTap: () => ThemePickerSheet.show(context),
            ),
            _Tile(
              icon: Icons.notifications_outlined,
              title: 'Notifiche',
              subtitle: 'Avvisi quando il tuo ordine è pronto',
              onTap: () {},
            ),
            _Tile(
              icon: Icons.email_outlined,
              title: 'Comunicazioni marketing',
              subtitle: user.acceptedMarketing ? 'Attive' : 'Disattivate',
              trailingIcon: user.acceptedMarketing
                  ? Icons.toggle_on
                  : Icons.toggle_off_outlined,
              onTap: () => authState.updateProfile(
                  acceptMarketing: !user.acceptedMarketing),
            ),
            const SizedBox(height: 14),
            _SectionTitle('Privacy e dati (GDPR)', palette: palette),
            _Tile(
              icon: Icons.download_outlined,
              title: 'Esporta i miei dati',
              subtitle: 'JSON con profilo, consensi e ordini',
              onTap: () => _exportData(context, palette),
            ),
            _Tile(
              icon: Icons.delete_forever_outlined,
              title: 'Elimina il mio account',
              subtitle: 'Cancella tutti i dati. Irreversibile.',
              danger: true,
              onTap: () => _confirmDelete(context, palette),
            ),
            const SizedBox(height: 14),
            _SectionTitle('Documenti legali', palette: palette),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              title: 'Informativa Privacy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            _Tile(
              icon: Icons.description_outlined,
              title: 'Termini di Servizio',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle('Aiuto', palette: palette),
            _Tile(
              icon: Icons.help_outline,
              title: 'Domande frequenti',
              onTap: () {},
            ),
            _Tile(
              icon: Icons.support_agent_outlined,
              title: 'Contatta il negozio',
              subtitle: '+39 081 830 6365',
              onTap: () {},
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              icon: Icon(Icons.logout, color: palette.error),
              label: Text('Esci',
                  style: TextStyle(
                      color: palette.error, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                cartState.clear();
                authState.logout();
              },
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Silvestre Fotoservizi • v0.1.0',
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData(
      BuildContext context, SilvestrePalette palette) async {
    final user = authState.currentUser!;
    final orders = ordersState.forUser(user.id);
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'user': user.toJson(),
      'orders': orders
          .map((o) => {
                'id': o.id,
                'pickupCode': o.pickupCode,
                'status': o.status.name,
                'total': o.total,
                'createdAt': o.createdAt.toIso8601String(),
                'items': o.items
                    .map((i) => {
                          'product': i.productName,
                          'variant': i.variantName,
                          'quantity': i.quantity,
                          'unitPrice': i.unitPrice,
                          'lineTotal': i.lineTotal,
                        })
                    .toList(),
              })
          .toList(),
    };
    final pretty = const JsonEncoder.withIndent('  ').convert(payload);

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('I tuoi dati'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              pretty,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pretty));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiato negli appunti')),
              );
            },
            child: const Text('Copia'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SilvestrePalette palette) async {
    final confirmController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: palette.error),
              const SizedBox(width: 8),
              const Text('Elimina account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verranno cancellati: il tuo account, profilo, foto e cronologia ordini. '
                'I dati fiscali necessari per legge (es. fatture) saranno conservati '
                'in forma anonimizzata per il periodo di legge (10 anni).',
              ),
              const SizedBox(height: 12),
              const Text(
                'Per confermare, scrivi ELIMINA qui sotto:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'ELIMINA',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.error),
              onPressed: confirmController.text.trim() == 'ELIMINA'
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Elimina definitivamente'),
            ),
          ],
        );
      }),
    );
    if (ok != true) return;
    cartState.clear();
    await authState.deleteAccount();
  }

  Future<void> _showEditProfile(
      BuildContext context, SilvestrePalette palette) async {
    final user = authState.currentUser!;
    final name = TextEditingController(text: user.displayName);
    final phone = TextEditingController(text: user.phone ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifica profilo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nome e cognome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await authState.updateProfile(
                      displayName: name.text, phone: phone.text);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final SilvestrePalette palette;
  const _SectionTitle(this.text, {required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailingIcon;
  final bool danger;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final color = danger ? palette.error : palette.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: danger ? palette.error : palette.textPrimary)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!,
                style: TextStyle(color: palette.textSecondary, fontSize: 12)),
        trailing: Icon(
          trailingIcon ?? Icons.chevron_right,
          color: trailingIcon != null ? color : palette.textSecondary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
