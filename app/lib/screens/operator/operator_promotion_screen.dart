import 'package:flutter/material.dart';
import '../../state/marketing_contacts_state.dart';
import '../../theme/app_theme.dart';
import 'promotion_tabs/tab_logica_gdpr.dart';
import 'promotion_tabs/tab_crea.dart';
import 'promotion_tabs/tab_destinatari.dart';
import 'promotion_tabs/tab_esclusi.dart';

/// Pannello operatore "Crea Promozione" — 4 tab in ordine compliance-first:
///   1. Logica & GDPR (read-only docs + stats)
///   2. Crea Promozione (form + invio)
///   3. Destinatari Promozione (solo acconsentiti)
///   4. Contatti Esclusi (re-include)
class OperatorPromotionScreen extends StatefulWidget {
  const OperatorPromotionScreen({super.key});

  @override
  State<OperatorPromotionScreen> createState() =>
      _OperatorPromotionScreenState();
}

class _OperatorPromotionScreenState extends State<OperatorPromotionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 4, vsync: this);

  // Stato campagna corrente — condiviso tra Tab 2 (Crea) e Tab 3 (Destinatari).
  // Set di contactId esclusi manualmente da questa specifica campagna.
  final Set<String> _excludedFromCampaign = <String>{};

  // Form data shared with Tab 2
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  DateTime? validFrom;
  DateTime? validTo;
  final List<String> photoUrls = [];

  @override
  void initState() {
    super.initState();
    marketingContactsState.watchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    detailsController.dispose();
    costController.dispose();
    super.dispose();
  }

  void _excludeContact(String id) {
    setState(() {
      _excludedFromCampaign.add(id);
    });
  }

  void _includeContact(String id) {
    setState(() {
      _excludedFromCampaign.remove(id);
    });
  }

  void _excludeAll(Iterable<String> ids) {
    setState(() {
      _excludedFromCampaign.addAll(ids);
    });
  }

  void _includeAll(Iterable<String> ids) {
    setState(() {
      _excludedFromCampaign.removeAll(ids);
    });
  }

  void _onFormChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Promozione'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: palette.primary,
          unselectedLabelColor: palette.textSecondary,
          indicatorColor: palette.primary,
          tabs: const [
            Tab(icon: Icon(Icons.gavel), text: 'Logica & GDPR'),
            Tab(icon: Icon(Icons.edit_note), text: 'Crea'),
            Tab(icon: Icon(Icons.group), text: 'Destinatari'),
            Tab(icon: Icon(Icons.block), text: 'Esclusi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PromoTabLogicaGdpr(palette: palette),
          PromoTabCrea(
            palette: palette,
            titleController: titleController,
            detailsController: detailsController,
            costController: costController,
            validFrom: validFrom,
            validTo: validTo,
            onValidFromChanged: (v) => setState(() => validFrom = v),
            onValidToChanged: (v) => setState(() => validTo = v),
            photoUrls: photoUrls,
            onPhotosChanged: _onFormChanged,
            excludedFromCampaign: _excludedFromCampaign,
            onJumpToTab: (i) => _tabController.animateTo(i),
          ),
          PromoTabDestinatari(
            palette: palette,
            excludedIds: _excludedFromCampaign,
            onExclude: _excludeContact,
            onInclude: _includeContact,
            onExcludeAll: _excludeAll,
            onIncludeAll: _includeAll,
          ),
          PromoTabEsclusi(
            palette: palette,
            excludedIds: _excludedFromCampaign,
            onReinclude: _includeContact,
          ),
        ],
      ),
    );
  }
}
