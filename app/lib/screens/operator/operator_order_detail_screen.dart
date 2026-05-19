import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order.dart';
import '../../models/photobook.dart';
import '../../services/messaging_service.dart';
import '../../state/orders_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/photobook_page_preview.dart';

class OperatorOrderDetailScreen extends StatelessWidget {
  final CustomerOrder order;
  const OperatorOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Ordine ${order.pickupCode}')),
      body: AnimatedBuilder(
        animation: ordersState,
        builder: (context, _) {
          final live = ordersState.orders.firstWhere(
            (o) => o.id == order.id,
            orElse: () => order,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusHeader(order: live, palette: palette),
              const SizedBox(height: 20),
              _Section(title: 'Cliente', palette: palette),
              const SizedBox(height: 8),
              _InfoCard(
                palette: palette,
                rows: [
                  _Row(Icons.person_outline, 'Nome', live.customerName ?? '—'),
                  _Row(Icons.phone_outlined, 'Telefono',
                      live.customerPhone ?? '—'),
                  _Row(Icons.tag, 'User ID', live.userId.substring(0, 8)),
                ],
              ),
              // Richiesta personalizzata: titolo + descrizione + foto allegate
              if (live.isCustomRequest) ...[
                const SizedBox(height: 20),
                _Section(
                    title: 'Richiesta personalizzata del cliente',
                    palette: palette),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: palette.warning.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_fix_high,
                              color: palette.warning, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              live.customRequestTitle ?? '(senza titolo)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((live.customRequestDescription ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'DESCRIZIONE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: palette.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          live.customRequestDescription!,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (live.customRequestPhotoUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'FOTO ALLEGATE (${live.customRequestPhotoUrls.length})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: palette.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: live.customRequestPhotoUrls.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                live.customRequestPhotoUrls[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 80,
                                  height: 80,
                                  color: palette.border,
                                  child: const Icon(
                                      Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _Section(title: 'Articoli (${live.itemCount})', palette: palette),
              const SizedBox(height: 8),
              ...live.items.map((it) {
                final photobookPages = it.photobookPages
                        ?.map((p) => PhotobookPage.fromFirestore(p))
                        .toList() ??
                    const <PhotobookPage>[];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.productName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    )),
                                Text(it.variantName,
                                    style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 12)),
                                if (it.photoUrls.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                        '${it.photoUrls.length} foto'
                                        '${photobookPages.isNotEmpty ? " · ${photobookPages.length} pagine" : ""}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: palette.textSecondary)),
                                  ),
                              ],
                            ),
                          ),
                          Text('x${it.quantity}',
                              style: TextStyle(color: palette.textSecondary)),
                          const SizedBox(width: 12),
                          Text('€ ${it.lineTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: palette.primary,
                              )),
                        ],
                      ),
                      if (photobookPages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_stories,
                                      size: 14, color: palette.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Anteprima fotolibro (tap su una pagina per ingrandire)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              PhotobookThumbnailGrid(pages: photobookPages),
                            ],
                          ),
                        ),
                      ] else if (it.photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: it.photoUrls.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 6),
                            itemBuilder: (_, i) => InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    insetPadding: const EdgeInsets.all(20),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(it.photoUrls[i]),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  it.photoUrls[i],
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 64,
                                    height: 64,
                                    color: palette.border,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Text('Totale',
                        style: TextStyle(color: palette.textSecondary)),
                    const Spacer(),
                    Text('€ ${live.total.toStringAsFixed(2)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        )),
                  ],
                ),
              ),
              if (live.customerNote != null && live.customerNote!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _Section(title: 'Nota del cliente', palette: palette),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.warning),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sticky_note_2_outlined, color: palette.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(live.customerNote!,
                            style: TextStyle(color: palette.textPrimary)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _Section(title: 'Azioni', palette: palette),
              const SizedBox(height: 8),
              _ActionPanel(order: live, palette: palette),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _StatusHeader({required this.order, required this.palette});

  @override
  Widget build(BuildContext context) {
    final color = order.status.colorOn(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(order.status.icon, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stato',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(order.status.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Codice ritiro',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text(order.pickupCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final SilvestrePalette palette;
  const _Section({required this.title, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: palette.textSecondary,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final SilvestrePalette palette;
  final List<_Row> rows;
  const _InfoCard({required this.palette, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: rows
            .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(r.icon, color: palette.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Text(r.label,
                          style: TextStyle(
                              color: palette.textSecondary, fontSize: 13)),
                      const Spacer(),
                      Text(r.value,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Row {
  final IconData icon;
  final String label;
  final String value;
  _Row(this.icon, this.label, this.value);
}

class _ActionPanel extends StatelessWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _ActionPanel({required this.order, required this.palette});

  @override
  Widget build(BuildContext context) {
    // Custom request: stato quoteRequested → form preventivo
    if (order.status == OrderStatus.quoteRequested && order.isCustomRequest) {
      return _QuoteForm(order: order, palette: palette);
    }
    // Custom request: stato quoted → in attesa cliente
    if (order.status == OrderStatus.quoted) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: palette.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Preventivo inviato. In attesa che il cliente accetti o declini.',
                style: TextStyle(color: palette.textPrimary),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (order.status == OrderStatus.submitted)
          _ActionButton(
            icon: Icons.precision_manufacturing,
            label: 'Avvia lavorazione',
            color: palette.primary,
            onPressed: () => _changeStatusAndNotify(
                context, OrderStatus.inProduction, 'inProduction'),
          ),
        if (order.status == OrderStatus.inProduction)
          _ActionButton(
            icon: Icons.local_mall_outlined,
            label: 'Segna come pronto per il ritiro',
            color: palette.success,
            onPressed: () => _markReady(context),
          ),
        if (order.status == OrderStatus.readyForPickup)
          _ActionButton(
            icon: Icons.check_circle_outline,
            label: 'Cliente ha ritirato',
            color: palette.textSecondary,
            onPressed: () => _changeStatusAndNotify(
                context, OrderStatus.pickedUp, 'pickedUp'),
          ),
        if (order.status != OrderStatus.pickedUp &&
            order.status != OrderStatus.cancelled)
          _ActionButton(
            icon: Icons.cancel_outlined,
            label: 'Annulla ordine',
            color: palette.error,
            outlined: true,
            onPressed: () => _confirmCancel(context),
          ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.message_outlined,
          label: 'Invia messaggio al cliente',
          color: palette.primary,
          outlined: true,
          onPressed: () => _showMessageSheet(context),
        ),
      ],
    );
  }

  /// Aggiorna lo stato dell'ordine e — se il cliente ha telefono — apre
  /// automaticamente WhatsApp con il template messaggio per lo stato nuovo.
  /// L'operatore deve solo premere "Invia" in WhatsApp.
  Future<void> _changeStatusAndNotify(
      BuildContext context, OrderStatus status, String templateKey) async {
    await ordersState.updateStatus(order.id, status);
    if (!context.mounted) return;

    final phone = order.customerPhone?.trim() ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Stato aggiornato. Cliente senza telefono: nessun messaggio inviato.'),
            duration: Duration(seconds: 2)),
      );
      return;
    }

    final name = order.customerName ?? 'cliente';
    final code = order.pickupCode;
    final message = settingsState.renderTemplate(templateKey,
        name: name, code: code);
    if (message.trim().isEmpty) return;

    await MessagingService.sendWhatsApp(phone: phone, message: message);
  }

  Future<void> _markReady(BuildContext context) =>
      _changeStatusAndNotify(context, OrderStatus.readyForPickup, 'ready');

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annullare ordine?'),
        content: const Text(
            'L\'ordine sarà segnato come annullato. Il cliente vedrà lo stato cambiato.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sì, annulla')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _changeStatusAndNotify(
          context, OrderStatus.cancelled, 'cancelled');
    }
  }

  void _showMessageSheet(BuildContext context, {String? prefillTemplate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageSheet(
        order: order,
        prefillTemplateKey: prefillTemplate,
      ),
    );
  }
}

class _QuoteForm extends StatefulWidget {
  final CustomerOrder order;
  final SilvestrePalette palette;
  const _QuoteForm({required this.order, required this.palette});

  @override
  State<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends State<_QuoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _eta = TextEditingController();
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    _eta.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final amount = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    try {
      await ordersState.sendQuote(
        orderId: widget.order.id,
        amount: amount,
        eta: _eta.text.trim(),
        operatorNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      // Auto-apre WhatsApp col messaggio preventivo che include il codice unico
      final code = widget.order.pickupCode;
      final name = widget.order.customerName ?? 'cliente';
      final note = _note.text.trim().isEmpty
          ? ''
          : '\nNota: ${_note.text.trim()}';
      final message =
          'Ciao $name, ecco il preventivo per la tua richiesta:\n\n'
          'IMPORTO: € ${amount.toStringAsFixed(2)}\n'
          'TEMPI: ${_eta.text.trim()}\n'
          'CODICE ORDINE: $code$note\n\n'
          'Per confermare apri l\'app Silvestre Fotoservizi → Lavoro Personalizzato → '
          '"Ho già un codice preventivo" → inserisci $code → paga.';
      final phone = widget.order.customerPhone ?? '';
      if (phone.isNotEmpty) {
        await MessagingService.sendWhatsApp(phone: phone, message: message);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preventivo inviato. Codice: $code')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.palette.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.request_quote_outlined,
                    color: widget.palette.primary),
                const SizedBox(width: 8),
                Text(
                  'Invia preventivo al cliente',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: widget.palette.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo (€)',
                hintText: 'Es. 45,50',
                border: OutlineInputBorder(),
                prefixText: '€ ',
              ),
              validator: (v) {
                final n = double.tryParse(
                    (v ?? '').replaceAll(',', '.').trim());
                if (n == null || n <= 0) return 'Importo non valido';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _eta,
              decoration: const InputDecoration(
                labelText: 'Tempi di consegna',
                hintText: 'Es. 3-5 giorni lavorativi',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Indica i tempi' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota per il cliente (opzionale)',
                hintText: 'Materiali utilizzati, dettagli, condizioni...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Invia preventivo'),
                onPressed: _sending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
    final btn = outlined
        ? OutlinedButton.icon(
            style: style,
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            onPressed: onPressed,
          )
        : ElevatedButton.icon(
            style: style,
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            onPressed: onPressed,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(width: double.infinity, child: btn),
    );
  }
}

class _MessageSheet extends StatefulWidget {
  final CustomerOrder order;
  final String? prefillTemplateKey;
  const _MessageSheet({required this.order, this.prefillTemplateKey});

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  late final TextEditingController _controller;
  String _selectedKey = 'ready';
  String? _customerEmail;
  bool _loadingEmail = true;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.prefillTemplateKey ?? 'ready';
    _controller = TextEditingController(text: _render(_selectedKey));
    _loadCustomerEmail();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerEmail() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.order.userId)
          .get();
      if (mounted) {
        setState(() {
          _customerEmail = snap.data()?['email'] as String?;
          _loadingEmail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  String _render(String key) => settingsState.renderTemplate(
        key,
        name: widget.order.customerName ?? 'cliente',
        code: widget.order.pickupCode,
      );

  bool get _hasPhone =>
      widget.order.customerPhone != null &&
      widget.order.customerPhone!.trim().isNotEmpty;

  bool get _hasEmail =>
      _customerEmail != null && _customerEmail!.trim().isNotEmpty;

  Future<void> _onSend(Future<bool> Function() launcher, String chan) async {
    try {
      final ok = await launcher();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '$chan aperto con messaggio pre-compilato'
              : 'Impossibile aprire $chan. App installata?'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore $chan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final templates = settingsState.settings.messageTemplates;
    final msg = _controller.text;

    return Container(
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Messaggio al cliente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              )),
          const SizedBox(height: 4),
          Text(
            widget.order.customerName ?? widget.order.userId.substring(0, 8),
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: 4),
          _ContactInfoRow(
            phone: widget.order.customerPhone,
            email: _customerEmail,
            loadingEmail: _loadingEmail,
            palette: palette,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: templates.keys.map((k) {
              final isSelected = k == _selectedKey;
              return ChoiceChip(
                label: Text(_labelFor(k)),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedKey = k;
                  _controller.text = _render(k);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Testo (modificabile)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SendButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  enabled: _hasPhone,
                  onPressed: () => _onSend(
                    () => MessagingService.sendWhatsApp(
                      phone: widget.order.customerPhone!,
                      message: msg,
                    ),
                    'WhatsApp',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SendButton(
                  icon: Icons.sms_outlined,
                  label: 'SMS',
                  color: palette.primary,
                  enabled: _hasPhone,
                  onPressed: () => _onSend(
                    () => MessagingService.sendSms(
                      phone: widget.order.customerPhone!,
                      message: msg,
                    ),
                    'SMS',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SendButton(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  color: palette.secondary,
                  enabled: _hasEmail,
                  onPressed: () => _onSend(
                    () => MessagingService.sendEmail(
                      email: _customerEmail!,
                      subject:
                          'Silvestre Fotoservizi — ordine ${widget.order.pickupCode}',
                      body: msg,
                    ),
                    'Email',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_hasPhone)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Chiama'),
                    onPressed: () => MessagingService.callPhone(
                        widget.order.customerPhone!),
                  ),
                ),
              if (_hasPhone) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copia testo'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: msg));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copiato negli appunti')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelFor(String k) => switch (k) {
        'submitted' => 'Ricevuto',
        'inProduction' => 'In lavorazione',
        'ready' => 'Pronto',
        'pickedUp' => 'Ritirato',
        _ => k,
      };
}

class _SendButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;
  const _SendButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: enabled ? onPressed : null,
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  final String? phone;
  final String? email;
  final bool loadingEmail;
  final SilvestrePalette palette;
  const _ContactInfoRow({
    required this.phone,
    required this.email,
    required this.loadingEmail,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (phone != null && phone!.isNotEmpty) {
      children.add(_chip(Icons.phone_outlined, phone!));
    }
    if (email != null && email!.isNotEmpty) {
      children.add(_chip(Icons.mail_outline, email!));
    } else if (loadingEmail) {
      children.add(_chip(Icons.mail_outline, '…'));
    }
    if (children.isEmpty) {
      return Text('Nessun contatto disponibile',
          style: TextStyle(
              color: palette.error, fontSize: 12, fontStyle: FontStyle.italic));
    }
    return Wrap(spacing: 8, runSpacing: 4, children: children);
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.textSecondary),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
