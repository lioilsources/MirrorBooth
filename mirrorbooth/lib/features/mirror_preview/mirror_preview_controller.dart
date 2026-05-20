import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/mirror_filter.dart';
import '../../core/mirror_side.dart';

class MirrorPreviewState {
  final CameraController? controller;
  final MirrorSide side;
  final bool isReady;
  final String? error;
  /// Continuous rotation in degrees [0, 360), applied to the whole circular
  /// mirror composition.
  final double rotationDeg;
  final MirrorFilter selectedFilter;
  final CameraLensDirection lensDirection;
  final bool hasFrontCamera;
  final bool hasBackCamera;
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final List<double> zoomPresets;

  const MirrorPreviewState({
    this.controller,
    this.side = MirrorSide.left,
    this.isReady = false,
    this.error,
    this.rotationDeg = 0.0,
    this.selectedFilter = MirrorFilter.none,
    this.lensDirection = CameraLensDirection.front,
    this.hasFrontCamera = false,
    this.hasBackCamera = false,
    this.zoomLevel = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
    this.zoomPresets = const [1.0],
  });

  bool get canToggleLens => hasFrontCamera && hasBackCamera;
  bool get canZoom => maxZoom > minZoom + 0.01;

  MirrorPreviewState copyWith({
    CameraController? controller,
    MirrorSide? side,
    bool? isReady,
    String? error,
    double? rotationDeg,
    MirrorFilter? selectedFilter,
    CameraLensDirection? lensDirection,
    bool? hasFrontCamera,
    bool? hasBackCamera,
    double? zoomLevel,
    double? minZoom,
    double? maxZoom,
    List<double>? zoomPresets,
  }) =>
      MirrorPreviewState(
        controller: controller ?? this.controller,
        side: side ?? this.side,
        isReady: isReady ?? this.isReady,
        error: error ?? this.error,
        rotationDeg: rotationDeg ?? this.rotationDeg,
        selectedFilter: selectedFilter ?? this.selectedFilter,
        lensDirection: lensDirection ?? this.lensDirection,
        hasFrontCamera: hasFrontCamera ?? this.hasFrontCamera,
        hasBackCamera: hasBackCamera ?? this.hasBackCamera,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        minZoom: minZoom ?? this.minZoom,
        maxZoom: maxZoom ?? this.maxZoom,
        zoomPresets: zoomPresets ?? this.zoomPresets,
      );
}

class MirrorPreviewController extends StateNotifier<MirrorPreviewState>
    with WidgetsBindingObserver {
  MirrorPreviewController() : super(const MirrorPreviewState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  bool _switchingLens = false;

  Future<void> _init({CameraLensDirection? preferredLens}) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      state = state.copyWith(error: 'Camera permission denied');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      state = state.copyWith(error: 'No cameras available');
      return;
    }

    final hasFront =
        cameras.any((c) => c.lensDirection == CameraLensDirection.front);
    final hasBack =
        cameras.any((c) => c.lensDirection == CameraLensDirection.back);

    final desired = preferredLens ?? state.lensDirection;
    final selected = cameras.firstWhere(
      (c) => c.lensDirection == desired,
      orElse: () => cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      ),
    );

    final controller = CameraController(
      selected,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();

      double minZoom = 1.0;
      double maxZoom = 1.0;
      try {
        minZoom = await controller.getMinZoomLevel();
        maxZoom = await controller.getMaxZoomLevel();
      } catch (_) {
        // Some devices/platforms may not support zoom queries; keep defaults.
      }
      final presets = _computeZoomPresets(minZoom, maxZoom);
      final initialZoom = presets.contains(1.0) ? 1.0 : minZoom;
      try {
        await controller.setZoomLevel(initialZoom);
      } catch (_) {}

      state = state.copyWith(
        controller: controller,
        isReady: true,
        lensDirection: selected.lensDirection,
        hasFrontCamera: hasFront,
        hasBackCamera: hasBack,
        zoomLevel: initialZoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        zoomPresets: presets,
      );
      WakelockPlus.enable();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Computes iPhone-style zoom presets that fall inside the device's actual
  /// [min, max] zoom range reported by the camera plugin. We always include
  /// 1.0 (the "wide" lens equivalent) and add 0.5×, 2×, 3× when the hardware
  /// supports them. Without native lens introspection these are heuristics:
  /// a 0.5× preset means the device exposes sub-1× zoom (likely a real ultra-
  /// wide); 2×/3× may be digital on phones without a telephoto.
  static List<double> _computeZoomPresets(double min, double max) {
    final values = <double>{};
    if (min < 0.95) {
      // Round down to one decimal so 0.5×/0.6× display cleanly.
      values.add((min * 10).floor() / 10.0);
    }
    values.add(1.0);
    if (max >= 1.95) values.add(2.0);
    if (max >= 2.95) values.add(3.0);
    final list = values.where((v) => v >= min && v <= max).toList()..sort();
    return list.isEmpty ? [min.clamp(0.1, max)] : list;
  }

  Future<void> setZoom(double z) async {
    final ctrl = state.controller;
    if (ctrl == null || !state.isReady) return;
    final clamped = z.clamp(state.minZoom, state.maxZoom);
    try {
      await ctrl.setZoomLevel(clamped);
      state = state.copyWith(zoomLevel: clamped);
    } catch (_) {
      // Ignore transient errors (e.g., controller disposed mid-call).
    }
  }

  Future<void> toggleLens() async {
    if (_switchingLens) return;
    if (!state.canToggleLens) return;
    final old = state.controller;
    if (old == null || !state.isReady) return;

    _switchingLens = true;
    final next = state.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    state = state.copyWith(isReady: false);
    try {
      await old.dispose();
      await _init(preferredLens: next);
    } finally {
      _switchingLens = false;
    }
  }

  void toggleSide() {
    state = state.copyWith(side: state.side.toggled);
  }

  void setSide(MirrorSide side) {
    state = state.copyWith(side: side);
  }

  void setRotation(double deg) {
    var normalized = deg % 360.0;
    if (normalized < 0) normalized += 360.0;
    state = state.copyWith(rotationDeg: normalized);
  }

  void nudgeRotation(double delta) => setRotation(state.rotationDeg + delta);

  void setFilter(MirrorFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void Function()? onForceStop;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = this.state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      onForceStop?.call();
      controller.dispose();
      WakelockPlus.disable();
      this.state = this.state.copyWith(isReady: false);
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.controller?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}

final mirrorPreviewProvider =
    StateNotifierProvider.autoDispose<MirrorPreviewController, MirrorPreviewState>(
  (_) => MirrorPreviewController(),
);
