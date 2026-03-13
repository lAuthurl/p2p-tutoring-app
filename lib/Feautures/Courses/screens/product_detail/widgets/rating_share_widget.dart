// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../../models/ModelProvider.dart'; // ✅ Import your Review model

class TRatingAndShare extends StatelessWidget {
  final List<Review>? reviews;

  const TRatingAndShare({super.key, this.reviews});

  double get averageRating {
    if (reviews == null || reviews!.isEmpty) return 0;
    final total = reviews!.fold<double>(0, (sum, r) => sum + (r.rating));
    return total / reviews!.length;
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = averageRating;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Rating Stars Only
        Row(
          children: List.generate(5, (index) {
            final iconColor =
                index < avgRating.round() ? Colors.amber : Colors.grey.shade300;
            return Icon(Iconsax.star5, color: iconColor, size: 24);
          }),
        ),

        /// Share Button
        IconButton(
          onPressed: () {
            // Implement sharing logic here, e.g. share session link
          },
          icon: const Icon(Icons.share, size: TSizes.iconMd),
        ),
      ],
    );
  }
}
