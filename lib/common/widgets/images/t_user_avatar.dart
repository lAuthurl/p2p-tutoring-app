import 'package:flutter/material.dart';
import 'package:p2p_tutoring_app/personalization/controllers/user_controller.dart';

class TUserAvatar extends StatelessWidget {
  const TUserAvatar({
    super.key,
    required this.imageKeyOrUrl,
    required this.radius,
    this.fallbackInitial = '?',
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? imageKeyOrUrl;
  final double radius;
  final String fallbackInitial;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (imageKeyOrUrl == null || imageKeyOrUrl!.isEmpty) {
      return _fallback(cs);
    }

    return FutureBuilder<String?>(
      // ✅ Resolve a fresh signed URL every time this widget builds.
      // The URL expires in 15 min so we always fetch a fresh one.
      future: UserController.resolveS3Url(imageKeyOrUrl),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _fallback(cs);
        }
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(snapshot.data!),
          backgroundColor:
              backgroundColor ?? cs.primaryContainer.withValues(alpha: 0.3),
          onBackgroundImageError: (_, __) {},
          child: null,
        );
      },
    );
  }

  Widget _fallback(ColorScheme cs) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? cs.primaryContainer.withValues(alpha: 0.3),
      child: Text(
        fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : '?',
        style: TextStyle(
          color: foregroundColor ?? cs.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
