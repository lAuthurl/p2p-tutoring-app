// lib/common/widgets/images/t_network_image.dart

import 'package:flutter/material.dart';
import 'package:p2p_tutoring_app/personalization/controllers/user_controller.dart';
import 'package:p2p_tutoring_app/utils/constants/image_strings.dart';

/// Displays a network image from an S3 key or URL.
///
/// Resolves a fresh pre-signed URL at build time so the image never
/// shows a 403 due to an expired signature. Falls back to [fallbackAsset]
/// on error or while loading.
class TNetworkImage extends StatelessWidget {
  const TNetworkImage({
    super.key,
    required this.imageKeyOrUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackAsset,
    this.fallbackWidget,
    this.showLoadingIndicator = false,
    this.showShimmer = false,
    this.borderRadius,
  });

  final String? imageKeyOrUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Asset path shown on error or when image is null.
  /// Defaults to TImages.tutorPromo1.
  final String? fallbackAsset;

  /// Custom widget shown on error instead of an asset.
  /// Takes priority over [fallbackAsset] if both are provided.
  final Widget? fallbackWidget;

  /// Show a circular progress indicator while loading.
  final bool showLoadingIndicator;

  /// Show a shimmer placeholder while resolving/loading.
  final bool showShimmer;

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveFallback =
        fallbackWidget ??
        Image.asset(
          fallbackAsset ?? TImages.tutorPromo1,
          fit: fit,
          width: width,
          height: height,
        );

    if (imageKeyOrUrl == null || imageKeyOrUrl!.isEmpty) {
      return effectiveFallback;
    }

    Widget result = FutureBuilder<String?>(
      future: UserController.resolveS3Url(imageKeyOrUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (showShimmer) return _Shimmer(width: width, height: height);
          if (showLoadingIndicator) {
            return SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          // Transparent placeholder while resolving
          return SizedBox(width: width, height: height);
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return effectiveFallback;
        }

        final url = snapshot.data!;

        return Image.network(
          url,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 200),
                child: child,
              );
            }
            if (showShimmer) {
              return _Shimmer(width: width, height: height);
            }
            if (showLoadingIndicator) {
              return Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value:
                        progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                (progress.expectedTotalBytes ?? 1)
                            : null,
                  ),
                ),
              );
            }
            return SizedBox(width: width, height: height);
          },
          errorBuilder: (_, __, ___) => effectiveFallback,
        );
      },
    );

    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius!, child: result);
    }

    return result;
  }
}

// ── Internal shimmer placeholder ─────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer({this.width, this.height});
  final double? width;
  final double? height;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.withValues(alpha: _anim.value),
          ),
    );
  }
}
