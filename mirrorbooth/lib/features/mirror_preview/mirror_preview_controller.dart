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
  });

  bool get canToggleLens => hasFrontCamera && hasBackCamera;

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
      state = state.copyWith(
        controller: controller,
        isReady: true,
        lensDirection: selected.lensDirection,
        hasFrontCamera: hasFront,
        hasBackCamera: hasBack,
      );
      WakelockPlus.enable();
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
      // Flip isReady first so the screen drops FilteredMirrorCanvas (and its
      // capture ticker) before the controller dies.
      this.state = this.state.copyWith(isReady: false);
      controller.dispose();
      WakelockPlus.disable();
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
