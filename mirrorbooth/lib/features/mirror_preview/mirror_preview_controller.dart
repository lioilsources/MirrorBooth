import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/mirror_side.dart';

class MirrorPreviewState {
  final CameraController? controller;
  final MirrorSide side;
  final bool isReady;
  final String? error;

  const MirrorPreviewState({
    this.controller,
    this.side = MirrorSide.left,
    this.isReady = false,
    this.error,
  });

  MirrorPreviewState copyWith({
    CameraController? controller,
    MirrorSide? side,
    bool? isReady,
    String? error,
  }) =>
      MirrorPreviewState(
        controller: controller ?? this.controller,
        side: side ?? this.side,
        isReady: isReady ?? this.isReady,
        error: error ?? this.error,
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = this.state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      this.state = this.state.copyWith(isReady: false);
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.controller?.dispose();
    super.dispose();
  }
}

final mirrorPreviewProvider =
    StateNotifierProvider.autoDispose<MirrorPreviewController, MirrorPreviewState>(
  (_) => MirrorPreviewController(),
);
