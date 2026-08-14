import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../utils/period_filter.dart';

/// Barre horizontale de filtres par période (chips).
class PeriodFilterBar extends StatelessWidget {
  const PeriodFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kPeriodFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final option = kPeriodFilters[i];
          final isSelected = selected == option.id;
          return FilterChip(
            label: Text(
              option.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? KatianColors.red : ext.textPrimary,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KatianTheme.buttonBorderRadius),
            ),
            selected: isSelected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            selectedColor: KatianColors.redLight,
            backgroundColor: ext.surface,
            side: BorderSide(
              color: isSelected ? KatianColors.red : ext.border,
            ),
            onSelected: (_) => onChanged(option.id),
          );
        },
      ),
    );
  }
}
