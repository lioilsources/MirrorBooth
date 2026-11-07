// App Store preview helper: renders a demo clip of the camera screen from a
// still face: the unmirrored original, flipping between left+left and
// right+right with the side toggle, browsing filters, turning the mirror axis
// (inner ring) and rotating the whole image (outer ring). The face should be
// clearly lopsided (a wink, a crooked grin) or the two sides look alike. The picture comes from the real
// composeMirrorPhoto geometry and filter shaders, the filter strip is the real
// FilterStrip widget; frames are piped straight into ffmpeg. Not part of the
// regular test suite. store/appstore/make_previews.py calls it:
//
//   PREVIEW_FACE=face.png PREVIEW_OUT=out.mp4 PREVIEW_FILTERS=pencil,comic,neon \
//     flutter test tool/store_preview_render_test.dart
//
// The last filter in PREVIEW_FILTERS stays on for the axis and rotation part.
// PREVIEW_CAPTIONS overrides the seven captions ("a|b|...", see _captions);
// PREVIEW_LOCALE (default en) picks the app language for the on-screen UI.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/core/mirror_side.dart';
import 'package:mirrorbooth/features/mirror_preview/filter_strip.dart';
import 'package:mirrorbooth/features/mirror_preview/photo_composer.dart';
import 'package:mirrorbooth/features/mirror_preview/side_toggle_button.dart';
import 'package:mirrorbooth/l10n/l10n.dart';

// 886x1920 is the 6.9" App Store preview size.
const _screen = Size(443, 960);
const _dpr = 2.0;
const _fps = 30;
// PREVIEW_SHORT=1 cuts a ~17 s clip for the App Store, where previews
// autoplay muted in search results: it opens straight on the mirrored face
// (no plain original first) and skips the image-rotation phase.
final _short = Platform.environment['PREVIEW_SHORT'] == '1';

final _seconds = _short ? 17.0 : 26.0;

final _locale = Locale(Platform.environment['PREVIEW_LOCALE'] ?? 'en');

// Same fractions as MirrorPreviewScreen.
const _outerRingDiameterFrac = 0.88;
const _innerRingDiameterFrac = 0.44;

// Phase boundaries in seconds.
final _sidesAt = _short ? 0.0 : 1.8;
final _filtersAt = _short ? 4.4 : 7.2;
final _axisAt = _short ? 10.4 : 13.2;
final _rotateAt = _short ? 15.4 : 18.8;
final _outroAt = _short ? 15.4 : 24.4;

// Side toggle taps: left from _sidesAt, then right, left, right.
final _sideTaps = _short ? [1.0, 2.2, 3.4] : [3.3, 4.8, 6.0];

const _captions =
    'Your real face|Left + left|Right + right|Pick a filter|'
    'Turn the mirror axis|Rotate the image|Mirror Booth';

