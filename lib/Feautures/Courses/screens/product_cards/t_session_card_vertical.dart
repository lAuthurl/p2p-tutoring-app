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

    String mainImage() {
      if (session.images != null && session.images!.isNotEmpty) {
        final img = session.images!.first;
        if (img.isNotEmpty) return img;
      }
      if (session.thumbnail != null && session.thumbnail!.isNotEmpty) {
        return session.thumbnail!;
      }
      if (session.sessionVariations != null &&
          session.sessionVariations!.isNotEmpty) {
        final v = session.sessionVariations!.first;
        if (v.image != null && v.image!.isNotEmpty) return v.image!;
      }
      return '';
    }

    Widget buildImage(String src, {BoxFit fit = BoxFit.cover}) {
      final fallback = TImages.tutorPromo1;
      if (src.isEmpty) return Image.asset(fallback, fit: fit);
      if (src.startsWith('http')) {
        return Image.network(
          src,
          fit: fit,
          errorBuilder: (_, __, ___) => Image.asset(fallback, fit: fit),
        );
      }
      return Image.asset(src, fit: fit);
    }

    final tutorIcon =
        session.tutor?.image?.isNotEmpty == true
            ? session.tutor!.image!
            : TImages.tdefaultpfp;

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
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: TColors.textWhite,
                      child: ClipOval(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child:
                              tutorIcon.startsWith('http')
                                  ? Image.network(tutorIcon, fit: BoxFit.cover)
                                  : Image.asset(tutorIcon, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  if (salePercentage != null && salePercentage > 0)
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

            // ✅ Detailed Column with Tutor Name & Session Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tutor Name + Verified Icon
                  if (session.tutor != null) ...[
                    Row(
                      children: [
                        const SizedBox(width: 0), // optional spacing
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
