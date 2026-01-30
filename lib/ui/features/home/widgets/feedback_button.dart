import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

class FeedbackButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FeedbackButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : AppTheme.pillUnselected,
            width: 1.8,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: AppTheme.pillTextStyle.copyWith(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
