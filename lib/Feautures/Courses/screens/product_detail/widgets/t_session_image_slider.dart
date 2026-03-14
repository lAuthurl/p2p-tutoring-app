// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
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

  Widget _tutorAvatar(Tutor? tutor) {
    if (tutor == null) {
      return _InitialsAvatar(initials: '?');
    }
    if (tutor.image != null && tutor.image!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        child: ClipOval(
          child: SizedBox(
            width: 44,
            height: 44,
            child:
                tutor.image!.startsWith('http')
                    ? Image.network(
                      tutor.image!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, _, _) =>
                              _InitialsAvatar(initials: _initials(tutor.name)),
                    )
                    : Image.asset(tutor.image!, fit: BoxFit.cover),
          ),
        ),
      );
    }
    return _InitialsAvatar(initials: _initials(tutor.name));
  }

  String _initials(String name) =>
      name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final controller = TutoringController.instance;
    final images = controller.getAllSessionImages(session);
    final filteredImages =
        images.where((img) => img != session.tutor?.image).toList();
    final visibleImages =
        filteredImages.length > 1 ? filteredImages.sublist(1) : <String>[];
    final tutorName = session.tutor?.name ?? '';

    return TCurvedEdgesWidget(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            // ── Hero image ──────────────────────────────────────────
            SizedBox(
              height: 380,
              width: double.infinity,
              child: Builder(
                builder: (_) {
                  final image =
                      (selectedImage?.isNotEmpty ?? false)
                          ? selectedImage!
                          : (controller.selectedSessionImage.value.isEmpty
                              ? session.thumbnail ?? ''
                              : controller.selectedSessionImage.value);
                  final cleaned = THelperFunctions.normalizeImagePath(image);

                  if (cleaned.isEmpty) {
                    return Image.asset(
                      TImages.tutorPromo1,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  }

                  if (THelperFunctions.isNetworkImagePath(image)) {
                    return Image.network(
                      cleaned,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 220),
                            child: child,
                          );
                        }
                        return _ShimmerPlaceholder();
                      },
                      errorBuilder:
                          (_, _, _) => Image.asset(
                            TImages.tutorPromo1,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                    );
                  }

                  return Image.asset(
                    cleaned,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),

            // ── Bottom gradient overlay ─────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tutor chip + thumbnails row ────────────────────────
            Positioned(
              left: TSizes.defaultSpace,
              right: TSizes.defaultSpace,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tutor avatar + name chip
                  GestureDetector(
                    onTap: () {
                      if (onImageSelected != null) {
                        onImageSelected!(session.tutor?.image ?? '');
                      } else {
                        controller.selectedSessionImage.value =
                            session.tutor?.image ?? '';
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _tutorAvatar(session.tutor),
                          if (tutorName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                tutorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Thumbnails
                  if (visibleImages.isNotEmpty)
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final isSelected =
                                (selectedImage?.isNotEmpty ?? false)
                                    ? selectedImage == visibleImages[index]
                                    : controller.selectedSessionImage.value ==
                                        visibleImages[index];

                            return _ThumbTile(
                              imageUrl: visibleImages[index],
                              isSelected: isSelected,
                              onTap: () {
                                if (onImageSelected != null) {
                                  onImageSelected!(visibleImages[index]);
                                } else {
                                  controller.selectedSessionImage.value =
                                      visibleImages[index];
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── AppBar ─────────────────────────────────────────────
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

// ── Thumbnail tile ────────────────────────────────────────────────────────────
class _ThumbTile extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbTile({
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 60,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? TColors.primary
                    : Colors.white.withValues(alpha: 0.25),
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: TColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ]
                  : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isSelected ? 1.0 : 0.6,
            child:
                imageUrl.startsWith('http')
                    ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder:
                          (_, _, _) => Container(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                    )
                    : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
          ),
        ),
      ),
    );
  }
}

// ── Initials avatar ───────────────────────────────────────────────────────────
class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: TColors.primary,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────
class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.withValues(alpha: _anim.value),
          ),
    );
  }
}
