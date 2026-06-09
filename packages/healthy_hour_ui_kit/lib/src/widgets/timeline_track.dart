import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_radii.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_spacing.dart';
import 'package:healthy_hour_ui_kit/src/widgets/timeline_ruler.dart';

/// A single past or live session laid on the [TimelineTrack].
///
/// Has a real duration and is rendered as a horizontal colored region in
/// the tape (no separate "bar row" anymore — see [TimelineTrack]).
@immutable
class TimelineSegment {
  const TimelineSegment({
    required this.id,
    required this.startedAt,
    required this.emoji,
    this.endedAt,
    this.tone,
  });

  final String id;
  final DateTime startedAt;

  /// `null` means the segment is currently running and should extend to
  /// `now` when drawn.
  final DateTime? endedAt;
  final String emoji;

  /// Optional fill color for the segment's region in the tape. If null
  /// the track falls back to [AppColors.surface] — a low-contrast surface
  /// that doesn't compete with the brand.
  final Color? tone;

  bool get isLive => endedAt == null;
}

/// Single-row "tape" timeline. The ruler and the session strip share one
/// surface: each session is a colored fill in the lower band of the ruler
/// card, with hour labels riding above and tick marks descending through
/// the fill. Compared to a separate-bar layout this:
///
///   - removes the vertical-overflow problem (selected segments no longer
///     pop above the ruler — selection is signalled by brightness + a
///     thin success outline instead);
///   - reads as one continuous tape of the day where gaps between sessions
///     are visible as gaps in color rather than empty horizontal space;
///   - frees up vertical space on the host screen.
///
/// The whole strip scrolls horizontally as one unit. The right scroll edge
/// is determined by [end] — pass `now` (or `now` plus a small pad) to make
/// the future visually unreachable.
class TimelineTrack extends StatelessWidget {
  const TimelineTrack({
    required this.segments,
    required this.start,
    required this.end,
    required this.now,
    required this.onSelect,
    this.selectedId,
    this.scrollController,
    super.key,
    this.minutesPerPixel = 1.2,
    this.height = 64,
    this.minEmojiWidth = 48,
  });

  final List<TimelineSegment> segments;
  final DateTime start;
  final DateTime end;
  final DateTime now;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final ScrollController? scrollController;
  final double minutesPerPixel;

  /// Total vertical extent of the tape (ruler labels + ticks + fills).
  final double height;

  /// Minimum painted width of a session region for its emoji to be shown
  /// centered inside it. Below this threshold the region is still tappable
  /// and the fill still draws — only the emoji is suppressed.
  final double minEmojiWidth;

  /// Width of the rendered Now pill. Used to clamp pill placement so its
  /// right edge never overflows the Stack's bounds.
  static const double _nowPillWidth = 48;

  /// Pixel gap between the Now line and the leading edge of the Now pill.
  static const double _nowPillGap = 4;

  /// Horizontal inset applied to the scroll view so the leftmost / rightmost
  /// moments aren't flush with the viewport edge. Public so consumers that
  /// translate between data-time and scroll-offset (e.g. for centring on a
  /// selected segment) can account for it.
  static const double edgePad = AppSpacing.md;

  /// Width of the alpha fade applied at each viewport edge so any segment
  /// extending past the visible area dissolves rather than getting hard-cut.
  static const double _edgeFadeWidth = 24;

  /// Vertical center of the lower band where session emojis sit, expressed
  /// as a fraction of [height]. Picked so the emoji doesn't collide with
  /// the descending hour ticks (which end roughly at the band's top).
  static const double _emojiCenterFraction = 0.78;

  double _xFor(DateTime at) =>
      at.difference(start).inMinutes / minutesPerPixel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = end.difference(start).inMinutes / minutesPerPixel;
    final showNow = !now.isBefore(start) && !now.isAfter(end);
    final futureVisible = end.isAfter(now);

    // Clamp the pill so its right edge stays inside the Stack.
    final nowX = showNow ? _xFor(now) : 0.0;
    final maxPillLeft = width - _nowPillWidth;
    final preferredPillLeft = nowX + _nowPillGap;
    final pillLeft = preferredPillLeft > maxPillLeft
        ? maxPillLeft.clamp(0.0, double.infinity)
        : preferredPillLeft;

