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

  // Bumped whenever the widget's imageUrl prop changes, so a refresh
  // started for a previous prop configuration can recognize it's no
  // longer relevant and discard its result instead of clobbering
  // whatever the widget has moved on to showing.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _url = widget.imageUrl;
  }

  @override
  void didUpdateWidget(covariant GarageVehicleNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Also check imagePath: this widget can end up reused for a different
    // vehicle at the same list position (e.g. the horizontal vehicle
    // selector rebuilds its cards by index, with no per-vehicle Key, and
    // the list itself reorders whenever a vehicle is edited/activated).
    // Relying on imageUrl alone would miss that swap whenever the two
    // vehicles' URLs happen to coincide (both null/empty, for instance).
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imagePath != widget.imagePath) {
      _generation++;
      _url = widget.imageUrl;
      _hasRetried = false;
    }
  }

  Future<void> _refresh() async {
    final imagePath = widget.imagePath?.trim();
    if (_hasRetried || imagePath == null || imagePath.isEmpty) return;
    _hasRetried = true;
    final requestGeneration = _generation;

    try {
      final freshUrl = await sl<GarageVehicleRepository>()
          .refreshVehicleImageUrl(imagePath);
      if (!mounted || requestGeneration != _generation) return;
      if (freshUrl == null || freshUrl.isEmpty) return;

      // Supabase signs each URL with a fresh token, so freshUrl is never
      // the same cache key as the expired one — but evict it anyway so
      // the failed entry doesn't linger in Flutter's image cache.
      final staleUrl = _url;
      if (staleUrl != null && staleUrl.isNotEmpty) {
        PaintingBinding.instance.imageCache.evict(NetworkImage(staleUrl));
      }

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
        // Ties the image element to this exact URL, so switching to a
        // freshly-signed one is guaranteed to start a new image load
        // instead of Flutter potentially reusing internal state tied to
        // the previous (expired) request.
        key: ValueKey(url),
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
