import 'package:flutter/material.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// Pop-over shown above a selected past session: emoji marker + edit + delete.
///
/// Mirrors the floating action card from the (now-removed) standalone
/// timeline page. Lives on Home since the timeline is embedded there.
class SessionActions extends StatelessWidget {
  const SessionActions({
    required this.session,
    required this.now,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Session session;
  final DateTime now;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final emoji = session.kind == ActivityKind.walking ? '👟' : '🧑‍💻';
    final title = session.kind == ActivityKind.walking ? 'Walking' : 'Working';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: text.titleMedium),
        Text(
          DurationFormatter.hhmm(session.startedAt),
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Bubble(
              color: c.surface,
              border: Border.all(color: c.success, width: 2),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: AppSpacing.xs),
            _Bubble(
              color: c.surfaceMuted,
              onTap: onEdit,
              child: AppIcons.edit(size: 18, color: c.textPrimary),
            ),
            const SizedBox(width: AppSpacing.xs),
            _Bubble(
              color: c.surfaceMuted,
              onTap: onDelete,
              child: AppIcons.trash(size: 18, color: c.danger),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.child,
    required this.color,
    this.border,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final BoxBorder? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(border: border, shape: BoxShape.circle),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}
