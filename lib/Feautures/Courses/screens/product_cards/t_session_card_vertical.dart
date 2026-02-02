import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/controllers/tutoring_controller.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/models/tutoring_session_model.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/session_detail_screen.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';

class TSessionCardVertical extends StatelessWidget {
  final TutoringSessionModel session;
  const TSessionCardVertical({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;
    final salePercentage = controller.calculateSalePercentage(
      session.pricePerSession,
      null,
    );

    // Prefer session.images.first, then thumbnail, then first variation image
    String mainImage() {
      if (session.images != null && session.images!.isNotEmpty) {
        return session.images!.first;
      }
      if (session.thumbnail.isNotEmpty) return session.thumbnail;
      if (session.sessionVariations != null &&
          session.sessionVariations!.isNotEmpty) {
        return session.sessionVariations!.first.image ?? '';
      }
      return '';
    }

    Widget buildImage(String src, {BoxFit fit = BoxFit.cover}) {
      final fallback = TImages.tutorPromo1; // safe fallback
      if (src.isEmpty) {
        return Image.asset(fallback, fit: fit);
      }
      if (src.startsWith('http')) {
        return Image.network(src, fit: fit);
      }
      return Image.asset(src, fit: fit);
    }

    final tutorIcon = session.tutor?.image ?? TImages.tutorAlice;

    return GestureDetector(
      onTap: () => Get.to(() => SessionDetailScreen(session: session)),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(TSizes.productImageRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                children: [
                  // Main/session image (uses session.images first)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        TSizes.productImageRadius,
                      ),
                      child: buildImage(mainImage()),
                    ),
                  ),

                  // Small platform/tutor icon (bottom-left)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: TColors.borderDark, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: TColors.textWhite,
                        child: ClipOval(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child:
                                tutorIcon.startsWith('http')
                                    ? Image.network(
                                      tutorIcon,
                                      fit: BoxFit.cover,
                                    )
                                    : Image.asset(tutorIcon, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (salePercentage != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 0, 0, 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$salePercentage%',
                          style: const TextStyle(
                            color: TColors.textWhite,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 4),
                  Text(
                    '\$${session.pricePerSession.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
