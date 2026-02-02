import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/rating_share_widget.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/session_meta_data.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/t_session_attributes.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/t_session_image_slider.dart';
import 'package:readmore/readmore.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/device/device_utility.dart';
import '../../controllers/tutoring_controller.dart';
import '../../models/tutoring_session_model.dart'; // adjust if your model path/name differs
import '../../models/session_attribute_model.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, this.sessionIdFromCtor, this.session});

  final String? sessionIdFromCtor;
  final TutoringSessionModel? session;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final tutoringController = Get.find<TutoringController>();
  TutoringSessionModel? _resolvedSession;
  String? _error;

  // Helper to safely extract an id from Get.arguments (or constructor)
  String? _extractSessionId(dynamic args) {
    if (widget.sessionIdFromCtor != null &&
        widget.sessionIdFromCtor!.isNotEmpty) {
      return widget.sessionIdFromCtor;
    }
    if (args == null) return null;
    if (args is String) return args;
    if (args is Map) {
      // safe access - do not call [] on non-map
      return (args['sessionId'] ?? args['id'] ?? args['session']?['id'])
          ?.toString();
    }
    // If a SessionModel (or similar) was passed
    try {
      final dynamic maybeModel = args;
      final id = maybeModel.id;
      return id?.toString();
    } catch (_) {
      // args was neither a String, Map nor model with id property
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    // Resolve the session now so we can initialize controller state before first build
    final args = Get.arguments;
    TutoringSessionModel? sessionToShow = widget.session;

    if (sessionToShow == null) {
      final sessionId = _extractSessionId(args);
      if (sessionId == null) {
        _error = 'No session provided';
        return;
      }

      try {
        sessionToShow = tutoringController.sessions.firstWhere(
          (s) => s.id == sessionId,
        );
      } catch (_) {
        sessionToShow = null;
      }

      if (sessionToShow == null) {
        _error = 'Session not found';
        return;
      }
    }

    _resolvedSession = sessionToShow;

    // Initialize selection state synchronously before first build so the price and image
    // shown on the detail screen reflect this session (avoids showing stale values).
    tutoringController.initializeAlreadySelectedQuantity(_resolvedSession!);

    // Ensure default attribute selections: 'Mode' -> Online and 'Duration' -> 1hr when available
    // Use safe lookups without referring to SessionAttributeModel directly
    final attrs = _resolvedSession!.sessionAttributes ?? [];

    SessionAttributeModel? modeAttr;
    for (final a in attrs) {
      if (a.name.toLowerCase() == 'mode') {
        modeAttr = a;
        break;
      }
    }
    if (modeAttr != null && modeAttr.values.isNotEmpty) {
      tutoringController.selectedAttributes['Mode'] = 'Online';
    }

    SessionAttributeModel? durationAttr;
    for (final a in attrs) {
      if (a.name.toLowerCase() == 'duration') {
        durationAttr = a;
        break;
      }
    }
    if (durationAttr != null && durationAttr.values.isNotEmpty) {
      tutoringController.selectedAttributes['Duration'] = '1hr';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: Center(child: Text(_error!)),
      );
    }

    final resolvedSession = _resolvedSession!;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1 - Session Image Slider
            TSessionImageSlider(session: resolvedSession),

            /// 2 - Session Details
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
                // reduced vertical padding to bring content up closer to thumbnails
                vertical: TSizes.defaultSpace / 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// - Rating & Share
                  const TRatingAndShare(),

                  const SizedBox(height: TSizes.spaceBtwItems / 2),

                  /// - Price, Title, Seats, & Tutor
                  TProductMetaData(session: resolvedSession),
                  const SizedBox(height: TSizes.spaceBtwSections / 2),

                  /// -- Attributes
                  if (resolvedSession.sessionVariations != null &&
                      resolvedSession.sessionVariations!.isNotEmpty)
                    TSessionAttributes(session: resolvedSession),
                  if (resolvedSession.sessionVariations != null &&
                      resolvedSession.sessionVariations!.isNotEmpty)
                    const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- Checkout / Add-to-Booking Button
                  SizedBox(
                    width: TDeviceUtils.getScreenWidth(context),
                    child: ElevatedButton(
                      onPressed:
                          () => tutoringController.addSessionToBooking(
                            resolvedSession,
                          ),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.all(TSizes.md),
                        ),
                        backgroundColor: MaterialStateProperty.resolveWith(
                          (states) => const Color(0xFF2C2060),
                        ),
                        overlayColor: MaterialStateProperty.resolveWith(
                          (states) => const Color(0xFF2C2060).withOpacity(0.12),
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          TColors.textWhite,
                        ),
                      ),
                      child: const Text('Book Session'),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// - Description
                  const TSectionHeading(
                    title: 'Description',
                    showActionButton: false,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  ReadMoreText(
                    resolvedSession.description ?? 'No description provided.',
                    trimLines: 2,
                    colorClickableText: Colors.pink,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' Show more',
                    trimExpandedText: ' Less',
                    moreStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    lessStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// - Reviews
                  const Divider(),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const TSectionHeading(
                        title: 'Reviews (199)',
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
      ),
    );
  }
}
