// lib/common/widgets/images/t_network_image.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:p2p_tutoring_app/utils/constants/image_strings.dart';

import '../../../services/image_cache_sevice.dart';

class TNetworkImage extends StatefulWidget {
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

  @override
  State<TNetworkImage> createState() => _TNetworkImageState();
}

class _TNetworkImageState extends State<TNetworkImage> {
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve(widget.imageKeyOrUrl);
  }

  @override
  void didUpdateWidget(TNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageKeyOrUrl != widget.imageKeyOrUrl) {
      setState(() {
        _resolvedUrl = null;
        _loading = true;
      });
      _resolve(widget.imageKeyOrUrl);
    }
  }

  Future<void> _resolve(String? key) async {
    if (key == null || key.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final url = await ImageCacheService.instance.resolve(key);
    if (mounted) {
      setState(() {
        _resolvedUrl = url;
        _loading = false;
      });
    }
  }

  Widget _fallback() =>
      widget.fallbackWidget ??
      Image.asset(
        widget.fallbackAsset ?? TImages.courseOthers,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
      );

  @override
  Widget build(BuildContext context) {
    if (widget.imageKeyOrUrl == null || widget.imageKeyOrUrl!.isEmpty) {
      return _fallback();
    }

    Widget result;

    if (_loading) {
      if (widget.showShimmer) {
        result = _Shimmer(width: widget.width, height: widget.height);
      } else if (widget.showLoadingIndicator) {
        result = SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      } else {
        // Show fallback while loading so there's no blank gap
        result = _fallback();
      }
    } else if (_resolvedUrl == null) {
      result = _fallback();
    } else {
      result = CachedNetworkImage(
        imageUrl: _resolvedUrl!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) {
          if (widget.showShimmer) {
            return _Shimmer(width: widget.width, height: widget.height);
          }
          if (widget.showLoadingIndicator) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _fallback();
        },
        errorWidget: (context, url, error) => _fallback(),
      );
    }

    if (widget.borderRadius != null) {
      result = ClipRRect(borderRadius: widget.borderRadius!, child: result);
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
          (_, _) => Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.withValues(alpha: _anim.value),
          ),
    );
  }
}
