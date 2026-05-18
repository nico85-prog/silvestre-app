import 'package:flutter/material.dart';
import '../data/mock_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/store_info_banner.dart';
import 'category_products_screen.dart';
import 'custom_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _categoriesKey = GlobalKey();

  void _scrollToCategories() {
    final ctx = _categoriesKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroBanner(onStartPressed: _scrollToCategories),
        const SizedBox(height: 20),
        Text(
          'Cosa vuoi creare oggi?',
          key: _categoriesKey,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Scegli un prodotto e parti dalle tue foto',
          style: TextStyle(color: palette.textSecondary),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: MockCatalog.categories.length,
          itemBuilder: (context, i) {
            final c = MockCatalog.categories[i];
            return CategoryCard(
              title: c.name,
              subtitle: c.tagline,
              icon: c.icon,
              imageSeed: 'cat_${c.id}_$i',
              categoryId: c.id,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryProductsScreen(category: c),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        _CustomRequestCard(palette: palette),
        const SizedBox(height: 24),
        const StoreInfoBanner(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CustomRequestCard extends StatelessWidget {
  final SilvestrePalette palette;
  const _CustomRequestCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomRequestScreen()),
      ),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              palette.primary.withValues(alpha: 0.18),
              palette.secondary.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: palette.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_fix_high,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lavoro personalizzato',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Non trovi quello che cerchi? Descrivilo a noi: '
                    'ti rispondiamo con un preventivo su misura.',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: palette.primary),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onStartPressed;
  const _HeroBanner({required this.onStartPressed});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.primary, palette.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Da oltre 50 anni\nstampiamo i tuoi ricordi',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ordini in app, ritiro a Frattamaggiore in 24-48h',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: palette.primaryDark,
                  ),
                  onPressed: onStartPressed,
                  child: const Text('Inizia ora'),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/brand/silvestre_logo.jpg',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
