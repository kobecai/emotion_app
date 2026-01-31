import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../data/local/release_storage.dart';
import '../../../../domain/models/release_entry.dart';
import '../../../core/themes/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int _autoExitDelayMs = 3000;
  Timer? _autoExitTimer;

  @override
  void initState() {
    super.initState();
    _scheduleAutoExit();
  }

  @override
  void dispose() {
    _autoExitTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoExit() {
    _autoExitTimer?.cancel();
    _autoExitTimer = Timer(const Duration(milliseconds: _autoExitDelayMs), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  void _onUserInteraction() {
    _scheduleAutoExit();
  }

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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your moments'),
        elevation: 0,
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Listener(
        onPointerDown: (_) => _onUserInteraction(),
        onPointerMove: (_) => _onUserInteraction(),
        child: FutureBuilder<List<ReleaseEntry>>(
          future: ReleaseStorage().loadEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = (snapshot.data ?? [])
                .where((entry) => (entry.note?.trim() ?? '').isNotEmpty)
                .toList();
            if (entries.isEmpty) {
              return Column(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Nothing here yet.',
                        style: AppTheme.bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppTheme.pageHorizontalPadding,
                      right: AppTheme.pageHorizontalPadding,
                      top: 24,
                      bottom: 24 + bottomInset,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE0E0E0),
                          foregroundColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final grouped = <String, List<ReleaseEntry>>{};
            for (final entry in entries) {
              final key = _formatDate(entry.createdAt);
              grouped.putIfAbsent(key, () => []).add(entry);
            }
            final sections = grouped.entries.toList();

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.pageHorizontalPadding,
                      vertical: 16,
                    ),
                    itemCount: sections.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _HistorySection(
                        dateLabel: section.key,
                        entries: section.value,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: AppTheme.pageHorizontalPadding,
                    right: AppTheme.pageHorizontalPadding,
                    top: 24,
                    bottom: 24 + bottomInset,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String dateLabel;
  final List<ReleaseEntry> entries;

  const _HistorySection({required this.dateLabel, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              entry.note?.trim() ?? '',
              style: AppTheme.bodyStyle.copyWith(color: AppTheme.textPrimary),
            ),
          );
        }),
      ],
    );
  }
}
