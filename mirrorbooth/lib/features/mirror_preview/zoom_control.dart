import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iPhone-style zoom control: a row of preset buttons (0.5×, 1×, 2×, …).
///
/// Tap a button to snap to that preset. Long-press any button to reveal a
/// horizontal slider directly above the row that spans [minZoom, maxZoom];
/// continue dragging without lifting the finger to scrub the zoom value. The
/// slider hides when the long-press ends.
class ZoomControl extends StatefulWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final List<double> presets;
  final ValueChanged<double> onChanged;

  const ZoomControl({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.presets,
    required this.onChanged,
  });

  @override
  State<ZoomControl> createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl> {
  bool _sliderActive = false;
  final GlobalKey _sliderKey = GlobalKey();

  static const double _sliderWidth = 240.0;
  static const double _sliderHeight = 32.0;
  static const double _sliderGap = 10.0;

  void _showSlider() {
    if (_sliderActive) return;
    HapticFeedback.selectionClick();
    setState(() => _sliderActive = true);
  }

  void _hideSlider() {
    if (!_sliderActive) return;
    setState(() => _sliderActive = false);
  }

  void _updateFromGlobal(Offset globalPos) {
    final ctx = _sliderKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(globalPos);
    final t = (local.dx / box.size.width).clamp(0.0, 1.0);
    final z = widget.minZoom + t * (widget.maxZoom - widget.minZoom);
    widget.onChanged(z);
  }

  bool _isSelected(double preset) {
    final z = widget.currentZoom;
    final presets = widget.presets;
    if (presets.length == 1) return true;
    // The smallest preset wins when the zoom is below its midpoint with the
    // next preset; the largest wins when above its midpoint with the prev.
    final i = presets.indexOf(preset);
    final lower = i > 0 ? (preset + presets[i - 1]) / 2.0 : double.negativeInfinity;
    final upper =
        i < presets.length - 1 ? (preset + presets[i + 1]) / 2.0 : double.infinity;
    return z >= lower && z < upper;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slider always present in the tree (so its RenderBox exists for
        // coordinate mapping), but invisible & non-interactive when inactive.
        AnimatedSlide(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          offset: _sliderActive ? Offset.zero : const Offset(0, 0.4),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: _sliderActive ? 1.0 : 0.0,
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: _sliderGap),
                child: _ZoomSlider(
                  key: _sliderKey,
                  width: _sliderWidth,
                  height: _sliderHeight,
                  minZoom: widget.minZoom,
                  maxZoom: widget.maxZoom,
                  value: widget.currentZoom,
                ),
              ),
            ),
          ),
        ),
        // Button row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in widget.presets) ...[
                _ZoomButton(
                  preset: p,
                  selected: _isSelected(p),
                  onTap: () => widget.onChanged(p),
                  onLongPressStart: (_) => _showSlider(),
                  onLongPressMoveUpdate: (d) => _updateFromGlobal(d.globalPosition),
                  onLongPressEnd: (_) => _hideSlider(),
                  onLongPressCancel: _hideSlider,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final double preset;
  final bool selected;
  final VoidCallback onTap;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;
  final VoidCallback onLongPressCancel;

  const _ZoomButton({
    required this.preset,
    required this.selected,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
  });

  String _formatLabel() {
    // Selected → "1×". Unselected → "1" (compact like iPhone).
    final v = preset;
    final hasFraction = (v - v.roundToDouble()).abs() > 0.05;
    final body = hasFraction ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
    return selected ? '$body×' : body;
  }

  @override
  Widget build(BuildContext context) {
    final size = selected ? 36.0 : 30.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      onLongPressCancel: onLongPressCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          _formatLabel(),
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: selected ? 12 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  final double width;
  final double height;
  final double minZoom;
  final double maxZoom;
  final double value;

  const _ZoomSlider({
    super.key,
    required this.width,
    required this.height,
    required this.minZoom,
    required this.maxZoom,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final range = (maxZoom - minZoom).abs();
    final t = range < 1e-3 ? 0.5 : ((value - minZoom) / range).clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Track ticks
          Positioned.fill(
            child: CustomPaint(painter: _SliderTicksPainter()),
          ),
          // Min/max labels
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                _format(minZoom),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                _format(maxZoom),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Thumb
          Positioned(
            left: t * (width - height) + 2,
            top: 2,
            child: Container(
              width: height - 4,
              height: height - 4,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${_format(value)}×',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(double v) {
    final hasFraction = (v - v.roundToDouble()).abs() > 0.05;
    return hasFraction ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
  }
}

class _SliderTicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;
    const count = 11;
    final usable = size.width - size.height;
    final left = size.height / 2;
    for (int i = 1; i < count - 1; i++) {
      final x = left + usable * (i / (count - 1));
      canvas.drawLine(
        Offset(x, size.height * 0.35),
        Offset(x, size.height * 0.65),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
