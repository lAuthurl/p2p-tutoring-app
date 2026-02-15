import 'package:flutter/material.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
import '../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/tutoring_controller.dart';
import '../../../../../models/ModelProvider.dart';
import '../../favourite_icon.dart';
import '../../../../../utils/constants/image_strings.dart';

class TSessionImageSlider extends StatelessWidget {
  const TSessionImageSlider({
    super.key,
    required this.session,
    this.selectedImage,
    this.onImageSelected,
  });

  final TutoringSession session;
  final String? selectedImage;
  final void Function(String image)? onImageSelected;

  String _tutorIconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('alice')) return TImages.tutorAlice;
    if (n.contains('bob')) return TImages.tutorBob;
    if (n.contains('carol')) return TImages.tutorCarol;
    // Fallback
    return TImages.tutorAlice;
  }

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;
    final images = controller.getAllSessionImages(session);

    final tutorName = session.tutor?.name ?? '';
    final mappedIcon = _tutorIconForName(tutorName);

    final filteredImages = images.where((img) => img != mappedIcon).toList();
    final visibleImages =
        filteredImages.length > 1 ? filteredImages.sublist(1) : <String>[];

    return TCurvedEdgesWidget(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            // Main Large Image
            SizedBox(
              height: 360,
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace * 1.5),
                child: Center(
                  child: Builder(
                    builder: (_) {
                      final image =
                          (selectedImage?.isNotEmpty ?? false)
                              ? selectedImage!
                              : (controller.selectedSessionImage.value.isEmpty
                                  ? session.thumbnail ?? ''
                                  : controller.selectedSessionImage.value);

                      final cleaned = THelperFunctions.normalizeImagePath(
                        image,
                      );

                      if (cleaned.isEmpty) {
                        return Image.asset(
                          TImages.tutorPromo1,
                          fit: BoxFit.contain,
                        );
                      }

                      if (THelperFunctions.isNetworkImagePath(image)) {
                        return Image.network(
                          cleaned,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          frameBuilder: (context, child, frame, _) {
                            if (frame == null) return const SizedBox.shrink();
                            return AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 180),
                              child: child,
                            );
                          },
                          errorBuilder:
                              (_, __, ___) => Image.asset(
                                TImages.tutorPromo1,
                                fit: BoxFit.contain,
                              ),
                        );
                      }

                      return Image.asset(cleaned, fit: BoxFit.contain);
                    },
                  ),
                ),
              ),
            ),

            // Small tutor icon
            Positioned(
              left: TSizes.defaultSpace,
              bottom: 30,
              child: GestureDetector(
                onTap: () {
                  if (onImageSelected != null) {
                    onImageSelected!(mappedIcon);
                  } else {
                    controller.selectedSessionImage.value = mappedIcon;
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: TColors.borderDark, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: TColors.textWhite,
                    child: ClipOval(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(mappedIcon, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Image Slider Thumbnails
            Positioned(
              right: 0,
              bottom: 30,
              left: TSizes.defaultSpace,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: visibleImages.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(width: TSizes.spaceBtwItems),
                  itemBuilder: (_, index) {
                    final imageSelected =
                        (selectedImage?.isNotEmpty ?? false)
                            ? selectedImage == visibleImages[index]
                            : controller.selectedSessionImage.value ==
                                visibleImages[index];

                    return TRoundedImage(
                      width: 80,
                      fit: BoxFit.contain,
                      imageUrl: visibleImages[index],
                      isNetworkImage: visibleImages[index].startsWith('http'),
                      padding: const EdgeInsets.all(TSizes.sm),
                      backgroundColor: TColors.darkBackground,
                      onPressed: () {
                        if (onImageSelected != null) {
                          onImageSelected!(visibleImages[index]);
                        } else {
                          controller.selectedSessionImage.value =
                              visibleImages[index];
                        }
                      },
                      border: Border.all(
                        color:
                            imageSelected
                                ? TColors.primary
                                : Colors.transparent,
                      ),
                    );
                  },
                ),
              ),
            ),

            // AppBar
            TAppBar(
              showBackArrow: true,
              actions: [TFavouriteIcon(sessionId: session.id)],
              showActions: true,
              showSkipButton: false,
            ),
          ],
        ),
      ),
    );
  }
}
