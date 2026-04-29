import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_radii.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_spacing.dart';
import 'package:healthy_hour_ui_kit/src/widgets/timeline_ruler.dart';

/// A single past or live session laid on the [TimelineTrack].
///
/// Unlike a point-in-time marker, a segment has a real duration and is drawn
/// as a horizontal bar between [startedAt] and [endedAt] (or [now] if the
/// segment is still running).
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

  /// Optional fill color override. If null the track uses [AppColors.surface]
  /// — a low-contrast surface that doesn't compete with the brand.
  final Color? tone;

  bool get isLive => endedAt == null;
}

/// Combined session strip + ruler used on the Timeline screen.
///
/// Layered top-to-bottom:
///
///   - **Segment row** — each session is a horizontal bar positioned by time
///     and sized by duration. The selected segment gets a green outline; the
///     live segment gets a green right edge.
///   - **Ruler card** — three-tier ruler (hour / 15-min / 5-min ticks) on a
///     muted surface. The selected line drops down through the ruler.
///   - **Now marker** — a vertical green line that ties the bar row and the
///     ruler together, with a "Now" pill above and a triangle pin on the
///     ruler baseline.
///
/// The whole strip scrolls horizontally as one unit. The right scroll edge
/// is determined by [end] — pass `now` (or `now` plus a small pad) to make
/// the future unreachable, which is what the Healthy Hour timeline does.
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
    this.barHeight = 36,
    this.rulerHeight = 56,
    this.barRowGap = AppSpacing.sm,
  });

  final List<TimelineSegment> segments;
  final DateTime start;
  final DateTime end;
  final DateTime now;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final ScrollController? scrollController;
  final double minutesPerPixel;
  final double barHeight;
  final double rulerHeight;
  final double barRowGap;

  /// Minimum visible width for any segment so single-tap targets stay usable
  /// even for very short sessions. Sized so the emoji glyph plus the bar's
  /// horizontal padding always fits — anything smaller and the inner Row
  /// overflows.
  static const double _minBarWidth = 36;

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

  /// How far the selected segment is lifted above the regular bar row. Gives
  /// it a visible pop-out so it stands clear of any neighboring bar that
  /// might otherwise overlap or sit flush against it.
  static const double _selectedLift = 24;

  double _xFor(DateTime at) =>
      at.difference(start).inMinutes / minutesPerPixel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = end.difference(start).inMinutes / minutesPerPixel;
    // The strip reserves [_selectedLift] of headroom above the bar row so the
    // selected segment can pop up without leaving the viewport.
    final totalHeight =
        _selectedLift + barHeight + barRowGap + rulerHeight;
    final showNow = !now.isBefore(start) && !now.isAfter(end);
    final futureVisible = end.isAfter(now);

    final selectedSegment = selectedId == null
        ? null
        : segments.cast<TimelineSegment?>().firstWhere(
              (s) => s?.id == selectedId,
              orElse: () => null,
            );
    final selectedX =
        selectedSegment == null ? null : _xFor(selectedSegment.startedAt);

    // Clamp the pill so its right edge stays inside the Stack.
    final nowX = showNow ? _xFor(now) : 0.0;
    final maxPillLeft = width - _nowPillWidth;
    final preferredPillLeft = nowX + _nowPillGap;
    final pillLeft = preferredPillLeft > maxPillLeft
        ? maxPillLeft.clamp(0.0, double.infinity)
        : preferredPillLeft;

    return SizedBox(
      height: totalHeight,
      // Fades anything (bars, ruler, Now line) that runs past the viewport
      // edge into transparency — a "more here, scroll for it" affordance
      // that's universally readable.
      child: ShaderMask(
        shaderCallback: (bounds) {
          final fade = _edgeFadeWidth / bounds.width;
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
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
          // Edge padding so the leftmost / rightmost moments aren't flush
          // against the viewport edge.
          padding: const EdgeInsets.symmetric(horizontal: edgePad),
          child: SizedBox(
            width: width,
            height: totalHeight,
            child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ruler card (rounded surface) — pinned to the bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: rulerHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    child: TimelineRulerCanvas(
                      start: start,
                      end: end,
                      now: now,
                      height: rulerHeight,
                      minutesPerPixel: minutesPerPixel,
                      // The track owns the Now visual itself (pill + line).
                      showNowMarker: false,
                      // Dim ticks and labels in the future region.
                      futureFrom: futureVisible ? now : null,
                    ),
                  ),
                ),
              ),

              // Selection: green vertical line from the top of the bar row
              // down through the ruler. Drawn before the bars so the
              // selected bar's outline visually sits on top of it.
              if (selectedX != null)
                Positioned(
                  left: selectedX - 0.75,
                  top: 0,
                  bottom: 0,
                  width: 1.5,
                  child: ColoredBox(color: c.success),
                ),

              // Session bars, positioned by time.
              for (final s in segments) _positionedBar(context, s),

              // Now marker — vertical line + pill, drawn on top of bars so
              // the live session's right edge meets it cleanly.
              if (showNow) ..._buildNowMarker(context, pillLeft),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _positionedBar(BuildContext context, TimelineSegment s) {
    final c = context.colors;
    final left = _xFor(s.startedAt);
    final rawRight = _xFor(s.endedAt ?? now);
    final right =
        (rawRight - left) < _minBarWidth ? left + _minBarWidth : rawRight;
    final barWidth = right - left;

    final isSelected = s.id == selectedId;
    final isLive = s.isLive;
    final fill = s.tone ?? c.surface;

    // Render the emoji only if there's room for it inside the bar's
    // padding. Combined with [_minBarWidth] this should always be true,
    // but leaving the check here prevents accidental future regressions
    // from re-introducing the RenderFlex overflow.
    const horizontalPadding = 8.0;
    const emojiBoxWidth = 20.0;
    final showEmoji = barWidth >= (horizontalPadding * 2) + emojiBoxWidth;
    final showLiveDot = isLive && barWidth > 64;
    final radius = BorderRadius.circular(AppSpacing.sm);

    return Positioned(
      left: left,
      // Selected bars pop up to the very top of the strip; everything else
      // sits in the regular row, [_selectedLift] below.
      top: isSelected ? 0 : _selectedLift,
      width: barWidth,
      height: barHeight,
      child: GestureDetector(
        onTap: () => onSelect(s.id),
        behavior: HitTestBehavior.opaque,
        // ClipRRect guarantees no descendant can paint past the bar's
        // rounded edges, even at the minimum width.
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? c.success : c.divider,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showEmoji)
                  Text(s.emoji, style: const TextStyle(fontSize: 14)),
                if (showEmoji && showLiveDot) const SizedBox(width: 6),
                if (showLiveDot) _LiveDot(color: c.success),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNowMarker(BuildContext context, double pillLeft) {
    final c = context.colors;
    final x = _xFor(now);
    final rowTop = _selectedLift;
    return [
      // Vertical line — starts below the regular bar row and runs through
      // the ruler.
      Positioned(
        left: x - 0.75,
        top: rowTop + barHeight,
        bottom: 0,
        width: 1.5,
        child: ColoredBox(color: c.success),
      ),
      // Now pill, vertically centred on the regular (non-selected) bar row.
      // `pillLeft` is pre-clamped by the parent so it never overflows the
      // strip.
      Positioned(
        left: pillLeft,
        top: rowTop + (barHeight - 22) / 2,
        child: const _NowPill(),
      ),
    ];
  }
}

class _NowPill extends StatelessWidget {
  const _NowPill();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 22,
      width: 48,
      decoration: BoxDecoration(
        color: c.success,
        borderRadius: AppRadii.pillRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        'Now',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.background,
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
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
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