    return SizedBox(
      height: height,
      // Fades anything (fills, ruler, Now line) that runs past the viewport
      // edge into transparency — a "more here, scroll for it" affordance
      // that's universally readable.
      child: ShaderMask(
        shaderCallback: (bounds) {
          final fade = _edgeFadeWidth / bounds.width;
          return LinearGradient(
            colors: const [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            stops: [0, fade, 1 - fade, 1],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: edgePad),
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                child: Stack(
                  children: [
                    // 1. Colored session fills (the "tape").
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TapeFillPainter(
                          segments: segments,
                          start: start,
                          now: now,
                          minutesPerPixel: minutesPerPixel,
                          selectedId: selectedId,
                          idleColor: c.surfaceMuted,
                          successColor: c.success,
                        ),
                      ),
                    ),

                    // 2. Ruler ticks + labels — drawn over the fills so the
                    //    grid stays legible no matter the activity color.
                    Positioned.fill(
                      child: TimelineRulerCanvas(
                        start: start,
                        end: end,
                        now: now,
                        height: height,
                        minutesPerPixel: minutesPerPixel,
                        showNowMarker: false,
                        futureFrom: futureVisible ? now : null,
                      ),
                    ),

                    // 3. Tap targets + centered emojis per session.
                    for (final s in segments) ..._segmentOverlay(context, s),

                    // 4. Selection vertical line — anchors the selected
                    //    region's left edge to the eye, doubles as the
                    //    "you tapped here" affordance.
                    if (selectedId != null)
                      ..._selectionLine(context),

                    // 5. Now marker — vertical line + pill on top of all.
                    if (showNow) ..._buildNowMarker(context, pillLeft),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _segmentOverlay(BuildContext context, TimelineSegment s) {
    final left = _xFor(s.startedAt);
    final rawRight = _xFor(s.endedAt ?? now);
    final width = (rawRight - left).clamp(0.0, double.infinity);
    if (width <= 0) return const [];

    final showEmoji = width >= minEmojiWidth;
    final emojiTop = height * _emojiCenterFraction - 9;

    return [
      Positioned(
        left: left,
        top: 0,
        width: width,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(s.id),
          child: showEmoji
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: emojiTop,
                      child: s.isLive
                          ? _LivePulse(child: _emoji(s.emoji))
                          : _emoji(s.emoji),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ),
    ];
  }

  Widget _emoji(String e) =>
      Text(e, style: const TextStyle(fontSize: 14));

  List<Widget> _selectionLine(BuildContext context) {
    final selected = segments.cast<TimelineSegment?>().firstWhere(
          (s) => s?.id == selectedId,
          orElse: () => null,
        );
    if (selected == null) return const [];
    final c = context.colors;
    final x = _xFor(selected.startedAt);
    return [
      Positioned(
        left: x - 0.75,
        top: 0,
        bottom: 0,
        width: 1.5,
        child: ColoredBox(color: c.success),
      ),
    ];
  }

  List<Widget> _buildNowMarker(BuildContext context, double pillLeft) {
    final c = context.colors;
    final x = _xFor(now);
    return [
      Positioned(
        left: x - 0.75,
        top: 0,
        bottom: 0,
        width: 1.5,
        child: ColoredBox(color: c.success),
      ),
      Positioned(
        left: pillLeft,
        top: 4,
        child: const _NowPill(),
      ),
    ];
  }
}

/// Paints the colored "tape" — one filled rectangle per session, drawn in
/// the lower portion of the ruler card so hour labels stay on the muted
/// background. When a selection exists, unselected fills are dimmed toward
/// the idle color and the selected fill is outlined in the success color.
class _TapeFillPainter extends CustomPainter {
  _TapeFillPainter({
    required this.segments,
    required this.start,
    required this.now,
    required this.minutesPerPixel,
    required this.selectedId,
    required this.idleColor,
    required this.successColor,
  });

  final List<TimelineSegment> segments;
  final DateTime start;
  final DateTime now;
  final double minutesPerPixel;
  final String? selectedId;
  final Color idleColor;
  final Color successColor;

  /// Vertical fraction at which the tape starts (top of the band). Above
  /// this is reserved for hour labels.
  static const double _bandTopFraction = 0.36;

  @override
  void paint(Canvas canvas, Size size) {
    final yTop = size.height * _bandTopFraction;
    final yBottom = size.height;
    final hasSelection = selectedId != null;

    for (final s in segments) {
      final left = s.startedAt.difference(start).inMinutes / minutesPerPixel;
      final rightSrc = (s.endedAt ?? now).difference(start).inMinutes /
          minutesPerPixel;
      // Skip fully-offscreen on the right; the ScrollView clip handles
      // off-left culling cheaply enough that we don't bother here.
      if (rightSrc <= 0) continue;
      final right = rightSrc;
      if (right - left <= 0) continue;

      final isSelected = s.id == selectedId;
      var fill = s.tone ?? idleColor;
      if (hasSelection && !isSelected) {
        // Mute non-selected sessions toward the idle color so the focus
        // sits on the selected one.
        fill = Color.lerp(fill, idleColor, 0.55) ?? fill;
      }

      final rect = Rect.fromLTRB(left, yTop, right, yBottom);
      canvas.drawRect(rect, Paint()..color = fill);

      if (isSelected) {
        canvas.drawRect(
          rect.deflate(0.75),
          Paint()
            ..color = successColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TapeFillPainter old) =>
      old.segments != segments ||
      old.start != start ||
      old.now != now ||
      old.minutesPerPixel != minutesPerPixel ||
      old.selectedId != selectedId ||
      old.idleColor != idleColor ||
      old.successColor != successColor;
}

class _NowPill extends StatelessWidget {
  const _NowPill();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 18,
      width: 44,
      decoration: BoxDecoration(
        color: c.success,
        borderRadius: AppRadii.pillRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        'Now',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.background,
        ),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse({required this.child});

  final Widget child;

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}
