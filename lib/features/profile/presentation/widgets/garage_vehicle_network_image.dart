import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/di/app_injection.dart';
import '../../domain/repositories/garage_vehicle_repository.dart';

/// Renders a garage vehicle photo from its signed URL, and transparently
/// re-signs it once if the URL has expired. Signed URLs are only valid for
/// an hour, so a screen left open longer than that would otherwise show
/// [errorBuilder]'s fallback even though the photo itself is still there.
class GarageVehicleNetworkImage extends StatefulWidget {
  const GarageVehicleNetworkImage({
    super.key,
    required this.imagePath,
    required this.imageUrl,
    required this.errorBuilder,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
  });

  /// The storage path used to request a fresh signed URL when the current
  /// one expires. Null/empty disables the automatic refresh.
  final String? imagePath;
  final String? imageUrl;
  final BoxFit fit;
  final WidgetBuilder errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  @override
  State<GarageVehicleNetworkImage> createState() =>
      _GarageVehicleNetworkImageState();
}

class _GarageVehicleNetworkImageState extends State<GarageVehicleNetworkImage> {
  String? _url;
  bool _hasRetried = false;

  @override
  void initState() {
    super.initState();
    _url = widget.imageUrl;
  }

  @override
  void didUpdateWidget(covariant GarageVehicleNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _url = widget.imageUrl;
      _hasRetried = false;
    }
  }

  Future<void> _refresh() async {
    final imagePath = widget.imagePath?.trim();
    if (_hasRetried || imagePath == null || imagePath.isEmpty) return;
    _hasRetried = true;

    try {
      final freshUrl = await sl<GarageVehicleRepository>()
          .refreshVehicleImageUrl(imagePath);
      if (!mounted || freshUrl == null || freshUrl.isEmpty) return;
      setState(() => _url = freshUrl);
    } catch (_) {
      // Keep showing the fallback if the refresh itself fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null || url.isEmpty) {
      // Fills whatever space the caller gave us, so the fallback occupies
      // the exact same box as the image would — regardless of how the
      // caller happens to be constraining us — avoiding a layout shift
      // between the loaded-image and fallback states.
      return SizedBox.expand(child: widget.errorBuilder(context));
    }

    return SizedBox.expand(
      child: Image.network(
        url,
        fit: widget.fit,
        loadingBuilder: widget.loadingBuilder,
        errorBuilder: (context, error, stackTrace) {
          // Guard here (not just inside _refresh()) so a widget stuck in
          // the error state doesn't keep queueing a callback on every
          // rebuild it happens to go through (scrolls, animations, an
          // ancestor's setState, ...) once a retry has already run.
          if (!_hasRetried) {
            SchedulerBinding.instance.addPostFrameCallback((_) => _refresh());
          }
          return widget.errorBuilder(context);
        },
      ),
    );
  }
}
