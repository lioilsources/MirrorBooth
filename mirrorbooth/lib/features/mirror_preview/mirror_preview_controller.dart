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
  /// 0, 90, 180, 270 — applied to camera content (preview + capture)
  final int rotationDeg;
  final MirrorFilter selectedFilter;

  const MirrorPreviewState({
    this.controller,
    this.side = MirrorSide.left,
    this.isReady = false,
    this.error,
    this.rotationDeg = 0,
    this.selectedFilter = MirrorFilter.none,
  });

  MirrorPreviewState copyWith({
    CameraController? controller,
    MirrorSide? side,
    bool? isReady,
    String? error,
    int? rotationDeg,
    MirrorFilter? selectedFilter,
  }) =>
      MirrorPreviewState(
        controller: controller ?? this.controller,
        side: side ?? this.side,
        isReady: isReady ?? this.isReady,
        error: error ?? this.error,
        rotationDeg: rotationDeg ?? this.rotationDeg,
        selectedFilter: selectedFilter ?? this.selectedFilter,
      );
}

class MirrorPreviewController extends StateNotifier<MirrorPreviewState>
    with WidgetsBindingObserver {
  MirrorPreviewController() : super(const MirrorPreviewState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      state = state.copyWith(error: 'Camera permission denied');
      return;
    }

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
      state = state.copyWith(controller: controller, isReady: true);
      WakelockPlus.enable();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void toggleSide() {
    state = state.copyWith(side: state.side.toggled);
  }

  void setSide(MirrorSide side) {
    state = state.copyWith(side: side);
  }

  /// Cycle: 0° → 90° → 180° → 270° → 0°. Used by manual rotate button.
  void cycleRotation() {
    state = state.copyWith(rotationDeg: (state.rotationDeg + 90) % 360);
  }

  void setRotation(int deg) {
    state = state.copyWith(rotationDeg: deg % 360);
  }

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