double _smooth(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Piecewise smoothstep through (time, value) keys.
double _keys(double t, List<(double, double)> keys) {
  if (t <= keys.first.$1) return keys.first.$2;
  for (var i = 1; i < keys.length; i++) {
    final (t1, v1) = keys[i];
    final (t0, v0) = keys[i - 1];
    if (t <= t1) return v0 + (v1 - v0) * _smooth((t - t0) / (t1 - t0));
  }
  return keys.last.$2;
}

// Axis and rotation keyframes, relative to the start of their phase.
const _axisKeys = [(0.4, 90.0), (1.8, 20.0), (3.4, 160.0), (5.0, 90.0)];
const _rotateKeys = [(0.4, 0.0), (1.9, 50.0), (3.5, -35.0), (5.0, 0.0)];

/// One tap: the side toggle, a collection tab or a filter chip.
class _Tap {
  final double at;
  final FilterCollection? tab;
  final MirrorFilter? filter;
  const _Tap(this.at, {this.tab, this.filter});

  bool get isSide => tab == null && filter == null;
}

List<_Tap> _plan(List<MirrorFilter> filters) {
  final taps = [for (final at in _sideTaps) _Tap(at)];
  var at = _filtersAt + 0.6;
  // The strip opens on the Pretty tab, as in the app.
  var tab = FilterCollection.pretty;
  for (final f in filters) {
    if (f.collection != tab) {
      tab = f.collection!;
      taps.add(_Tap(at, tab: tab));
      at += 0.75;
    }
    taps.add(_Tap(at, filter: f));
    at += f == filters.last ? 0 : 1.3;
  }
  return taps;
}

class _Frame {
  /// Shows the plain still without the app UI.
  bool original = false;
  MirrorFilter filter = MirrorFilter.none;
  MirrorSide side = MirrorSide.left;
  double axisDeg = 90;
  double rotationDeg = 0;
  Offset? finger;
  bool pressed = false;
  String caption = '';
  ui.Image? picture;
}

void main() {
  testWidgets('render store preview clip', (tester) async {
    final env = Platform.environment;
    final filters = env['PREVIEW_FILTERS']!
        .split(',')
        .map((n) => MirrorFilter.values.byName(n))
        .toList();
    final captions = (env['PREVIEW_CAPTIONS'] ?? _captions).split('|');
    final taps = _plan(filters);

    tester.view.physicalSize = _screen * _dpr;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);

    late ui.Image still;
    final shaders = <MirrorFilter, ui.FragmentShader>{};
    late Process ffmpeg;
    await tester.runAsync(() async {
      await _loadFonts();
      final codec = await ui.instantiateImageCodec(
        await File(env['PREVIEW_FACE']!).readAsBytes(),
      );
      // Upscale so composeMirrorPhoto, which works at the still's density,
      // renders the shader at the clip's own height.
      final face = (await codec.getNextFrame()).image;
      still = await _upscale(face, _screen.height * _dpr / face.height);
      codec.dispose();
      for (final f in filters) {
        final program = await ui.FragmentProgram.fromAsset(f.shaderAsset!);
        shaders[f] = program.fragmentShader();
      }
      final w = (_screen.width * _dpr).round();
      final h = (_screen.height * _dpr).round();
      ffmpeg = await Process.start('ffmpeg', [
        '-v', 'error', '-y',
        '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${w}x$h',
        '-r', '$_fps', '-i', '-',
        // App Store previews want an audio track; a silent one will do.
        '-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100',
        '-shortest', '-c:v', 'libx264', '-profile:v', 'high', '-crf', '17',
        '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '256k',
        '-movflags', '+faststart', env['PREVIEW_OUT']!,
      ]);
      ffmpeg.stderr.listen(stderr.add);
    });

    final boundary = GlobalKey();
    final frame = _Frame();
    // The screen is pumped once and then driven through notifiers: rebuilding
    // FilterStrip every frame would make its didUpdateWidget snap the open
    // tab back to the selected filter's collection.
    final tick = ValueNotifier(0);
    final selected = ValueNotifier(MirrorFilter.none);
    final side = ValueNotifier(MirrorSide.left);
    final total =
        int.tryParse(env['PREVIEW_FRAMES'] ?? '') ?? (_seconds * _fps).round();
    final clock = Stopwatch()..start();
    Offset fingerFrom = Offset(_screen.width * 0.8, _screen.height + 40);
    Offset? fingerTo;
    var moveStart = 0.0;

    for (var n = 0; n < total; n++) {
      final t = n / _fps;
      frame.pressed = false;
      frame.original = t < _sidesAt;

      if (t < _sidesAt) {
        frame.caption = captions[0];
        frame.finger = null;
      } else if (t < _axisAt) {
        // Taps whose time has come go to the real widgets: the strip switches
        // tabs itself and reports filter picks through onSelect.
        for (final tap in taps) {
          // Chips past the edge of the strip scroll in before the tap.
          final reveal = tap.at - 0.6;
          if (tap.filter != null && t >= reveal && t < reveal + 1 / _fps) {
            _reveal(tester, tap);
          }
          if (t >= tap.at && t < tap.at + 1 / _fps) {
            await tester.tap(_finderOf(tap));
          }
        }
        frame.caption = t >= _filtersAt
            ? captions[3]
            : captions[side.value.isLeft ? 1 : 2];
        // The finger glides to the next target and presses briefly.
        final next = taps.firstWhere(
          (x) => x.at + 0.12 > t,
          orElse: () => taps.last,
        );
        final target = _targetOf(tester, next);
        if (fingerTo != target) {
          fingerFrom = frame.finger ?? fingerFrom;
          fingerTo = target;
          moveStart = t;
        }
        final travel = min(0.45, max(0.1, next.at - 0.12 - moveStart));
        frame.finger = Offset.lerp(
          fingerFrom,
          target,
          _smooth((t - moveStart) / travel),
        );
        frame.pressed = (t - next.at).abs() < 0.12;
        if (t > taps.last.at + 0.5) frame.finger = null;
      } else if (t < _rotateAt) {
        frame.caption = captions[4];
        final local = t - _axisAt;
        frame.axisDeg = _keys(local, _axisKeys);
        // Finger rides the inner ring on the axis line.
        final r = _screen.shortestSide * _innerRingDiameterFrac / 2 - 6;
        frame.finger = local < 0.25 || local > 5.4
            ? null
            : _onCircle(r, frame.axisDeg);
        frame.pressed = frame.finger != null;
      } else if (t < _outroAt) {
        frame.caption = captions[5];
        final local = t - _rotateAt;
        frame.rotationDeg = _keys(local, _rotateKeys);
        // Outside the inner ring the drag turns the whole composition.
        final r = _screen.shortestSide * _outerRingDiameterFrac / 2 - 18;
        frame.finger = local < 0.25 || local > 5.2
            ? null
            : _onCircle(r, 60 + frame.rotationDeg);
        frame.pressed = frame.finger != null;
      } else {
        frame.caption = captions[6];
        frame.finger = null;
      }

      frame.filter = selected.value;
      frame.side = side.value;
      final old = frame.picture;
      await tester.runAsync(() async {
        final shader = shaders[frame.filter];
        frame.picture = await composeMirrorPhoto(
          PhotoComposeJob(
            still: still,
            mirrorStillHorizontally: false,
            screenSize: _screen,
            rotationDeg: frame.rotationDeg,
            mirrorAxisDeg: frame.axisDeg,
            directOnLeft: frame.side.isLeft,
            portraitAspect: still.width / still.height,
            shader: shader,
            shaderNeedsTime: frame.filter.needsTime,
            time: t,
            shaderNeedsFace: frame.filter.needsFace,
          ),
        );
      });

      if (n == 0) {
        await tester.pumpWidget(
          _App(
            boundary: boundary,
            child: _CameraScreen(
              frame: frame,
              still: still,
              tick: tick,
              selected: selected,
              side: side,
            ),
          ),
        );
      }
      tick.value = n;
      await tester.pump(const Duration(milliseconds: 1000 ~/ _fps));

      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: _dpr);
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        ffmpeg.stdin.add(rgba!.buffer.asUint8List());
        await ffmpeg.stdin.flush();
        image.dispose();
        old?.dispose();
      });
      if (n % 60 == 59) {
        debugPrint(
          'frame ${n + 1}/$total, '
          '${clock.elapsedMilliseconds ~/ (n + 1)} ms/frame',
        );
      }
    }

    await tester.runAsync(() async {
      await ffmpeg.stdin.close();
      final code = await ffmpeg.exitCode;
      expect(code, 0, reason: 'ffmpeg failed');
    });
  }, timeout: Timeout.none);
}

