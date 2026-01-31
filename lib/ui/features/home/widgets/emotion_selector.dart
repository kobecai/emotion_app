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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 28,
      crossAxisSpacing: 12,
      childAspectRatio: 3.2,
      children: emotions.map((emotion) {
        return EmotionChip(
          label: emotion.label,
          isSelected: selectedEmotion != null && emotion == selectedEmotion,
          onTap: () => onEmotionSelected(emotion),
        );
      }).toList(),
    );
  }
}
