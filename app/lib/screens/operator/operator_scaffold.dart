import 'package:flutter/material.dart';
import '../../state/auth_state.dart';
import '../../state/operator_nav_state.dart';
import '../../state/operators_state.dart';
import '../../state/orders_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_theme.dart';
import 'operator_calendar_screen.dart';
import 'operator_dashboard.dart';
import 'operator_orders_screen.dart';
import 'operator_settings_screen.dart';

class OperatorScaffold extends StatefulWidget {
  const OperatorScaffold({super.key});

  @override
  State<OperatorScaffold> createState() => _OperatorScaffoldState();
}

class _OperatorScaffoldState extends State<OperatorScaffold> {
  final _tabs = const [
    OperatorDashboard(),
    OperatorOrdersScreen(),
    OperatorCalendarScreen(),
    OperatorSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ordersState.watchAll();
    settingsState.load();
    operatorsState.watch();
    operatorNavState.addListener(_onNavChange);
  }

  @override
  void dispose() {
    operatorNavState.removeListener(_onNavChange);
    ordersState.stopWatching();
    operatorsState.stopWatching();
    super.dispose();
  }

  void _onNavChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;
    final user = authState.currentUser!;

    return Scaffold(
      appBar: AppBar(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Silvestre',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OPERATORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: user.displayName,
            onSelected: (v) {
              if (v == 'logout') authState.logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(user.email,
                        style: TextStyle(
                            fontSize: 12, color: palette.textSecondary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Esci')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: operatorNavState.tab, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: operatorNavState.tab,
        onDestinationSelected: (i) => operatorNavState.goToTab(i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Ordini'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendario'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Impostazioni'),
        ],
      ),
    );
  }
}
