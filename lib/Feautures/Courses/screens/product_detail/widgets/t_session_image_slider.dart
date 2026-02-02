import 'package:flutter/material.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
import '../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/tutoring_controller.dart';
import '../../../models/tutoring_session_model.dart';
import '../../favourite_icon.dart';
import '../../../../../utils/constants/image_strings.dart';

class TSessionImageSlider extends StatelessWidget {
  const TSessionImageSlider({
    super.key,
    required this.session,
    this.selectedImage,
    this.onImageSelected,
  });

  final TutoringSessionModel session;
  final String? selectedImage;
  final void Function(String image)? onImageSelected;

  String _tutorIconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('alice')) return TImages.tutorAlice;
    if (n.contains('bob')) return TImages.tutorBob;
    if (n.contains('carol')) return TImages.tutorCarol;
    // Fallback: use tutorAlice as default
    return TImages.tutorAlice;
  }

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;
    final images = controller.getAllSessionImages(session);
    final mappedIcon = _tutorIconForName(session.tutor?.name ?? '');
    final filteredImages = images.where((img) => img != mappedIcon).toList();
    // Remove the first thumbnail (rounded rectangle) so it doesn't appear under the left icon
    final visibleImages =
        filteredImages.length > 1 ? filteredImages.sublist(1) : <String>[];

    return TCurvedEdgesWidget(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            /// Main Large Image
            SizedBox(
              height: 360,
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace * 1.5),
                child: Center(
                  child: Builder(
                    builder: (_) {
                      final image =
                          (selectedImage != null && selectedImage!.isNotEmpty)
                              ? selectedImage!
                              : (controller.selectedSessionImage.value.isEmpty
                                  ? session.thumbnail
                                  : controller.selectedSessionImage.value);
                      return GestureDetector(
                        onTap: () => controller.showEnlargedImage(image),
                        child: Builder(
                          builder: (_) {
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
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                frameBuilder: (
                                  context,
                                  child,
                                  frame,
                                  wasSynchronouslyLoaded,
                                ) {
                                  if (frame == null)
                                    return const SizedBox.shrink();
                                  return AnimatedOpacity(
                                    opacity: 1,
                                    duration: Duration(milliseconds: 180),
                                    child: child,
                                  );
                                },
                                errorBuilder:
                                    (context, error, stackTrace) => Image.asset(
                                      TImages.tutorPromo1,
                                      fit: BoxFit.contain,
                                    ),
                              );
                            }
                            return Image.asset(cleaned, fit: BoxFit.contain);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            /// Small tutor icon (aligned with thumbnails)
            Positioned(
              left: TSizes.defaultSpace,
              bottom: 30,
              child: GestureDetector(
                onTap: () {
                  final mapped = _tutorIconForName(session.tutor?.name ?? '');
                  if (onImageSelected != null) {
                    onImageSelected!(mapped);
                  } else {
                    controller.selectedSessionImage.value = mapped;
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
                        child: Image.asset(
                          _tutorIconForName(session.tutor?.name ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Image Slider Thumbnails
            Positioned(
              right: 0,
              bottom: 30,
              left: TSizes.defaultSpace,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: visibleImages.length,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  separatorBuilder:
                      (context, index) =>
                          const SizedBox(width: TSizes.spaceBtwItems),
                  itemBuilder: (_, index) {
                    return Builder(
                      builder: (_) {
                        final imageSelected =
                            (selectedImage != null && selectedImage!.isNotEmpty)
                                ? selectedImage == visibleImages[index]
                                : controller.selectedSessionImage.value ==
                                    visibleImages[index];
                        return TRoundedImage(
                          width: 80,
                          fit: BoxFit.contain,
                          imageUrl: visibleImages[index],
                          isNetworkImage: visibleImages[index].startsWith(
                            'http',
                          ),
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
                    );
                  },
                ),
              ),
            ),

            /// AppBar Icons
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
