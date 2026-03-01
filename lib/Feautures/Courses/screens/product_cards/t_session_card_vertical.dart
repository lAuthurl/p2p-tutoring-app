// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/controllers/tutoring_controller.dart';
import '../../../../common/widgets/texts/t_brand_title_text_with_verified_icon.dart';
import '../../../../utils/constants/enums.dart';
import '../../controllers/session_creation_controller.dart';
import '../../../../models/ModelProvider.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../screens/product_detail/session_detail_screen.dart';

class TSessionCardVertical extends StatelessWidget {
  final TutoringSession session;
  const TSessionCardVertical({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;
    final double price = session.pricePerSession ?? 0.0;
    final salePercentage = controller.calculateSalePercentage(price, null);

    // Determine main image
    String mainImage() {
      if (session.images != null && session.images!.isNotEmpty) {
        final img = session.images!.first;
        if (img.isNotEmpty) return img;
      }
      if (session.thumbnail != null && session.thumbnail!.isNotEmpty) {
        return session.thumbnail!;
      }
      return '';
    }

    // Build image widget with fallback
    Widget buildImage(String src, {BoxFit fit = BoxFit.cover}) {
      final fallback = TImages.tutorPromo1;
      if (src.isEmpty) return Image.asset(fallback, fit: fit);
      if (src.startsWith('http')) {
        return Image.network(
          src,
          fit: fit,
          errorBuilder: (_, _, _) => Image.asset(fallback, fit: fit),
        );
      }
      return Image.asset(src, fit: fit);
    }

    // Tutor avatar with initials fallback
    Widget buildTutorAvatar(Tutor? tutor) {
      if (tutor == null) {
        return CircleAvatar(
          radius: 16,
          backgroundColor: TColors.primary,
          child: const Text(
            '?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
      }

      if (tutor.image != null && tutor.image!.isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundColor: TColors.textWhite,
          child: ClipOval(
            child: SizedBox(
              width: 28,
              height: 28,
              child:
                  tutor.image!.startsWith('http')
                      ? Image.network(tutor.image!, fit: BoxFit.cover)
                      : Image.asset(tutor.image!, fit: BoxFit.cover),
            ),
          ),
        );
      } else {
        final initials =
            tutor.name
                .trim()
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase();
        return CircleAvatar(
          radius: 16,
          backgroundColor: TColors.primary,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        final tag = session.id;

        if (!Get.isRegistered<TutoringController>(tag: tag)) {
          Get.put(TutoringController(), tag: tag, permanent: false);
        }
        if (!Get.isRegistered<SessionCreationController>(tag: tag)) {
          Get.put(SessionCreationController(), tag: tag, permanent: false);
        }

        Get.to(() => SessionDetailScreen(session: session, tag: tag));
      },
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
            // Image Stack with Tutor Icon & Sale Badge
            SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        TSizes.productImageRadius,
                      ),
                      child: buildImage(mainImage()),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: buildTutorAvatar(session.tutor),
                  ),
                  if (salePercentage > 0)
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

            // Tutor name + session title & price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (session.tutor != null) ...[
                    Row(
                      children: [
                        const SizedBox(width: 0),
                        TBrandTitleWithVerifiedIcon(
                          title: session.tutor!.name,
                          brandTextSize: TextSizes.medium,
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 4),
                  ],

                  // Session Title
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 4),

                  // Session Price
                  Text(
                    '\$${price.toStringAsFixed(0)}',
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
