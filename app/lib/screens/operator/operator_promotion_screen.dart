import 'package:flutter/material.dart';
import '../../state/marketing_contacts_state.dart';
import '../../state/promotions_state.dart';
import '../../theme/app_theme.dart';
import 'new_promotion_screen.dart';
import 'promotion_tabs/tab_logica_gdpr.dart';
import 'promotion_tabs/tab_acconsentiti.dart';
import 'promotion_tabs/tab_nuovi.dart';
import 'promotion_tabs/tab_in_attesa.dart';
import 'promotion_tabs/tab_rifiutati.dart';

/// Pannello operatore "Crea Promozione" — 5 tab in ordine:
///   1. Logica & GDPR (read-only docs + stats + CTA soft opt-in + Inbox)
///   2. 🟢 Acconsentiti
///   3. ⚪ Nuovi
///   4. 🟡 In attesa
///   5. 🔴 Rifiutati
///
/// FAB "+" sempre visibile per creare una nuova promozione standard.
class OperatorPromotionScreen extends StatefulWidget {
  const OperatorPromotionScreen({super.key});

  @override
  State<OperatorPromotionScreen> createState() =>
      _OperatorPromotionScreenState();
}

class _OperatorPromotionScreenState extends State<OperatorPromotionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 5, vsync: this);

  @override
  void initState() {
    super.initState();
    marketingContactsState.watchAll();
    promotionsState.watchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            Tab(text: '🟢 Acconsentiti'),
            Tab(text: '⚪ Nuovi'),
            Tab(text: '🟡 In attesa'),
            Tab(text: '🔴 Rifiutati'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PromoTabLogicaGdpr(palette: palette),
          PromoTabAcconsentiti(palette: palette),
          PromoTabNuovi(palette: palette),
          PromoTabInAttesa(palette: palette),
          PromoTabRifiutati(palette: palette),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('NUOVA PROMOZIONE',
            style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NewPromotionScreen(),
          ),
        ),
      ),
    );
  }
}
