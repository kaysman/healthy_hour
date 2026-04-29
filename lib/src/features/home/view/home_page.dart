import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
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
    this.onAddWater,
    this.onOpenWalkingConfig,
    this.onAddWalking,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenWaterConfig;
  final VoidCallback? onAddWater;
  final VoidCallback? onOpenWalkingConfig;
  final VoidCallback? onAddWalking;

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

  /// Discrete zoom levels — each is `(visibleHours, pastHours)`. The
  /// timeline shows `visibleHours` of width per viewport and lets you
  /// scroll back `pastHours` total.
  static const List<(int visible, int past)> _zoomLevels = [
    (1, 4),
    (3, 8),
    (6, 12),
    (12, 18),
    (24, 24),
  ];

  /// Default = 3h visible / 8h scrollable past.
  static const int _defaultZoomLevel = 1;

  /// Current zoom level index into [_zoomLevels].
  int _zoomLevel = _defaultZoomLevel;

  /// Cumulative scale during an in-flight pinch gesture; resets at start.
  double _pinchScale = 1.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _pinchScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Only treat real pinches (≥2 fingers) as zoom — single-finger drags
    // belong to the inner Scrollable.
    if (details.pointerCount >= 2) {
      _pinchScale = details.scale;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    var newLevel = _zoomLevel;
    if (_pinchScale > 1.3 && _zoomLevel > 0) {
      // Pinch-out → zoom in (less time visible).
      newLevel = _zoomLevel - 1;
    } else if (_pinchScale < 1 / 1.3 &&
        _zoomLevel < _zoomLevels.length - 1) {
      // Pinch-in → zoom out (more time visible).
      newLevel = _zoomLevel + 1;
    }
    _pinchScale = 1.0;
    if (newLevel != _zoomLevel) {
      setState(() {
        _zoomLevel = newLevel;
        // Re-anchor Now to the right edge after the zoom changes the
        // scrollable extent.
        _didAnchorNowToRight = false;
      });
    }
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
    if (session != null &&
        _trackStart != null &&
        _minutesPerPixel != null &&
        _viewportWidth != null &&
        _scroll.hasClients) {
      final markerX = session.startedAt.difference(_trackStart!).inMinutes /
              _minutesPerPixel! +
          _edgePad;
      final target = (markerX - _viewportWidth! / 2).clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      );
      if ((target - _scroll.offset).abs() > 0.5) {
        _ignoreNextScrollStart = true;
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
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
        final text = Theme.of(context).textTheme;

        final isWalking = state.displayKind == ActivityKind.walking;
        final tint = isWalking ? c.walkingTint : c.workingTint;
        final selected = state.selected;
        final showActions = selected != null && _showActions;

        return Scaffold(
          // Gradient lives in the Scaffold body so it covers the full screen;
          // Scaffold provides the Material ancestor needed for text rendering.
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tint, c.background],
                stops: const [0, 0.55],
              ),
            ),
            child: SafeArea(
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
                  final visibleHours = zoom.$1;
                  final pastHours = zoom.$2;
                  const futureBuffer = Duration(minutes: 30);
                  const sessionLeadIn = Duration(minutes: 30);
                  final minutesPerPixel =
                      (visibleHours * 60) / viewport.maxWidth;
                  final defaultStart =
                      state.now.subtract(Duration(hours: pastHours));
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
                            Text('Healthy', style: text.titleLarge),
                            const Spacer(),
                            PillBadge(
                              label: 'Working Time',
                              tone: isWalking
                                  ? PillTone.brand
                                  : PillTone.neutral,
                              leading: AppIcons.settings(
                                size: 14,
                                color:
                                    isWalking ? c.brandOn : c.textPrimary,
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
                          type: AppButtonType.primary,
                          onPressed: () => context
                              .read<HomeBloc>()
                              .add(const HomeSwitchActivityRequested()),
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
                              onDelete: () => context
                                  .read<HomeBloc>()
                                  .add(HomeSessionDeleted(selected.id)),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('actions-none')),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Embedded interactive timeline. Pinch-to-zoom cycles
                  // discrete zoom levels; the inner Scrollable still owns
                  // single-finger horizontal pans.
                  GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onScaleEnd: _onScaleEnd,
                    child: NotificationListener<ScrollStartNotification>(
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
                            onAdd: widget.onAddWater,
                            body: CircularTimer(
                              remaining: state.water.interval,
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
                            onAdd: widget.onAddWalking,
                            body: CircularTimer(
                              remaining: state.walking.interval,
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
