import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mirror_filter.dart';

typedef ShaderCache = Map<MirrorFilter, FragmentProgram>;

/// Shader programs loaded so far. Programs are loaded on demand (when a
/// filter is first selected) instead of all at launch: with ~100 filters the
/// eager loop kept the app on its launch screen for seconds.
class ShaderCacheNotifier extends Notifier<ShaderCache> {
  final _pending = <MirrorFilter>{};

  @override
  ShaderCache build() => const {};

  Future<void> ensure(MirrorFilter filter) async {
    final asset = filter.shaderAsset;
    if (asset == null || state.containsKey(filter) || !_pending.add(filter)) {
      return;
    }
    try {
      final program = await FragmentProgram.fromAsset(asset);
      state = {...state, filter: program};
    } catch (e) {
      debugPrint('shader $asset failed to load: $e');
    } finally {
      _pending.remove(filter);
    }
  }
}

final shaderCacheProvider =
    NotifierProvider<ShaderCacheNotifier, ShaderCache>(ShaderCacheNotifier.new);
