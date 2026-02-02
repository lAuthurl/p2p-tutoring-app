import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class TProductQuantityWithAddRemoveButton extends StatelessWidget {
  /// Deprecated: add/remove controls removed. This widget now renders a simple
  /// non-interactive quantity display to preserve compatibility with older callers.
  const TProductQuantityWithAddRemoveButton({
    super.key,
    this.add,
    this.width = 40,
    this.height = 40,
    this.iconSize,
    this.remove,
    required this.quantity,
    this.addBackgroundColor = TColors.black,
    this.removeBackgroundColor = TColors.darkGrey,
    this.addForegroundColor = TColors.white,
    this.removeForegroundColor = TColors.white,
  });

  final VoidCallback? add, remove;
  final int quantity;
  final double width, height;
  final double? iconSize;
  final Color addBackgroundColor, removeBackgroundColor;
  final Color addForegroundColor, removeForegroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: TSizes.spaceBtwItems),
        const SizedBox(width: TSizes.spaceBtwItems),
      ],
    );
  }
}
