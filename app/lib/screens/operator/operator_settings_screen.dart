import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user.dart';
import '../../services/contacts_export_service.dart';
import '../../state/auth_state.dart';
import '../../state/operators_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_theme.dart';

class OperatorSettingsScreen extends StatelessWidget {
  const OperatorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return AnimatedBuilder(
      animation: settingsState,
      builder: (context, _) {
        final s = settingsState.settings;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('Operatori autorizzati', palette: palette),
            const SizedBox(height: 4),
            Text(
              'Solo questi utenti possono accedere all\'app operatore. '
              'Per aggiungere un operatore, deve prima registrarsi come cliente nell\'app.',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            const SizedBox(height: 10),
            _OperatorsPanel(palette: palette),
            const SizedBox(height: 24),
            _SectionTitle('Capacità giornaliera', palette: palette),
            const SizedBox(height: 8),
            _NumberCard(
              label: 'Limite ordini al giorno',
              value: s.dailyOrderLimit,
              min: 1,
              max: 100,
              onChanged: (v) => settingsState.updateDailyLimit(v),
              palette: palette,
            ),
            const SizedBox(height: 18),
            _SectionTitle('Allerta ritardi', palette: palette),
            const SizedBox(height: 8),
            _NumberCard(
              label: 'Ore prima di marcare un ordine come "in ritardo"',
              value: s.lateOrderHours,
              min: 6,
              max: 168,
              step: 6,
              onChanged: (v) => settingsState.updateLateHours(v),
              palette: palette,
            ),
            const SizedBox(height: 18),
            _SectionTitle('Template messaggi cliente', palette: palette),
            const SizedBox(height: 4),
            Text(
              'Usa {{name}} e {{code}} come variabili. Esempio: "Ciao {{name}}, il tuo ordine {{code}} è pronto!"',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            const SizedBox(height: 10),
            for (final entry in s.messageTemplates.entries)
              _TemplateCard(
                templateKey: entry.key,
                value: entry.value,
                palette: palette,
              ),
            const SizedBox(height: 24),
            _SectionTitle('Strumenti esterni', palette: palette),
            const SizedBox(height: 8),
            _LinkCard(
              icon: Icons.analytics_outlined,
              title: 'Google Analytics 4',
              subtitle: 'Statistiche app: visitatori, conversioni, abbandoni',
              url: 'https://analytics.google.com/',
              palette: palette,
            ),
            const SizedBox(height: 8),
            _LinkCard(
              icon: Icons.cloud_outlined,
              title: 'Firebase Console',
              subtitle: 'Database, utenti, hosting, regole sicurezza',
              url: 'https://console.firebase.google.com/project/silvestre-fotoservizi',
              palette: palette,
            ),
            const SizedBox(height: 8),
            _LinkCard(
              icon: Icons.photo_library_outlined,
              title: 'Cloudinary Console',
              subtitle: 'Foto caricate dai clienti',
              url: 'https://console.cloudinary.com/',
              palette: palette,
            ),
            const SizedBox(height: 24),
            _SectionTitle('Esportazione dati', palette: palette),
            const SizedBox(height: 4),
            Text(
              'Esporta in formato CSV (apribile con Excel) tutti i contatti '
              'attualmente presenti su Firestore. Utile per backup periodici '
              'o per fini di audit GDPR.',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            const SizedBox(height: 10),
            _ExportContactsButton(palette: palette),
            const SizedBox(height: 24),
            _SectionTitle('Negozio', palette: palette),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv(palette, 'Nome', 'Silvestre Fotoservizi'),
                  _kv(palette, 'Indirizzo',
                      'Via V. Emanuele III, 205 — 80027 Frattamaggiore (NA)'),
                  _kv(palette, 'Telefono', '+39 335 169 7903'),
                  _kv(palette, 'Email', 'fotosilvestre1970@gmail.com'),
                  _kv(palette, 'Orari', 'Lun–Sab 09:00–13:00'),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _kv(SilvestrePalette palette, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(k,
                style: TextStyle(
                    color: palette.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(v,
                style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ExportContactsButton extends StatefulWidget {
  final SilvestrePalette palette;
  const _ExportContactsButton({required this.palette});

  @override
  State<_ExportContactsButton> createState() =>
      _ExportContactsButtonState();
}

class _ExportContactsButtonState extends State<_ExportContactsButton> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final n = await ContactsExportService.exportAllToCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✓ Esportati $n contatti. File CSV scaricato sul tuo dispositivo.'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore export: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_download_outlined,
                  color: palette.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Esporta tutti i contatti',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Genera un file .csv (separatore ";", apribile con Excel) con '
            'nome, telefono, email, stato consenso, date di consenso/invio '
            'soft opt-in, fonte. Il download parte automatico.',
            style: TextStyle(
                fontSize: 11, color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _exporting ? null : _export,
            label: Text(
              _exporting
                  ? 'Esportazione in corso...'
                  : '📥 SCARICA CONTATTI (.csv)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
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
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: palette.textSecondary,
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final SilvestrePalette palette;
  const _NumberCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: palette.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed:
                value - step >= min ? () => onChanged(value - step) : null,
          ),
          SizedBox(
            width: 40,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                )),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                value + step <= max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final String templateKey;
  final String value;
  final SilvestrePalette palette;
  const _TemplateCard({
    required this.templateKey,
    required this.value,
    required this.palette,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _OperatorsPanel extends StatefulWidget {
  final SilvestrePalette palette;
  const _OperatorsPanel({required this.palette});

  @override
  State<_OperatorsPanel> createState() => _OperatorsPanelState();
}

class _OperatorsPanelState extends State<_OperatorsPanel> {
  final _emailController = TextEditingController();
  bool _adding = false;
  String? _addError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addOperator() async {
    setState(() {
      _adding = true;
      _addError = null;
    });
    try {
      await operatorsState.promoteByEmail(_emailController.text);
      if (!mounted) return;
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operatore aggiunto.')),
      );
    } on OperatorException catch (e) {
      if (mounted) setState(() => _addError = e.message);
    } catch (e) {
      if (mounted) setState(() => _addError = 'Errore: $e');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _confirmRemove(AppUser op) async {
    final current = authState.currentUser!;
    if (op.id == current.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non puoi rimuovere te stesso.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rimuovere operatore?'),
        content: Text('${op.displayName} non potrà più accedere all\'app operatore. '
            'Tornerà ad essere un cliente normale.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rimuovi')),
        ],
      ),
    );
    if (ok == true) {
      await operatorsState.demote(op.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: operatorsState,
      builder: (context, _) {
        final ops = operatorsState.operators;
        final currentUid = authState.currentUser?.id;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ops.isEmpty)
                Text('Nessun operatore configurato.',
                    style:
                        TextStyle(color: widget.palette.textSecondary))
              else
                ...ops.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: widget.palette.primary,
                            radius: 18,
                            child: Text(
                              o.displayName.isNotEmpty
                                  ? o.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(o.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              widget.palette.textPrimary,
                                        )),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: widget.palette.primary,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'OPERATORE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (o.id == currentUid) ...[
                                      const SizedBox(width: 4),
                                      Text('(tu)',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: widget
                                                  .palette.textSecondary)),
                                    ],
                                  ],
                                ),
                                Text(o.email,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: widget.palette.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Rimuovi operatore',
                            icon: Icon(Icons.person_remove_outlined,
                                color: widget.palette.error),
                            onPressed: () => _confirmRemove(o),
                          ),
                        ],
                      ),
                    )),
              const Divider(),
              const SizedBox(height: 8),
              Text('Aggiungi operatore',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.palette.textPrimary)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'email@silvestre.it',
                        errorText: _addError,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _adding
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add_outlined),
                    label: const Text('Aggiungi'),
                    onPressed: _adding ? null : _addOperator,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateCardState extends State<_TemplateCard> {
  late final TextEditingController _c;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _label => switch (widget.templateKey) {
        'submitted' => 'Ordine ricevuto',
        'inProduction' => 'In lavorazione',
        'ready' => 'Pronto per il ritiro',
        'pickedUp' => 'Ringraziamento post-ritiro',
        _ => widget.templateKey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: widget.palette.textPrimary,
              )),
          const SizedBox(height: 6),
          TextField(
            controller: _c,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() => _dirty = true),
          ),
          if (_dirty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await settingsState.updateTemplate(
                      widget.templateKey, _c.text);
                  if (mounted) setState(() => _dirty = false);
                },
                child: const Text('Salva'),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final SilvestrePalette palette;
  const _LinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.palette,
  });

  Future<void> _open() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
