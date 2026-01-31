import 'package:flutter/material.dart';
import '../../../../domain/models/emotion.dart';
import 'emotion_chip.dart';

class EmotionSelector extends StatelessWidget {
  final Emotion? selectedEmotion;
  final ValueChanged<Emotion> onEmotionSelected;

  const EmotionSelector({
    super.key,
    required this.selectedEmotion,
    required this.onEmotionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final emotions = Emotion.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final crossAxisCount = maxWidth >= 560 ? 3 : 2;
        final childAspectRatio = maxWidth >= 560 ? 3.6 : 3.2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 28,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: emotions.map((emotion) {
            return EmotionChip(
              label: emotion.label,
              isSelected: selectedEmotion != null && emotion == selectedEmotion,
              onTap: () => onEmotionSelected(emotion),
            );
          }).toList(),
        );
      },
    );
  }
}