Offset _onCircle(double radius, double deg) {
  final a = deg * pi / 180;
  return _screen.center(Offset.zero) + Offset(cos(a), sin(a)) * radius;
}

Finder _finderOf(_Tap tap, {bool skipOffstage = true}) {
  if (tap.isSide) return find.byType(SideToggleButton);
  final l10n = lookupAppLocalizations(_locale);
  return find.text(
    tap.tab != null
        ? tap.tab!.localizedLabel(l10n).toUpperCase()
        : '${tap.filter!.icon} ${tap.filter!.localizedLabel(l10n)}',
    skipOffstage: skipOffstage,
  );
}

/// Starts a scroll of the filter row that brings [tap]'s chip on screen;
/// the frames pumped before the tap play it. A chip the lazy list has not
/// built yet lies past the end of what is built, so the row heads there.
void _reveal(WidgetTester tester, _Tap tap) {
  const duration = Duration(milliseconds: 450);
  final chip = _finderOf(tap, skipOffstage: false);
  if (chip.evaluate().isEmpty) {
    final row = find.descendant(
      of: find.byType(FilterStrip),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(row.last).position;
    position.animateTo(
      position.maxScrollExtent,
      duration: duration,
      curve: Curves.easeInOut,
    );
    return;
  }
  final rect = tester.getRect(chip.first);
  if (rect.left >= 8 && rect.right <= _screen.width - 8) return;
  Scrollable.ensureVisible(
    chip.evaluate().first,
    alignment: 0.5,
    duration: duration,
    curve: Curves.easeInOut,
  );
}

Offset _targetOf(WidgetTester tester, _Tap tap) {
  final found = _finderOf(tap);
  // Before the first pump nothing is laid out yet.
  if (found.evaluate().isEmpty) return Offset(_screen.width / 2, 780);
  return tester.getCenter(found.first);
}

Future<ui.Image> _upscale(ui.Image src, double factor) async {
  final w = (src.width * factor).round();
  final h = (src.height * factor).round();
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    src,
    Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..filterQuality = FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final out = await picture.toImage(w, h);
  picture.dispose();
  src.dispose();
  return out;
}

/// flutter test renders text in the Ahem box font unless real fonts are
/// registered; borrow the SDK's Roboto and Material Icons plus the macOS
/// symbol fonts for the filter glyphs.
Future<void> _loadFonts() async {
  // flutter_tester lives in <sdk>/bin/cache/artifacts/engine/<host>/.
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final fonts = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  Future<void> load(String family, String path) =>
      (FontLoader(family)..addFont(read(path))).load();

  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(read('$fonts/Roboto-$w.ttf'));
  }
  await roboto.load();
  await load('MaterialIcons', '$fonts/MaterialIcons-Regular.otf');
  await load('Symbols', '/System/Library/Fonts/Apple Symbols.ttf');
  await load('Dingbats', '/System/Library/Fonts/ZapfDingbats.ttf');
}

