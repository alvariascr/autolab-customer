import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/autolab_customer.dart';

class StartupSplashPage extends StatefulWidget {
  const StartupSplashPage({super.key});

  static const routePath = '/startup-splash';
  static const duration = Duration(seconds: 5);

  @override
  State<StartupSplashPage> createState() => _StartupSplashPageState();
}

class _StartupSplashPageState extends State<StartupSplashPage> {
  static const _splashVideoPath = 'assets/images/splash/splash_intro.mp4';

  Timer? _timer;
  VideoPlayerController? _videoController;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVideo());
    _timer = Timer(
      StartupSplashPage.duration,
      () => unawaited(_goToInitialRoute()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController
      ?..removeListener(_handleVideoProgress)
      ..dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset(_splashVideoPath);
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.play();
      controller.addListener(_handleVideoProgress);
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _videoController = null);
      }
    }
  }

  void _handleVideoProgress() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final duration = controller.value.duration;
    if (duration == Duration.zero) {
      return;
    }

    if (controller.value.position >= duration) {
      unawaited(_goToInitialRoute());
    }
  }

  Future<void> _goToInitialRoute() async {
    if (!mounted || _didNavigate) return;

    _didNavigate = true;
    _timer?.cancel();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final isVideoReady = controller?.value.isInitialized ?? false;

    return ColoredBox(
      color: AutolabCustomer.primary,
      child: SizedBox.expand(
        child: isVideoReady
            ? _ResponsiveSplashVideo(controller: controller!)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ResponsiveSplashVideo extends StatelessWidget {
  const _ResponsiveSplashVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        if (videoSize.width <= 0 ||
            videoSize.height <= 0 ||
            viewportWidth <= 0 ||
            viewportHeight <= 0) {
          return const SizedBox.shrink();
        }

        final coverScale = math.max(
          viewportWidth / videoSize.width,
          viewportHeight / videoSize.height,
        );
        final bleed = math.max(viewportWidth, viewportHeight) * 0.03;
        final fittedWidth = (videoSize.width * coverScale) + bleed;
        final fittedHeight = (videoSize.height * coverScale) + bleed;

        return ClipRect(
          child: Center(
            child: OverflowBox(
              minWidth: fittedWidth,
              maxWidth: fittedWidth,
              minHeight: fittedHeight,
              maxHeight: fittedHeight,
              child: SizedBox(
                width: fittedWidth,
                height: fittedHeight,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}
