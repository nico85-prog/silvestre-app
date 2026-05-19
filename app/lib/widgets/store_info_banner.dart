import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StoreInfoBanner extends StatelessWidget {
  const StoreInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, color: palette.primary),
              const SizedBox(width: 8),
              Text(
                'Il tuo negozio',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'dal 1970',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(Icons.location_on_outlined,
              'Via Vittorio Emanuele III, 205\n80027 Frattamaggiore (NA)'),
          const SizedBox(height: 8),
          _InfoRow(Icons.phone_outlined, '+39 347 826 0320'),
          const SizedBox(height: 8),
          _InfoRow(Icons.access_time, 'Lun-Sab 09:00 — 13:00'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: palette.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: palette.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
