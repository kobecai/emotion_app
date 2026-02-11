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
  static const double _detailMaxHeightFactor = 0.6;

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

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} · ${_formatTime(date)}';
  }

  Future<void> _showEntryOverlay(ReleaseEntry entry) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.16),
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: mediaQuery.size.width - 32,
              maxHeight: mediaQuery.size.height * _detailMaxHeightFactor,
            ),
            child: Material(
              color: Colors.white,
              elevation: 0,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateTime(entry.createdAt),
                        style: AppTheme.captionStyle.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        entry.note?.trim() ?? '',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0),
          foregroundColor: AppTheme.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
    );
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
      body: FutureBuilder<List<ReleaseEntry>>(
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
                  child: _buildDoneButton(),
                ),
              ],
            );
          }

          entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pageHorizontalPadding,
                    vertical: 16,
                  ),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _HistoryItem(
                      dateLabel: _formatDateTime(entry.createdAt),
                      note: entry.note?.trim() ?? '',
                      onTap: () => _showEntryOverlay(entry),
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
                child: _buildDoneButton(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String dateLabel;
  final String note;
  final VoidCallback onTap;

  const _HistoryItem({
    required this.dateLabel,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: AppTheme.captionStyle.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
