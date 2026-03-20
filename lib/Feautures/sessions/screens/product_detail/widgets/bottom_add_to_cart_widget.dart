import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:p2p_tutoring_app/models/TutoringSession.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart'; // contains TProductQuantityWithAddRemoveButton
import '../../../controllers/tutoring_controller.dart';
import '../../../models/tutoring_session_model.dart';

class TBottomAddToBooking extends StatefulWidget {
  const TBottomAddToBooking({super.key, required this.session});

  final TutoringSessionModel session;

  @override
  State<TBottomAddToBooking> createState() => _TBottomAddToBookingState();
}

class _TBottomAddToBookingState extends State<TBottomAddToBooking> {
  final tutoringController = TutoringController.instance;

  @override
  void initState() {
    super.initState();
    // Initialization is now performed by the parent screen to ensure pricing
    // and selected attributes are set before the first build.
  }

  @override
  Widget build(BuildContext context) {
    // Slightly lower the bar so it sits closer to device bottom edge
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.defaultSpace),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TSizes.defaultSpace,
          vertical: TSizes.defaultSpace / 2,
        ),
        decoration: BoxDecoration(
          color: TColors.darkContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Fixed quantity display (only one booking allowed)
            Row(
              children: [
                const Icon(Iconsax.calendar_1, size: 18),
                const SizedBox(width: TSizes.spaceBtwItems / 2),
                Text('Qty: 1', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),

            // Add to booking button (static snapshot, not reactive)
            ElevatedButton(
              onPressed:
                  () => tutoringController.addSessionToBooking(
                    widget.session as TutoringSession,
                  ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: TColors.primary,
                side: const BorderSide(color: TColors.primary),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.calendar_1),
                  SizedBox(width: TSizes.spaceBtwItems / 2),
                  Text('Add to Booking'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
