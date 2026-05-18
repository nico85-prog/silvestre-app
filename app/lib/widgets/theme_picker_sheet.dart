import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Scegli il tema',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cambia colori e font dell\'app',
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<SilvestreThemeSpec>(
            valueListenable: currentTheme,
            builder: (context, active, _) {
              return Column(
                children: SilvestreThemes.all.map((spec) {
                  final isActive = spec.id == active.id;
                  return _ThemeOption(
                    spec: spec,
                    isActive: isActive,
                    onTap: () {
                      currentTheme.value = spec;
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final SilvestreThemeSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: spec.palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? spec.palette.primary : palette.border,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _ColorDots(spec: spec),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: spec.palette.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.tagline,
                      style: TextStyle(
                        color: spec.palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isActive ? spec.palette.primary : palette.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDots extends StatelessWidget {
  final SilvestreThemeSpec spec;
  const _ColorDots({required this.spec});

  @override
  Widget build(BuildContext context) {
    final colors = [
      spec.palette.primary,
      spec.palette.secondary,
      spec.palette.background,
    ];
    return SizedBox(
      width: 44,
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 12.0,
              top: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
