import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/activity/activity.dart';
import 'package:healthy_hour/src/features/home/bloc/home_bloc.dart';
import 'package:healthy_hour/src/features/home/bloc/home_event.dart';
import 'package:healthy_hour/src/features/home/bloc/home_state.dart';
import 'package:healthy_hour/src/features/home/widgets/hour_grid.dart';
import 'package:healthy_hour/src/features/home/widgets/hour_sheet.dart';
import 'package:healthy_hour/src/features/home/widgets/nudge_hero.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// Home — one thing, now.
///
/// A single ring for whichever habit is due next, two one-tap actions, and
/// today's working hours scored as a grid. Every log offers Undo for a few
/// seconds; anything older is fixed from the hour sheet.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  void _showUndo(BuildContext context, HomeUndo undo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(undo.message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                context.read<HomeBloc>().add(const HomeUndoRequested()),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (prev, next) => next.undo != null && prev.undo != next.undo,
      listener: (context, state) => _showUndo(context, state.undo!),
      builder: (context, state) {
        final isWalking = state.displayKind == ActivityKind.walking;
        final due = NudgeHero.dueNudge(state);

        return ActivityBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  child: ConstrainedBox(
                    // Min-height = viewport so the Spacers spread the
                    // sections out on tall phones; short ones scroll.
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            _Header(
                              isWalking: isWalking,
                              onOpenSettings: onOpenSettings,
                            ),
                            const Spacer(),
                            const SizedBox(height: AppSpacing.lg),
                            NudgeHero(state: state),
                            const SizedBox(height: AppSpacing.lg),
                            _QuickActions(state: state, due: due),
                            const Spacer(),
                            const SizedBox(height: AppSpacing.xl),
                            HourGrid(
                              hours: state.hours,
                              onHourTap: (hour) => showHourSheet(context, hour),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWalking, this.onOpenSettings});

  final bool isWalking;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Image.asset(
          'assets/brand/healthy_hour_logo.png',
          key: const ValueKey('healthy-hour-brand'),
          width: 42,
          height: 42,
          semanticLabel: 'Healthy Hour logo',
        ),
        const Spacer(),
        // The design system's Small button: secondary while working,
        // primary (lime) while walking.
        AppButton(
          label: 'Working Time',
          size: AppButtonSize.small,
          type: isWalking ? AppButtonType.primary : AppButtonType.secondary,
          leading: AppIcons.settings(
            size: 16,
            color: isWalking ? c.brandOn : c.textPrimary,
          ),
          onPressed: onOpenSettings,
        ),
      ],
    );
  }
}

/// The two things you can do from Home, one tap each. The button for the
/// habit the hero is asking about is the filled one; off the clock, neither.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.state, required this.due});

  final HomeState state;
  final Nudge? due;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    final isWalking = state.displayKind == ActivityKind.walking;
    final waterFirst = due == Nudge.water ||
        (due == null &&
            !isWalking &&
            !state.isOffHours &&
            state.nextNudge == Nudge.water);

    // Off the clock nothing is being asked for, so nothing is filled.
    final quiet = state.isOffHours && !isWalking;
    AppButtonType type({required bool primary}) =>
        primary && !quiet ? AppButtonType.primary : AppButtonType.secondary;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppButton(
          key: const ValueKey('walk-action'),
          label: isWalking ? 'Back to work' : 'Start walk',
          type: type(primary: !waterFirst),
          leading: Text(
            isWalking ? '🧑‍💻' : '👟',
            style: const TextStyle(fontSize: 16),
          ),
          onPressed: () => bloc.add(
            HomeSwitchActivityRequested(
              to: isWalking ? ActivityKind.working : ActivityKind.walking,
            ),
          ),
        ),
        AppButton(
          key: const ValueKey('water-action'),
          label: 'Drank water',
          type: type(primary: waterFirst),
          leading: const Text('💧', style: TextStyle(fontSize: 16)),
          onPressed: () => bloc.add(const HomeDrinkLogged()),
        ),
      ],
    );
  }
}
