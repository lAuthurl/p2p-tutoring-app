import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/device/device_utility.dart';
import '../../../../../../utils/helpers/helper_functions.dart';

class TSearchContainer extends StatelessWidget {
  const TSearchContainer({
    super.key,
    required this.text,
    this.icon = Iconsax.search_normal,
    this.showBackground = true,
    this.showBorder = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
  });

  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showBackground, showBorder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return GestureDetector(
      // onTap: () => Get.to(() => const SearchScreen()),
      child: Padding(
        padding: padding,
        child: Container(
          width: TDeviceUtils.getScreenWidth(context),
          padding: const EdgeInsets.symmetric(
            vertical: TSizes.lg,
            horizontal: TSizes.md,
          ),
          decoration: BoxDecoration(
            color:
                showBackground
                    ? Theme.of(context).colorScheme.surface
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            border:
                showBorder
                    ? Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.08),
                    )
                    : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: dark ? TColors.darkerGrey : Colors.grey),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(text, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