class _App extends StatelessWidget {
  final GlobalKey boundary;
  final Widget child;
  const _App({required this.boundary, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['Symbols', 'Dingbats'],
      ),
      home: RepaintBoundary(
        key: boundary,
        // Without a Material ancestor text falls back to the debug style.
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

/// Static replica of MirrorPreviewScreen's layout around a composed frame.
/// Only the real FilterStrip and SideToggleButton are interactive; they
/// rebuild when their own value changes, everything else on every tick.
class _CameraScreen extends StatelessWidget {
  final _Frame frame;
  final ui.Image still;
  final ValueNotifier<int> tick;
  final ValueNotifier<MirrorFilter> selected;
  final ValueNotifier<MirrorSide> side;
  const _CameraScreen({
    required this.frame,
    required this.still,
    required this.tick,
    required this.selected,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    final shortest = _screen.shortestSide;
    Widget onTick(Widget Function() build) => ValueListenableBuilder(
      valueListenable: tick,
      builder: (_, _, _) => build(),
    );
    // Built once, so the per-tick fade below never rebuilds the strip.
    final controls = Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: SizedBox.square(
            dimension: shortest * _outerRingDiameterFrac,
            child: onTick(
              () => CustomPaint(
                painter: _RingPainter(rotationDeg: frame.rotationDeg),
              ),
            ),
          ),
        ),
        Center(
          child: SizedBox.square(
            dimension: shortest * _innerRingDiameterFrac,
            child: onTick(
              () => CustomPaint(
                painter: _MirrorAxisRingPainter(mirrorAxisDeg: frame.axisDeg),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 148,
          left: 0,
          right: 0,
          child: ValueListenableBuilder(
            valueListenable: selected,
            builder: (_, filter, _) => FilterStrip(
              selected: filter,
              onSelect: (f) => selected.value = f,
              ownedCollections: const {},
            ),
          ),
        ),
        Positioned(
          bottom: 44,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: side,
                builder: (_, current, _) => SideToggleButton(
                  current: current,
                  onToggle: () => side.value = current.toggled,
                ),
              ),
              const SizedBox(width: 14),
              const _PhotoButton(),
              const SizedBox(width: 14),
              const _RecButton(),
            ],
          ),
        ),
      ],
    );
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          onTick(
            () => RawImage(
              image: frame.original ? still : frame.picture,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          onTick(
            () => AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: frame.original ? 0 : 1,
              child: controls,
            ),
          ),
          Positioned(
            top: 78,
            left: 24,
            right: 24,
            child: onTick(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  frame.caption,
                  key: ValueKey(frame.caption),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    shadows: [Shadow(blurRadius: 14, color: Colors.black87)],
                  ),
                ),
              ),
            ),
          ),
          onTick(() => _Finger(frame: frame)),
        ],
      ),
    );
  }
}

class _Finger extends StatelessWidget {
  final _Frame frame;
  const _Finger({required this.frame});

  @override
  Widget build(BuildContext context) {
    final f = frame.finger;
    if (f == null) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned(
          left: f.dx - 22,
          top: f.dy - 22,
          child: IgnorePointer(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 90),
              scale: frame.pressed ? 0.82 : 1,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: frame.pressed ? 0.55 : 0.35,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(blurRadius: 10, color: Colors.black45),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3.5),
      ),
      padding: const EdgeInsets.all(5),
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

class _RecButton extends StatelessWidget {
  const _RecButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// Copies of MirrorPreviewScreen's private ring painters.
class _MirrorAxisRingPainter extends CustomPainter {
  final double mirrorAxisDeg;
  const _MirrorAxisRingPainter({required this.mirrorAxisDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashCount = 48;
    const sweep = 2 * pi / dashCount;
    const gapFrac = 0.45;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweep, sweep * (1 - gapFrac), false, ringPaint);
    }
    final theta = mirrorAxisDeg * pi / 180.0;
    final dir = Offset(cos(theta), sin(theta));
    final axisLength = radius - 4.0;
    canvas.drawLine(
      center - dir * axisLength,
      center + dir * axisLength,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      2.0,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_MirrorAxisRingPainter old) =>
      old.mirrorAxisDeg != mirrorAxisDeg;
}

class _RingPainter extends CustomPainter {
  final double rotationDeg;
  const _RingPainter({required this.rotationDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - rotationDeg) * pi / 180.0;
      final inner = radius - (i % 3 == 0 ? 14.0 : 8.0);
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * inner,
        center + Offset(cos(angle), sin(angle)) * (radius - 2),
        tickPaint,
      );
    }
    final dotAngle = -rotationDeg * pi / 180.0 - pi / 2;
    canvas.drawCircle(
      center + Offset(cos(dotAngle), sin(dotAngle)) * (radius - 8),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.rotationDeg != rotationDeg;
}
