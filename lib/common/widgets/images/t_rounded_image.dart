import 'package:flutter/material.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/constants/image_strings.dart';
import 't_network_image.dart';

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
      imageWidget = TNetworkImage(
        imageKeyOrUrl: cleaned,
        fit: fit ?? BoxFit.cover, // ✅ null fallback
        showLoadingIndicator: true,
        fallbackAsset: TImages.tutorPromo1,
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
