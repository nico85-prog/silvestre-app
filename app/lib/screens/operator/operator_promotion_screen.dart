import 'package:flutter/material.dart';
import '../../state/marketing_contacts_state.dart';
import '../../state/promotions_state.dart';
import '../../theme/app_theme.dart';
import 'new_promotion_screen.dart';
import 'promotion_tabs/tab_logica_gdpr.dart';
import 'promotion_tabs/tab_tutti.dart';
import 'promotion_tabs/tab_acconsentiti.dart';
import 'promotion_tabs/tab_nuovi.dart';
import 'promotion_tabs/tab_in_attesa.dart';
import 'promotion_tabs/tab_rifiutati.dart';

/// Pannello operatore "Crea Promozione" — 6 tab in ordine:
///   1. Logica & GDPR (documentazione + stats)
///   2. 👥 Tutti (action surface principale: bottoni OPT IN / SI / STOP /
///      reset / NO RESET per riga)
///   3. 🟢 Acconsentiti (read-only)
///   4. ⚪ Nuovi (read-only)
///   5. 🟡 In attesa (read-only)
///   6. 🔴 Rifiutati (read-only)
///
/// Pulsante "+ NUOVA PROMOZIONE" in AppBar actions (alto a destra)
/// apre form per promo standard.
class OperatorPromotionScreen extends StatefulWidget {
  const OperatorPromotionScreen({super.key});

  @override
  State<OperatorPromotionScreen> createState() =>
      _OperatorPromotionScreenState();
}

class _OperatorPromotionScreenState extends State<OperatorPromotionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 6, vsync: this);

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
    return AnimatedBuilder(
      animation: marketingContactsState,
      builder: (context, _) {
        final s = marketingContactsState;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Crea Promozione'),
            actions: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'NUOVA PROMOZIONE',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewPromotionScreen(),
                    ),
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: palette.primary,
              unselectedLabelColor: palette.textSecondary,
              indicatorColor: palette.primary,
              tabs: [
                const Tab(
                    icon: Icon(Icons.gavel), text: 'Logica & GDPR'),
                Tab(text: '👥 Tutti (${s.totalCount})'),
                Tab(text: '🟢 Acconsentiti (${s.optedInCount})'),
                Tab(text: '⚪ Nuovi (${s.newCount})'),
                Tab(text: '🟡 In attesa (${s.awaitingCount})'),
                Tab(text: '🔴 Rifiutati (${s.rejectedCount})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              PromoTabLogicaGdpr(palette: palette),
              PromoTabTutti(palette: palette),
              PromoTabAcconsentiti(palette: palette),
              PromoTabNuovi(palette: palette),
              PromoTabInAttesa(palette: palette),
              PromoTabRifiutati(palette: palette),
            ],
          ),
        );
      },
    );
  }
}
