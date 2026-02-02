import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/device/device_utility.dart';
import '../../../utils/helpers/helper_functions.dart';

class TEComAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Custom appbar for achieving a desired design goal.
  /// - Set [title] for a custom title.
  /// - [showBackArrow] to toggle the visibility of the back arrow.
  /// - [leadingIcon] for a custom leading icon.
  /// - [leadingOnPressed] callback for the leading icon press event.
  /// - [actions] for adding a list of action widgets.
  /// - [horizontalPadding] to customize horizontal padding around the AppBar.
  const TEComAppBar({
    super.key,
    this.title,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.showBackArrow = false,
    this.centerTitle = false,
    this.horizontalPadding,
  });

  final Widget? title;
  final bool showBackArrow;
  final bool centerTitle;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;
  final EdgeInsetsGeometry? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final padding =
        horizontalPadding ?? const EdgeInsets.symmetric(horizontal: TSizes.md);
    return Padding(
      padding: padding,
      child: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        // Allocate a normal leading width so the back button is tappable
        leadingWidth: kToolbarHeight,
        // Respect the centerTitle parameter passed to the widget
        centerTitle: centerTitle,
        leading:
            showBackArrow
                ? IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Iconsax.arrow_left,
                    color: dark ? TColors.white : TColors.dark,
                  ),
                )
                : leadingIcon != null
                ? IconButton(
                  onPressed: leadingOnPressed,
                  icon: Icon(leadingIcon),
                )
                : null,
        title: Align(
          alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
          child: title,
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(TDeviceUtils.getAppBarHeight());
}
