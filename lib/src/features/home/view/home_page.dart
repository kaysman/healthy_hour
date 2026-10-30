import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/activity/activity.dart';
import 'package:healthy_hour/src/features/home/bloc/home_bloc.dart';
import 'package:healthy_hour/src/features/home/bloc/home_event.dart';
import 'package:healthy_hour/src/features/home/bloc/home_state.dart';
import 'package:healthy_hour/src/features/home/widgets/activity_hero.dart';
import 'package:healthy_hour/src/features/home/widgets/session_actions.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// Home screen — current activity, switch CTA, embedded ruler-style timeline
/// (scrollable past + locked-future preview), and Water / Walking cards.
///
/// The timeline used to be a separate `/timeline` route; it now lives on Home
/// directly. Tapping a past session bar selects it and animates a small
/// actions card in above the strip with edit / delete affordances.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.onOpenSettings,
    this.onOpenWaterConfig,
    this.onOpenWalkingConfig,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenWaterConfig;
  final VoidCallback? onOpenWalkingConfig;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Whether the floating SessionActions card is shown. Hidden the moment the
  /// user starts scrolling the timeline; re-shown when they tap a new bar.
  bool _showActions = true;

  /// Drives the timeline's horizontal scroll. Used both for the initial
  /// "anchor Now to right edge" jump and the per-tap "centre on selected
  /// segment" animation.
  final ScrollController _scroll = ScrollController();

  /// Guards the initial right-edge anchor so it only fires once.
  bool _didAnchorNowToRight = false;

  /// Whether the next ScrollStartNotification is the result of a programmatic
  /// scroll (centring on a tap) and should not dismiss the actions card.
  bool _ignoreNextScrollStart = false;

  /// Cached layout values written from the LayoutBuilder. Used by selection
  /// callbacks (which run outside the LayoutBuilder context) to compute
  /// where to scroll.
  double? _viewportWidth;
  DateTime? _trackStart;
  double? _minutesPerPixel;

  /// Edge padding used by [TimelineTrack] — re-exposed here so scroll-offset
  /// math (centring on a selected session) accounts for the leading inset.
  static const double _edgePad = TimelineTrack.edgePad;

  /// Discrete zoom levels — each is `(visibleMinutes, pastMinutes)`.
  /// Pinch interpolates between them; release snaps to the nearest. The
  /// finest level shows ten minutes across the viewport so a 2-minute
  /// session is still legibly tappable.
  static const List<(int visibleMinutes, int pastMinutes)> _zoomLevels = [
    (10, 60),
    (30, 180),
    (60, 240),
    (180, 480),
    (360, 720),
    (720, 1080),
    (1440, 1440),
  ];

  /// Default = 3 h (180 min) visible / 8 h (480 min) scrollable past.
  static const int _defaultZoomLevel = 3;

  /// Current zoom level index into [_zoomLevels].
  int _zoomLevel = _defaultZoomLevel;

  /// Cumulative scale during an in-flight pinch; 1.0 when idle. Drives a
  /// *continuous* zoom — every update rebuilds the layout so the ruler
  /// tracks the user's fingers in real time, then snaps to the nearest
  /// discrete level on release.
  double _pinchScale = 1;

  /// True once the active gesture has crossed into multi-finger territory.
  /// Single-finger drags reach `onScaleUpdate` too; this gate keeps them
  /// out of the pinch flow so the inner Scrollable still owns panning.
  bool _pinchActive = false;

  /// Time under the focal point at the moment the pinch became active.
  /// Used to keep that exact moment pinned at the same screen X across
  /// every rebuild the pinch causes — without this, content slides out
  /// from under the user's fingers as `minutesPerPixel` changes.
  DateTime? _pinchFocalTime;

  /// Local X (relative to the timeline) of the pinch focal point. Captured
  /// once at pinch start; we treat the user as zooming around a stable
  /// anchor rather than re-aiming mid-gesture.
  double _pinchFocalLocalX = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _pinchScale = 1;
    _pinchActive = false;
    _pinchFocalTime = null;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Single-finger drags reach this handler too — they belong to the
    // inner Scrollable, so ignore them.
    if (details.pointerCount < 2) return;

    if (!_pinchActive) {
      _pinchActive = true;
      _pinchFocalLocalX = details.localFocalPoint.dx;
      if (_trackStart != null &&
          _minutesPerPixel != null &&
          _scroll.hasClients) {
        final contentX = _scroll.offset + _pinchFocalLocalX - _edgePad;
        _pinchFocalTime = _trackStart!.add(
          Duration(minutes: (contentX * _minutesPerPixel!).round()),
        );
      }
    }

    if ((details.scale - _pinchScale).abs() < 0.001) return;
    setState(() => _pinchScale = details.scale);
    _scheduleAnchorFocalToScreen();
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!_pinchActive) {
      _pinchScale = 1;
      return;
    }
    // Snap to the discrete level whose visibleMinutes best matches what
    // the user was looking at at release.
    final base = _zoomLevels[_zoomLevel];
    final effectiveVisibleMinutes = base.$1 / _pinchScale;
    var newLevel = 0;
    var bestDelta = double.infinity;
    for (var i = 0; i < _zoomLevels.length; i++) {
      final delta = (_zoomLevels[i].$1 - effectiveVisibleMinutes).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        newLevel = i;
      }
    }
    setState(() {
      _zoomLevel = newLevel;
      _pinchScale = 1;
      _pinchActive = false;
    });
    // Keep the focal moment pinned across the snap. The schedule captures
    // the focal locally, so it's safe to clear the field afterwards.
    _scheduleAnchorFocalToScreen();
    _pinchFocalTime = null;
  }

  /// After the next layout, jump scroll so [_pinchFocalTime] sits under
  /// [_pinchFocalLocalX] at the freshly computed `minutesPerPixel`. No-op
  /// if any of the inputs are missing.
  void _scheduleAnchorFocalToScreen() {
    final focal = _pinchFocalTime;
    if (focal == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scroll.hasClients ||
          _minutesPerPixel == null ||
          _trackStart == null) {
        return;
      }
      final contentX =
          focal.difference(_trackStart!).inMinutes / _minutesPerPixel!;
      final target = (contentX + _edgePad - _pinchFocalLocalX).clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      );
      if ((target - _scroll.offset).abs() > 0.5) {
        _scroll.jumpTo(target);
      }
    });
  }

  void _onScrollStart() {
    if (_ignoreNextScrollStart) {
      _ignoreNextScrollStart = false;
      return;
    }
    if (_showActions) {
      setState(() => _showActions = false);
    }
  }

  void _onSelectionChanged(String? id, HomeState state) {
    if (id == null) return;

    Session? session;
    for (final s in state.todaysSessions) {
      if (s.id == id) {
        session = s;
        break;
      }
    }
    if (session == null) return;

    final endedAt = session.endedAt ?? state.now;
    final sessionMinutes =
        endedAt.difference(session.startedAt).inSeconds / 60.0;
    // Anchor on the midpoint so live and short sessions land centered with
    // context on either side instead of flush against a viewport edge.
    final midpoint = session.startedAt.add(
      Duration(seconds: endedAt.difference(session.startedAt).inSeconds ~/ 2),
    );

    // Smart zoom: when the session is hard to read at the current zoom —
    // too tiny (<10% of viewport) or close to filling it (>70%) — pick the
    // smallest level that gives the session ~50% width, leaving context on
    // each side. Sessions that already sit comfortably get only re-centred.
    var zoomChanged = false;
    if (_minutesPerPixel != null && _viewportWidth != null) {
      final currentVisible = _viewportWidth! * _minutesPerPixel!;
      final fraction = sessionMinutes / currentVisible;
      if (fraction < 0.1 || fraction > 0.7) {
        const maxFraction = 0.5;
        final minVisible = sessionMinutes / maxFraction;
        var bestLevel = _zoomLevels.length - 1;
        for (var i = 0; i < _zoomLevels.length; i++) {
          if (_zoomLevels[i].$1 >= minVisible) {
            bestLevel = i;
            break;
          }
        }
        if (bestLevel != _zoomLevel) {
          setState(() => _zoomLevel = bestLevel);
          zoomChanged = true;
        }
      }
    }

    void centerOn(DateTime t, {required bool animate}) {
      if (_trackStart == null ||
          _minutesPerPixel == null ||
          _viewportWidth == null ||
          !_scroll.hasClients) {
        return;
      }
      final markerX =
          t.difference(_trackStart!).inMinutes / _minutesPerPixel! + _edgePad;
      final target = (markerX - _viewportWidth! / 2).clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      );
      if ((target - _scroll.offset).abs() <= 0.5) return;
      _ignoreNextScrollStart = true;
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(target);
      }
    }

    if (zoomChanged) {
      // Layout shifts with the new zoom — wait one frame, then jump.
      // Animating from the stale post-rebuild offset would slide through
      // a meaningless intermediate position.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        centerOn(midpoint, animate: false);
      });
    } else {
      centerOn(midpoint, animate: true);
    }

    if (!_showActions) {
      setState(() => _showActions = true);
    }
  }

  /// Schedules a one-shot jump that anchors `now` to the right edge of the
  /// viewport. Past activity reaches off-screen to the left; the future is a
  /// small dim buffer to the right. Idempotent across rebuilds.
  void _scheduleAnchorNowToRight() {
    if (_didAnchorNowToRight) return;
    _didAnchorNowToRight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _onSwitchActivity() {
    context.read<HomeBloc>().add(const HomeSwitchActivityRequested());
  }

  void _onStartWalk() {
    context
        .read<HomeBloc>()
        .add(const HomeSwitchActivityRequested(to: ActivityKind.walking));
  }

  void _onLogDrink() {
    context.read<HomeBloc>().add(const HomeDrinkLogged());
  }

  Future<void> _onEditSession(Session s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(s.startedAt),
    );
    if (picked == null) return;
    final newStart = DateTime(
      s.startedAt.year,
      s.startedAt.month,
      s.startedAt.day,
      picked.hour,
      picked.minute,
    );
    if (!mounted) return;
    context
        .read<HomeBloc>()
        .add(HomeSessionEdited(s.copyWith(startedAt: newStart)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (prev, next) => prev.selectedId != next.selectedId,
      listener: (context, state) =>
          _onSelectionChanged(state.selectedId, state),
      builder: (context, state) {
        final c = context.colors;

        final isWalking = state.displayKind == ActivityKind.walking;
        final selected = state.selected;
        final showActions = selected != null && _showActions;

        return ActivityBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              // Outer LayoutBuilder gives us the viewport width once so the
              // timeline section can derive minutesPerPixel without an inner
              // LayoutBuilder (which doesn't play well with IntrinsicHeight).
              child: LayoutBuilder(
                builder: (context, viewport) {
                  // ~3 hours of width per viewport. Past stretches 8h back
                  // (scrollable). Future is a 30-min "locked" buffer.
                  // Visible / scrollable hours come from the active zoom
                  // level; pinch-to-zoom on the strip cycles through them.
                  final zoom = _zoomLevels[_zoomLevel];
                  // Continuous pinch: visibleMinutes interpolates off the
                  // active discrete level by [_pinchScale] (1 when idle),
                  // so the ruler scales smoothly under the user's fingers.
                  final visibleMinutes = zoom.$1 / _pinchScale;
                  final pastMinutes = zoom.$2;
                  const futureBuffer = Duration(minutes: 30);
                  const sessionLeadIn = Duration(minutes: 30);
                  final minutesPerPixel = visibleMinutes / viewport.maxWidth;
                  final defaultStart =
                      state.now.subtract(Duration(minutes: pastMinutes));
                  // Auto-extend the past edge so the oldest session is always
                  // fully visible at the default scroll position.
                  DateTime? oldestStart;
                  for (final s in state.todaysSessions) {
                    if (oldestStart == null ||
                        s.startedAt.isBefore(oldestStart)) {
                      oldestStart = s.startedAt;
                    }
                  }
                  final trackStart = (oldestStart != null &&
                          oldestStart.isBefore(defaultStart))
                      ? oldestStart.subtract(sessionLeadIn)
                      : defaultStart;
                  final trackEnd = state.now.add(futureBuffer);

                  _viewportWidth = viewport.maxWidth;
                  _trackStart = trackStart;
                  _minutesPerPixel = minutesPerPixel;
                  _scheduleAnchorNowToRight();

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      // Min-height = viewport so the Spacer below still
                      // pushes the bottom group down when content fits.
                      // When SessionActions appears and content overflows,
                      // the SingleChildScrollView gracefully scrolls.
                      constraints:
                          BoxConstraints(minHeight: viewport.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top section: title + status pill, hero, primary
                            // CTA. Gets page-level horizontal padding.
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Row(
                                        key: const ValueKey(
                                          'healthy-hour-brand',
                                        ),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            'assets/brand/healthy_hour_logo.png',
                                            width: 42,
                                            height: 42,
                                            semanticLabel: 'Healthy Hour logo',
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      PillBadge(
                                        label: 'Working Time',
                                        tone: isWalking
                                            ? PillTone.brand
                                            : PillTone.neutral,
                                        leading: AppIcons.settings(
                                          size: 14,
                                          color: isWalking
                                              ? c.brandOn
                                              : c.textPrimary,
                                        ),
                                        onTap: widget.onOpenSettings,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  ActivityHero(
                                    kind: state.displayKind,
                                    duration: state.currentDuration,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  AppButton(
                                    label: isWalking
                                        ? 'Continue working'
                                        : 'Have a walk',
                                    leading: Text(
                                      isWalking ? '🧑‍💻' : '👟',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    onPressed: _onSwitchActivity,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),

                            // SessionActions: animates in/out as selection changes or
                            // the user scrolls.
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) {
                                return FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.7, end: 1)
                                        .animate(anim),
                                    alignment: Alignment.bottomCenter,
                                    child: child,
                                  ),
                                );
                              },
                              child: showActions
                                  ? Padding(
                                      key: ValueKey('actions-${selected.id}'),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: SessionActions(
                                        session: selected,
                                        now: state.now,
                                        onEdit: () => _onEditSession(selected),
                                        onDelete: () =>
                                            context.read<HomeBloc>().add(
                                                  HomeSessionDeleted(
                                                    selected.id,
                                                  ),
                                                ),
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('actions-none'),
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Embedded interactive timeline.
                            // Single-finger drag pans; multi-finger
                            // pinch zooms continuously around the
                            // focal point and snaps to the nearest
                            // discrete level on release. Uses a
                            // greedy scale recognizer so the
                            // page-level vertical scroll can't steal
                            // two-finger pinches.
                            RawGestureDetector(
                              behavior: HitTestBehavior.opaque,
                              gestures: <Type, GestureRecognizerFactory>{
                                _GreedyScaleRecognizer:
                                    GestureRecognizerFactoryWithHandlers<
                                        _GreedyScaleRecognizer>(
                                  _GreedyScaleRecognizer.new,
                                  (instance) {
                                    instance
                                      ..onStart = _onScaleStart
                                      ..onUpdate = _onScaleUpdate
                                      ..onEnd = _onScaleEnd;
                                  },
                                ),
                              },
                              child:
                                  NotificationListener<ScrollStartNotification>(
                                onNotification: (_) {
                                  _onScrollStart();
                                  return false;
                                },
                                child: TimelineTrack(
                                  segments: [
                                    for (final s in state.todaysSessions)
                                      TimelineSegment(
                                        id: s.id,
                                        startedAt: s.startedAt,
                                        endedAt: s.endedAt,
                                        emoji: s.kind == ActivityKind.walking
                                            ? '👟'
                                            : '🧑‍💻',
                                        tone: s.kind == ActivityKind.walking
                                            ? c.walkingTint
                                            : c.workingTint,
                                      ),
                                  ],
                                  start: trackStart,
                                  end: trackEnd,
                                  now: state.now,
                                  selectedId: state.selectedId,
                                  onSelect: (id) => context
                                      .read<HomeBloc>()
                                      .add(HomeSessionSelected(id)),
                                  scrollController: _scroll,
                                  minutesPerPixel: minutesPerPixel,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Activity cards.
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ActivityCard(
                                      onConfigure: widget.onOpenWaterConfig,
                                      onAdd: _onLogDrink,
                                      body: CircularTimer(
                                        remaining: state.waterRemaining,
                                        total: state.water.interval,
                                        label: 'Water',
                                        ringColor: c.water,
                                        icon: const Text(
                                          '💧',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: ActivityCard(
                                      onConfigure: widget.onOpenWalkingConfig,
                                      // `+` starts a walk; already walking,
                                      // there's nothing to add.
                                      onAdd: isWalking ? null : _onStartWalk,
                                      body: CircularTimer(
                                        remaining: state.walkingRemaining,
                                        total: state.walking.interval,
                                        label: 'Walking',
                                        ringColor: c.walking,
                                        icon: const Text(
                                          '👟',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// `ScaleGestureRecognizer` that wins the gesture arena the moment a
/// second pointer touches down, instead of waiting for movement to cross
/// `kScaleSlop`. Without this the surrounding vertical scroll view grabs
/// the first finger and the page scrolls instead of the timeline zooming.
class _GreedyScaleRecognizer extends ScaleGestureRecognizer {
  _GreedyScaleRecognizer({super.debugOwner});

  int _trackedPointers = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _trackedPointers++;
    super.addAllowedPointer(event);
    if (_trackedPointers >= 2) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _trackedPointers = 0;
    super.didStopTrackingLastPointer(pointer);
  }
}
