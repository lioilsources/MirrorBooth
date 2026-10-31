// App Store screenshot helper: runs the real filter shaders over still images,
// so the listing shows what the app renders rather than a lookalike. Not part
// of the regular test suite. store/appstore/make_appstore_shots.py calls it:
//
//   STORE_IN=dir STORE_OUT=dir STORE_FILTERS=neon,popArt \
//     flutter test tool/store_filter_render_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mirrorbooth/core/face_anchor.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';

Future<ui.Image> _apply(ui.Image input, MirrorFilter filter) async {
  final program = await ui.FragmentProgram.fromAsset(filter.shaderAsset!);
  final shader = program.fragmentShader();
  // Same float layout as composeMirrorPhoto.
  final w = input.width.toDouble();
  final h = input.height.toDouble();
  shader.setImageSampler(0, input);
  shader.setFloat(0, w);
  shader.setFloat(1, h);
  var i = 2;
  if (filter.needsTime) shader.setFloat(i++, 12.0);
  if (filter.needsFace) {
    shader.setFloat(i++, FaceAnchor.defaults.center.dx);
    shader.setFloat(i++, FaceAnchor.defaults.center.dy);
    shader.setFloat(i++, FaceAnchor.defaults.scale);
  }
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = shader);
  final picture = recorder.endRecording();
  final out = await picture.toImage(input.width, input.height);
  picture.dispose();
  shader.dispose();
  return out;
}

void main() {
  testWidgets('render store filter stills', (tester) async {
    final env = Platform.environment;
    final inDir = Directory(env['STORE_IN']!);
    final outDir = Directory(env['STORE_OUT']!)..createSync(recursive: true);
    final filters = env['STORE_FILTERS']!
        .split(',')
        .map((n) => MirrorFilter.values.byName(n))
        .toList();

    await tester.runAsync(() async {
      for (final file in inDir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.png')) continue;
        final stem = file.uri.pathSegments.last.replaceAll('.png', '');
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final input = (await codec.getNextFrame()).image;
        codec.dispose();
        for (final filter in filters) {
          final image = await _apply(input, filter);
          final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          final png = img.encodePng(img.Image.fromBytes(
            width: image.width,
            height: image.height,
            bytes: rgba!.buffer,
            numChannels: 4,
            order: img.ChannelOrder.rgba,
          ));
          await File('${outDir.path}/${stem}_${filter.name}.png')
              .writeAsBytes(png);
          image.dispose();
        }
        input.dispose();
      }
    });
  });
}
