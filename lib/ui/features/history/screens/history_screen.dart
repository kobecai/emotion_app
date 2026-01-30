import 'package:flutter/material.dart';
import '../../../../data/local/release_storage.dart';
import '../../../../domain/models/release_entry.dart';
import '../../../core/themes/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your moments'),
        elevation: 0,
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: FutureBuilder<List<ReleaseEntry>>(
        future: ReleaseStorage().loadEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'Nothing here yet.\nCome back whenever you need to let something out.',
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pageHorizontalPadding,
              vertical: 16,
            ),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryItem(entry: entry);
            },
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ReleaseEntry entry;

  const _HistoryItem({required this.entry});

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${entry.emotion.label} · ${_formatDate(entry.createdAt)}',
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.durationSeconds.toStringAsFixed(1)} seconds',
          style: AppTheme.captionStyle,
        ),
      ],
    );
  }
}
