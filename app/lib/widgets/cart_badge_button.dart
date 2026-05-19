import 'package:flutter/material.dart';
import '../screens/cart_screen.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';

/// Icona carrello con badge contatore. Sempre visibile in AppBar.
/// Tap → apre la schermata Carrello.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return AnimatedBuilder(
      animation: cartState,
      builder: (context, _) {
        final count = cartState.itemCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Carrello',
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
