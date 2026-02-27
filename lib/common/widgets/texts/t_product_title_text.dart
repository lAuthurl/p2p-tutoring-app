import 'package:flutter/material.dart';

class TProductTitleText extends StatelessWidget {
  const TProductTitleText({
    super.key,
    required this.title,
    this.smallSize = false,
    this.maxLines = 2,
    this.textAlign = TextAlign.left,
    this.customStyle, // <-- added
  });

  final String title;
  final bool smallSize;
  final int maxLines;
  final TextAlign? textAlign;
  final TextStyle? customStyle; // <-- added

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style:
          customStyle ??
          (!smallSize
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.labelLarge),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
