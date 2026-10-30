import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/home/bloc/home_bloc.dart';
import 'package:healthy_hour/src/features/home/bloc/home_event.dart';
import 'package:healthy_hour/src/features/home/bloc/home_state.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// Opens the walks and drinks logged in [hour], with edit and delete.
///
/// This is where corrections live now: Undo covers the just-tapped mistake,
/// and the rare later fix is a plain list rather than a gesture on a ruler.
Future<void> showHourSheet(BuildContext context, HealthyHour hour) {
  final bloc = context.read<HomeBloc>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.background,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: HourSheet(hour: hour),
    ),
  );
}

class HourSheet extends StatelessWidget {
  const HourSheet({required this.hour, super.key});

  final HealthyHour hour;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final entries = _entriesIn(state)..sort((a, b) => a.at.compareTo(b.at));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${DurationFormatter.hhmm(hour.start)} – '
                  '${DurationFormatter.hhmm(hour.end)}',
                  style: text.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      'Nothing logged in this hour.',
                      style: text.bodyMedium,
                    ),
                  )
                else
                  for (final entry in entries) entry.build(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_Entry> _entriesIn(HomeState state) => [
        for (final d in state.todaysDrinks)
          if (!d.isBefore(hour.start) && d.isBefore(hour.end)) _Drink(d),
        for (final s in state.todaysSessions)
          if (s.kind == ActivityKind.walking &&
              s.startedAt.isBefore(hour.end) &&
              (s.endedAt ?? state.now).isAfter(hour.start))
            _Walk(s),
      ];
}

sealed class _Entry {
  DateTime get at;
  Widget build(BuildContext context, HomeState state);
}

class _Drink implements _Entry {
  _Drink(this.at);

  @override
  final DateTime at;

  @override
  Widget build(BuildContext context, HomeState state) {
    return _Row(
      emoji: '💧',
      title: 'Water',
      subtitle: DurationFormatter.hhmm(at),
      onDelete: () => context.read<HomeBloc>().add(HomeDrinkDeleted(at)),
    );
  }
}

class _Walk implements _Entry {
  _Walk(this.session);

  final Session session;

  @override
  DateTime get at => session.startedAt;

  @override
  Widget build(BuildContext context, HomeState state) {
    final end = session.endedAt;
    return _Row(
      emoji: '👟',
      title: 'Walk',
      subtitle: '${DurationFormatter.hhmm(session.startedAt)} – '
          '${end == null ? 'now' : DurationFormatter.hhmm(end)}',
      onEdit: () => _editStart(context),
      onDelete: () =>
          context.read<HomeBloc>().add(HomeSessionDeleted(session.id)),
    );
  }

  Future<void> _editStart(BuildContext context) async {
    final bloc = context.read<HomeBloc>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(session.startedAt),
    );
    if (picked == null) return;
    final s = session.startedAt;
    bloc.add(
      HomeSessionEdited(
        session.copyWith(
          startedAt:
              DateTime(s.year, s.month, s.day, picked.hour, picked.minute),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onDelete,
    this.onEdit,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit start time',
              onPressed: onEdit,
              icon: AppIcons.edit(size: 20, color: c.textPrimary),
            ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: AppIcons.trash(size: 20, color: c.danger),
          ),
        ],
      ),
    );
  }
}
