import 'package:flutter/material.dart';
import 'package:healthy_hour/src/core/core.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/home/bloc/home_state.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// The one thing Home is about right now, as a single ring.
///
/// - **Counting down** — the habit due first, with its time left; the other
///   habit sits underneath as a single line.
/// - **Due** — the ring closes and pulses, and the copy turns into the ask.
/// - **Walking** — the walk itself: how long you've been up.
/// - **Off the clock** — outside the working window nothing is due.
class NudgeHero extends StatelessWidget {
  const NudgeHero({required this.state, super.key});

  final HomeState state;

  /// The habit Home is asking for this second, or `null` while nothing is
  /// due. Home fills that habit's button.
  static Nudge? dueNudge(HomeState state) {
    if (state.isOffHours) return null;
    if (state.displayKind == ActivityKind.walking) {
      return state.waterRemaining == Duration.zero ? Nudge.water : null;
    }
    final nudge = state.nextNudge;
    return _remaining(state, nudge) == Duration.zero ? nudge : null;
  }

  static Duration _remaining(HomeState state, Nudge nudge) => switch (nudge) {
        Nudge.walk => state.walkingRemaining,
        Nudge.water => state.waterRemaining,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isWalking = state.displayKind == ActivityKind.walking;

    if (state.isOffHours && !isWalking) {
      final opens = state.workingWindow.startOn(state.now);
      return _HeroLayout(
        progress: 0,
        color: c.textTertiary,
        emoji: '🌙',
        headline: 'Off the clock',
        caption: state.now.isBefore(opens)
            ? 'Reminders start at ${DurationFormatter.hhmm(opens)}'
            : 'Reminders resume tomorrow',
        headlineIsTime: false,
      );
    }

    if (isWalking) {
      return _HeroLayout(
        progress: 1,
        color: c.walking,
        emoji: '👟',
        headline: _clock(state.currentDuration),
        caption: 'walking',
        footer: state.isOffHours ? null : _waterLine(context),
      );
    }

    final nudge = state.nextNudge;
    final remaining = _remaining(state, nudge);
    final total = switch (nudge) {
      Nudge.walk => state.walking.interval,
      Nudge.water => state.water.interval,
    };
    final due = remaining == Duration.zero;
    final (emoji, color) = switch (nudge) {
      Nudge.walk => ('👟', c.walking),
      Nudge.water => ('💧', c.water),
    };

    return _HeroLayout(
      progress: due || total == Duration.zero
          ? 1
          : remaining.inMilliseconds / total.inMilliseconds,
      color: color,
      emoji: emoji,
      pulse: due,
      headlineIsTime: !due,
      headline: due
          ? switch (nudge) {
              Nudge.walk => 'Time to walk',
              Nudge.water => 'Time to drink',
            }
          : _clock(remaining),
      caption: due ? _dueCaption(nudge) : 'until ${nudge.name}',
      header: state.current == null
          ? null
          : '🧑‍💻 Working for ${_spoken(state.currentDuration)}',
      footer: switch (nudge) {
        Nudge.walk => _waterLine(context),
        Nudge.water => _OtherLine(
            emoji: '👟',
            text: _inOrDue('Walk', state.walkingRemaining),
          ),
      },
    );
  }

  Widget _waterLine(BuildContext context) =>
      _OtherLine(emoji: '💧', text: _inOrDue('Water', state.waterRemaining));

  String _dueCaption(Nudge nudge) {
    switch (nudge) {
      case Nudge.walk:
        return 'Sitting for ${_spoken(state.currentDuration)}';
      case Nudge.water:
        final last = state.lastDrinkAt;
        if (last == null || last.isBefore(state.now.atStartOfDay)) {
          return 'No water yet today';
        }
        return 'Last drink at ${DurationFormatter.hhmm(last)}';
    }
  }

  static String _inOrDue(String habit, Duration left) => left == Duration.zero
      ? '$habit is due'
      : '$habit in ${DurationFormatter.ms(left)}';

  /// `MM:SS`, or `H:MM:SS` once a walk passes the hour.
  static String _clock(Duration d) =>
      d.inHours > 0 ? DurationFormatter.hms(d) : DurationFormatter.ms(d);

  /// `47 min`, `1 h 12 min`.
  static String _spoken(Duration d) {
    final m = d.inMinutes % 60;
    if (d.inHours == 0) return '$m min';
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
  }
}

class _HeroLayout extends StatelessWidget {
  const _HeroLayout({
    required this.progress,
    required this.color,
    required this.emoji,
    required this.headline,
    required this.caption,
    this.headlineIsTime = true,
    this.pulse = false,
    this.header,
    this.footer,
  });

  final double progress;
  final Color color;
  final String emoji;
  final String headline;
  final String caption;
  final bool headlineIsTime;
  final bool pulse;
  final String? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          child: header == null
              ? null
              : Text(
                  header!,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Pulse(
          active: pulse,
          child: ProgressRing(
            progress: progress,
            color: color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    headline,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: headlineIsTime ? 48 : 26,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(height: 22, child: footer),
      ],
    );
  }
}

/// The habit that isn't the hero, as one quiet line.
class _OtherLine extends StatelessWidget {
  const _OtherLine({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A slow breathe while a nudge is due. Holds still when the platform asks
/// for reduced motion.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1, end: 1.04)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animate && _controller.value != 0) {
      _controller.animateBack(0, duration: const Duration(milliseconds: 200));
    } else if (!animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
