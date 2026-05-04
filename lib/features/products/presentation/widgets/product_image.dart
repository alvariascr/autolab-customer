import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.height,
    this.borderRadius,
    this.placeholderIconSize = 34,
  });

  final String imageUrl;
  final double height;
  final BorderRadius? borderRadius;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl.trim().isEmpty
        ? _ProductImagePlaceholder(
            height: height,
            iconSize: placeholderIconSize,
          )
        : Image.network(
            imageUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) {
              return _ProductImagePlaceholder(
                height: height,
                iconSize: placeholderIconSize,
              );
            },
          );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: child,
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder({
    required this.height,
    required this.iconSize,
  });

  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFF8F4EF),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: const Color(0xFF9B3D24),
          size: iconSize,
        ),
      ),
    );
  }
}
