// lib/common/widgets/images/t_network_image.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:p2p_tutoring_app/utils/constants/image_strings.dart';

import '../../../services/image_cache_sevice.dart';

/// Displays a network image from an S3 key or URL with two-layer caching:
///
///   • URL resolution cache  — ImageCacheService (in-memory, 13-min TTL)
///   • Pixel cache           — CachedNetworkImage (disk + memory)
///
/// This means:
///   • S3 pre-signed URLs are refreshed at most once per 13 minutes per key
///   • The decoded image pixels are cached on disk so re-renders are instant
///   • No flicker on widget rebuilds — CachedNetworkImage reuses the disk hit
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
  final String? fallbackAsset;
  final Widget? fallbackWidget;
  final bool showLoadingIndicator;
  final bool showShimmer;
  final BorderRadius? borderRadius;

  Widget _fallback() =>
      fallbackWidget ??
      Image.asset(
        fallbackAsset ?? TImages.tutorPromo1,
        fit: fit,
        width: width,
        height: height,
      );

  @override
  Widget build(BuildContext context) {
    if (imageKeyOrUrl == null || imageKeyOrUrl!.isEmpty) {
      return _fallback();
    }

    Widget result = FutureBuilder<String?>(
      // ValueKey ensures the future reruns only when the raw key actually changes,
      // not on every parent rebuild
      key: ValueKey(imageKeyOrUrl),
      future: ImageCacheService.instance.resolve(imageKeyOrUrl),
      builder: (context, snapshot) {
        // ── Loading state ──────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (showShimmer) {
            return _Shimmer(width: width, height: height);
          }
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
          // Transparent gap while resolving (avoids layout shifts)
          return SizedBox(width: width, height: height);
        }

        // ── Error / null ───────────────────────────────────────────────────
        if (!snapshot.hasData || snapshot.data == null) {
          return _fallback();
        }

        // ── Resolved URL — hand off to CachedNetworkImage for pixel caching ─
        return CachedNetworkImage(
          imageUrl: snapshot.data!,
          fit: fit,
          width: width,
          height: height,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (context, url) {
            if (showShimmer) {
              return _Shimmer(width: width, height: height);
            }
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
            return SizedBox(width: width, height: height);
          },
          errorWidget: (context, url, error) => _fallback(),
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
