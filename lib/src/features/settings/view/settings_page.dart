import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/activity/activity.dart';
import 'package:healthy_hour/src/features/settings/bloc/settings_bloc.dart';
import 'package:healthy_hour/src/features/settings/bloc/settings_event.dart';
import 'package:healthy_hour/src/features/settings/bloc/settings_state.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return ActivityBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              // No M3 tint/shadow when the list scrolls under it: the
              // backdrop should read as one surface.
              scrolledUnderElevation: 0,
              elevation: 0,
              title: const Text('Adjust'),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const _SectionTitle(text: 'Working window'),
                  _WindowEditor(
                    window: state.window,
                    onChanged: (w) => context
                        .read<SettingsBloc>()
                        .add(SettingsWindowChanged(w)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle(text: 'Water reminder'),
                  _IntervalSlider(
                    value: state.water.interval,
                    onChanged: (d) => context
                        .read<SettingsBloc>()
                        .add(SettingsWaterChanged(TimerConfig(interval: d))),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle(text: 'Walking reminder'),
                  _IntervalSlider(
                    value: state.walking.interval,
                    onChanged: (d) => context
                        .read<SettingsBloc>()
                        .add(SettingsWalkingChanged(TimerConfig(interval: d))),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _WindowEditor extends StatelessWidget {
  const _WindowEditor({required this.window, required this.onChanged});

  final WorkingWindow window;
  final ValueChanged<WorkingWindow> onChanged;

  String _format(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeChip(
            label: 'Start',
            value: _format(window.startMinutes),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: window.startMinutes ~/ 60,
                  minute: window.startMinutes % 60,
                ),
              );
              if (picked == null) return;
              onChanged(
                window.copyWith(
                  startMinutes: picked.hour * 60 + picked.minute,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TimeChip(
            label: 'End',
            value: _format(window.endMinutes),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: window.endMinutes ~/ 60,
                  minute: window.endMinutes % 60,
                ),
              );
              if (picked == null) return;
              onChanged(
                window.copyWith(
                  endMinutes: picked.hour * 60 + picked.minute,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: AppRadii.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntervalSlider extends StatelessWidget {
  const _IntervalSlider({required this.value, required this.onChanged});

  final Duration value;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final minutes = value.inMinutes.clamp(5, 90);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Every $minutes minutes',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          min: 5,
          max: 90,
          divisions: 17,
          value: minutes.toDouble(),
          onChanged: (v) => onChanged(Duration(minutes: v.round())),
        ),
      ],
    );
  }
}
