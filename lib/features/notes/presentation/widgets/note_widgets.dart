import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/note.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: AppColors.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'OFFLINE MODE ACTIVE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: .7,
                ),
              ),
            ),
            Text(
              'Saving to local cache',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineBottomNavigation extends StatelessWidget {
  const OfflineBottomNavigation({required this.selectedIndex, super.key});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const items = [
      (
        Icons.description_outlined,
        Icons.description_rounded,
        'Notes',
        '/notes',
      ),
      (Icons.search_outlined, Icons.search_rounded, 'Search', '/notes/search'),
      (
        Icons.settings_outlined,
        Icons.settings_rounded,
        'Settings',
        '/settings',
      ),
    ];
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var index = 0; index < items.length; index++)
                Semantics(
                  selected: selectedIndex == index,
                  button: true,
                  label: items[index].$3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.go(items[index].$4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selectedIndex == index
                            ? colors.secondaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedIndex == index
                                ? items[index].$2
                                : items[index].$1,
                            size: 24,
                            color: selectedIndex == index
                                ? colors.onSecondaryContainer
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[index].$3,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: selectedIndex == index
                                      ? colors.onSecondaryContainer
                                      : colors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({required this.status, super.key});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, background, foreground) = switch (status) {
      SyncStatus.synced => (
        'SYNCED',
        Icons.check_circle_rounded,
        AppColors.primaryContainer,
        AppColors.onPrimaryContainer,
      ),
      SyncStatus.pending => (
        'PENDING',
        Icons.cloud_upload_rounded,
        AppColors.tertiaryContainer,
        AppColors.onTertiaryContainer,
      ),
      SyncStatus.conflict => (
        'CONFLICT',
        Icons.warning_rounded,
        AppColors.errorContainer,
        AppColors.onErrorContainer,
      ),
    };
    return Semantics(
      label: 'Sync status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: foreground,
                letterSpacing: -.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, required this.onTap, super.key});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final railColor = switch (note.status) {
      SyncStatus.synced => AppColors.primaryContainer,
      SyncStatus.pending => AppColors.tertiary,
      SyncStatus.conflict => AppColors.error,
    };
    final statusIcon = switch (note.status) {
      SyncStatus.synced => Icons.check_circle_rounded,
      SyncStatus.pending => Icons.cloud_upload_rounded,
      SyncStatus.conflict => Icons.warning_rounded,
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: railColor),
          ),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(statusIcon, size: 18, color: railColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.body.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat.MMMd().add_jm().format(note.updatedAt),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.outline),
                      ),
                      SyncStatusBadge(status: note.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedListEntry extends StatelessWidget {
  const AnimatedListEntry({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 280 + (index * 55).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 48, color: colors.primary),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
