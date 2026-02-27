// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../controllers/session_creation_controller.dart';
import '../../controllers/tutoring_controller.dart';
import '../../../Courses/screens/product_detail/widgets/rating_share_widget.dart';
import '../../../Courses/screens/product_detail/widgets/session_meta_data.dart';
import '../../../Courses/screens/product_detail/widgets/t_session_attributes.dart';
import '../../../Courses/screens/product_detail/widgets/t_session_image_slider.dart';
import '../../../../models/ModelProvider.dart';
import 'chat.dart';
import 'tutor_profile.dart';

class SessionDetailScreen extends StatefulWidget {
  final TutoringSession session;
  final String tag;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.tag,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late final TutoringController _tutoringController;
  late final SessionCreationController _creationController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with per-screen tag
    _tutoringController = Get.put(TutoringController(), tag: widget.tag);
    _creationController = Get.put(SessionCreationController(), tag: widget.tag);

    _initializeAttributes(widget.session);
  }

  @override
  void dispose() {
    if (Get.isRegistered<TutoringController>(tag: widget.tag)) {
      Get.delete<TutoringController>(tag: widget.tag);
    }
    if (Get.isRegistered<SessionCreationController>(tag: widget.tag)) {
      Get.delete<SessionCreationController>(tag: widget.tag);
    }
    super.dispose();
  }

  void _initializeAttributes(TutoringSession session) {
    final sessionAttrs = <String, List<String>>{};
    final variations = session.sessionVariations ?? [];

    for (final variation in variations) {
      final attrs = variation.sessionAttributes ?? [];
      for (final attr in attrs) {
        if (attr.values != null && attr.values!.isNotEmpty) {
          sessionAttrs.putIfAbsent(attr.name, () => []);
          for (final val in attr.values!) {
            if (!sessionAttrs[attr.name]!.contains(val)) {
              sessionAttrs[attr.name]!.add(val);
            }
          }
        }
      }
    }

    const defaultAttrs = {
      "Mode": ["Online", "Offline"],
      "Duration": ["1hr", "2hr"],
      "Payment": ["Before Session", "After Session"],
    };

    final merged = {...defaultAttrs, ...sessionAttrs};
    _creationController.initializeAttributesForSession(merged);
  }

  Future<Tutor?> _getTutorOrFetch(TutoringSession session) async {
    try {
      if (session.tutor != null) return session.tutor;

      final tutorId = (session.tutor != null) ? session.tutor!.id : null;

      if (tutorId != null && tutorId.isNotEmpty) {
        final tutors = await Amplify.DataStore.query(
          Tutor.classType,
          where: Tutor.ID.eq(tutorId),
        );
        if (tutors.isNotEmpty) return tutors.first;
      }

      Get.snackbar(
        "Error",
        "Tutor information not available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );

      return null;
    } catch (e, st) {
      safePrint("❌ Failed to fetch tutor for session ${session.id}: $e\n$st");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    TDeviceUtils.getScreenWidth(context);
    const buttonHeight = 56.0;

    // Wrap the entire reactive portion in a single Obx
    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: buttonHeight + TSizes.spaceBtwItems,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TSessionImageSlider(session: session),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.defaultSpace,
                      vertical: TSizes.defaultSpace / 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TRatingAndShare(),
                        const SizedBox(height: TSizes.spaceBtwItems / 2),

                        // Pass normal Map, child handles price calculation
                        TProductMetaData(
                          session: session,
                          selectedAttributes: Map<String, String>.from(
                            _creationController.selectedAttributes,
                          ), // convert RxMap -> normal Map here
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections / 2),
                        TSessionAttributes(session: session),
                        const SizedBox(height: TSizes.spaceBtwSections / 2),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final tutor = await _getTutorOrFetch(session);
                                  if (tutor != null) {
                                    Get.to(
                                      () => TutorProfileScreen(tutor: tutor),
                                    );
                                  }
                                },
                                style: _outlinedButtonStyle(),
                                child: const Text(
                                  "Tutor Profile",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: TSizes.spaceBtwItems),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final tutor = await _getTutorOrFetch(session);
                                  if (tutor != null) {
                                    Get.to(
                                      () => ChatScreen(
                                        tutor: tutor,
                                        sessionId: session.id,
                                      ),
                                    );
                                  }
                                },
                                style: _outlinedButtonStyle(),
                                child: const Text(
                                  "Chat",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections),
                        const SizedBox(height: TSizes.spaceBtwSections / 2),

                        const TSectionHeading(
                          title: "Description",
                          showActionButton: false,
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        ReadMoreText(
                          session.description ?? "No description provided.",
                          trimLines: 3,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: " Show more",
                          trimExpandedText: " Less",
                          moreStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          lessStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections / 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const TSectionHeading(
                              title: "Reviews",
                              showActionButton: false,
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.arrow_right_3, size: 18),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          /// Book Session Button
          Positioned(
            bottom: -8,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _bookSession(session),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      padding: const EdgeInsets.all(TSizes.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Book Session",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: TColors.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bookSession(TutoringSession session) {
    _tutoringController.addSessionToBooking(
      session,
      selectedAttributes: Map<String, String>.from(
        _creationController.selectedAttributes,
      ),
    );

    Get.snackbar(
      "Added to Booking",
      "Session added with your selected options",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  ButtonStyle _outlinedButtonStyle() => OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
    foregroundColor: TColors.primary,
    side: BorderSide(color: TColors.primary.withOpacity(0.4)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
