import 'package:flutter/material.dart';

class FormHeaderWidget extends StatelessWidget {
  const FormHeaderWidget({
    super.key,
    this.imageColor,
    this.titleColor,
    this.subTitleColor,
    this.heightBetween,
    required this.image,
    required this.title,
    required this.subTitle,
    this.imageHeight = 0.15,
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.imageAlignment = Alignment.topLeft,
  });

  //Variables -- Declared in Constructor
  final Color? imageColor;
  final Color? titleColor;
  final Color? subTitleColor;
  final double imageHeight;
  final double? heightBetween;
  final String image, title, subTitle;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign? textAlign;
  final AlignmentGeometry imageAlignment;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Align(
          alignment: imageAlignment,
          child: Image.asset(
            image,
            height: size.height * imageHeight,
            color: imageColor,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) => SizedBox(
                  height: size.height * imageHeight,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: (size.height * imageHeight) * 0.6,
                    ),
                  ),
                ),
          ),
        ),
        SizedBox(height: heightBetween),
        Text(
          title,
          style:
              Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(color: titleColor) ??
              TextStyle(color: titleColor),
        ),
        Text(
          subTitle,
          textAlign: textAlign,
          style:
              Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: subTitleColor) ??
              TextStyle(color: subTitleColor),
        ),
      ],
    );
  }
}
