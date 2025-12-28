import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';

class ClickableRichTextWidget extends StatelessWidget {
  const ClickableRichTextWidget({
    required this.text1,
    required this.text2,
    required this.onPressed,
    super.key,
  });

  final String text1, text2;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${text1.tr}? ',
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          isDark
                              ? TColors.textDarkSecondary
                              : TColors.textSecondary,
                    ) ??
                    TextStyle(
                      color:
                          isDark
                              ? TColors.textDarkSecondary
                              : TColors.textSecondary,
                    ),
              ),
              TextSpan(
                text: text2.tr,
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TColors.facebookBackgroundColor,
                    ) ??
                    TextStyle(color: TColors.facebookBackgroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
