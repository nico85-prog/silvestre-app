import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../state/orders_state.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_picker_sheet.dart';
import '../widgets/notification_permission_banner.dart';
import '../widgets/verification_banner.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _tab = 0;
  final List<int> _tabHistory = [];

  final _tabs = const [HomeScreen(), OrdersScreen(), AccountScreen()];

  void _switchTab(int i) {
    if (i == _tab) return;
    setState(() {
      _tabHistory.add(_tab);
      _tab = i;
    });
  }

  void _goBack() {
    if (_tabHistory.isEmpty) return;
    setState(() => _tab = _tabHistory.removeLast());
  }

  @override
  void initState() {
    super.initState();
    final user = authState.currentUser;
    if (user != null) {
      ordersState.watchForUser(user.id);
    }
  }

  @override
  void dispose() {
    ordersState.stopWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: _tabHistory.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Indietro',
                onPressed: _goBack,
              ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/brand/silvestre_logo.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text('Silvestre',
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text(
              'Fotoservizi',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambia tema',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => ThemePickerSheet.show(context),
          ),
          _CartBadgeButton(palette: palette),
        ],
      ),
      body: Column(
        children: [
          const EmailVerificationBanner(),
          const NotificationPermissionBanner(),
          Expanded(child: IndexedStack(index: _tab, children: _tabs)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Catalogo'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Ordini'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }
}

class _CartBadgeButton extends StatelessWidget {
  final SilvestrePalette palette;
  const _CartBadgeButton({required this.palette});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartState,
      builder: (context, _) {
        final count = cartState.itemCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
