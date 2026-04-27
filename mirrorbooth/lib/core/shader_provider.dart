import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mirror_filter.dart';

typedef ShaderCache = Map<MirrorFilter, FragmentProgram>;

final shaderCacheProvider = FutureProvider<ShaderCache>((ref) async {
  final cache = <MirrorFilter, FragmentProgram>{};
  for (final filter in MirrorFilter.values) {
    final asset = filter.shaderAsset;
    if (asset != null) {
      cache[filter] = await FragmentProgram.fromAsset(asset);
    }
  }
  return cache;
});
