// lib/common/widgets/images/t_user_avatar.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../services/image_cache_sevice.dart';

/// Circular avatar widget with two-layer caching:
///
///   • URL resolution — ImageCacheService (in-memory, 13-min TTL per S3 key)
///   • Pixel cache    — CachedNetworkImage (disk + memory)
///
/// Shows initials while the URL resolves, then cross-fades to the image.
class TUserAvatar extends StatelessWidget {
  const TUserAvatar({
    super.key,
    required this.imageKeyOrUrl,
    required this.radius,
    this.fallbackInitial = '?',
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String? imageKeyOrUrl;
  final double radius;
  final String fallbackInitial;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget avatar;

    if (imageKeyOrUrl == null || imageKeyOrUrl!.isEmpty) {
      avatar = _initialsAvatar(cs);
    } else {
      avatar = FutureBuilder<String?>(
        key: ValueKey(imageKeyOrUrl),
        future: ImageCacheService.instance.resolve(imageKeyOrUrl),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            // Show initials while resolving or on error
            return _initialsAvatar(cs);
          }

          return CachedNetworkImage(
            imageUrl: snapshot.data!,
            imageBuilder:
                (context, imageProvider) => CircleAvatar(
                  radius: radius,
                  backgroundImage: imageProvider,
                  backgroundColor:
                      backgroundColor ??
                      cs.primaryContainer.withValues(alpha: 0.3),
                ),
            placeholder: (context, url) => _initialsAvatar(cs),
            errorWidget: (context, url, error) => _initialsAvatar(cs),
            fadeInDuration: const Duration(milliseconds: 200),
          );
        },
      );
    }

    // Optional border ring
    if (borderWidth > 0 && borderColor != null) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _initialsAvatar(ColorScheme cs) {
    final letter =
        fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? cs.primaryContainer.withValues(alpha: 0.3),
      child: Text(
        letter,
        style: TextStyle(
          color: foregroundColor ?? cs.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
