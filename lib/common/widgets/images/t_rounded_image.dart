import 'package:flutter/material.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/constants/image_strings.dart';

class TRoundedImage extends StatelessWidget {
  const TRoundedImage({
    super.key,
    this.border,
    this.padding,
    this.onPressed,
    this.width,
    this.height,
    this.applyImageRadius = true,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.isNetworkImage = false,
    this.borderRadius = TSizes.md,
  });

  final double? width, height;
  final String imageUrl;
  final bool applyImageRadius;
  final BoxBorder? border;
  final Color? backgroundColor;
  final BoxFit? fit;
  final EdgeInsetsGeometry? padding;
  final bool isNetworkImage;
  final VoidCallback? onPressed;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cleaned = THelperFunctions.normalizeImagePath(imageUrl);
    final useNetwork =
        isNetworkImage || THelperFunctions.isNetworkImagePath(imageUrl);

    Widget imageWidget;
    if (cleaned.isEmpty) {
      // Use fallback placeholder asset
      imageWidget = Image.asset(TImages.tutorPromo1, fit: fit);
    } else if (useNetwork) {
      imageWidget = Image.network(
        cleaned,
        fit: fit,
        // Show simple loading indicator while network image loads
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return const SizedBox.shrink();
          }
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: 1,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // fallback to asset placeholder
          return Image.asset(TImages.tutorPromo1, fit: fit);
        },
      );
    } else {
      imageWidget = Image.asset(cleaned, fit: fit);
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          border: border,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius:
              applyImageRadius
                  ? BorderRadius.circular(borderRadius)
                  : BorderRadius.zero,
          child: imageWidget,
        ),
      ),
    );
  }
}
