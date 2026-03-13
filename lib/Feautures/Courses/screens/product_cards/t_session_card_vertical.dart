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
import '../../screens/product_detail/session_detail_screen.dart';

class TSessionCardVertical extends StatelessWidget {
  final TutoringSession session;
  const TSessionCardVertical({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double price = session.pricePerSession ?? 0.0;
    final salePercentage = controller.calculateSalePercentage(price, null);
    final isFree = price == 0;

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

    Widget buildImage(String src) {
      final fallback = TImages.tutorPromo1;

      if (src.isEmpty) {
        return Image.asset(fallback, fit: BoxFit.cover);
      }

      if (src.startsWith('http')) {
        return Image.network(
          src,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
        );
      }

      return Image.asset(src, fit: BoxFit.cover);
    }

    Widget buildTutorAvatar(Tutor? tutor) {
      Widget inner;

      if (tutor == null) {
        inner = const Text(
          '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      } else if (tutor.image != null && tutor.image!.isNotEmpty) {
        inner = ClipOval(
          child:
              tutor.image!.startsWith('http')
                  ? Image.network(
                    tutor.image!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  )
                  : Image.asset(
                    tutor.image!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
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

        inner = Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        );
      }

      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: TColors.primary,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: inner,
      );
    }

    return GestureDetector(
      onTap: () {
        final tag = session.id;

        if (!Get.isRegistered<TutoringController>(tag: tag)) {
          Get.put(TutoringController(), tag: tag);
        }

        if (!Get.isRegistered<SessionCreationController>(tag: tag)) {
          Get.put(SessionCreationController(), tag: tag);
        }

        Get.to(() => SessionDetailScreen(session: session, tag: tag));
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        width: 180,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 25,
              spreadRadius: 3,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: TColors.dashboardAppbarBackground,
              blurRadius: 2,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 160,
                width: 180,
                child: Stack(
                  clipBehavior: Clip.none, // allows shadow overflow
                  children: [
                    Positioned.fill(child: buildImage(mainImage())),

                    /// bottom gradient
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ),

                    /// TUTOR AVATAR (safe bottom-left placement)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: buildTutorAvatar(session.tutor),
                    ),

                    if (salePercentage > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _Badge(
                          label: '-$salePercentage%',
                          color: Colors.redAccent.shade700,
                        ),
                      ),

                    if (isFree)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _Badge(
                          label: 'Free',
                          color: Colors.green.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            /// INFO
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (session.tutor != null)
                    TBrandTitleWithVerifiedIcon(
                      title: session.tutor!.name,
                      brandTextSize: TextSizes.small,
                    ),

                  const SizedBox(height: 4),

                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (isFree)
                    Text(
                      'Free',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₦${price.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: TColors.primary,
                        ),
                      ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
