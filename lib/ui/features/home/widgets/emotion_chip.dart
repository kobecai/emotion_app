import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

class EmotionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const EmotionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedScale(
          scale: isSelected ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.pillUnselected,
                width: 1.8,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTheme.pillTextStyle.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
