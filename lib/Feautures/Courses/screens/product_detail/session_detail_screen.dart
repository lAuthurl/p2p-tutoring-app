import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/rating_share_widget.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/session_meta_data.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/t_session_attributes.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/screens/product_detail/widgets/t_session_image_slider.dart';
import 'package:p2p_tutoring_app/models/ModelProvider.dart';
import 'package:readmore/readmore.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/device/device_utility.dart';
import '../../controllers/tutoring_controller.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, this.sessionIdFromCtor, this.session});

  final String? sessionIdFromCtor;
  final TutoringSession? session;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final tutoringController = Get.find<TutoringController>();
  TutoringSession? _resolvedSession;
  String? _error;

  String? _extractSessionId(dynamic args) {
    if (widget.sessionIdFromCtor != null &&
        widget.sessionIdFromCtor!.isNotEmpty) {
      return widget.sessionIdFromCtor;
    }
    if (args == null) return null;
    if (args is String) return args;
    if (args is Map) {
      return (args['sessionId'] ?? args['id'] ?? args['session']?['id'])
          ?.toString();
    }
    try {
      final dynamic maybeModel = args;
      return maybeModel.id;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    TutoringSession? sessionToShow = widget.session;

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

    // Initialize selected quantity and default attributes
    tutoringController.initializeAlreadySelectedQuantity(_resolvedSession!);

    final attrs = _resolvedSession!.sessionAttributes ?? [];
    for (final a in attrs) {
      if (a.name.toLowerCase() == 'mode' && (a.values?.isNotEmpty ?? false)) {
        tutoringController.selectedAttributes['Mode'] = 'Online';
      }
      if (a.name.toLowerCase() == 'duration' &&
          (a.values?.isNotEmpty ?? false)) {
        tutoringController.selectedAttributes['Duration'] = '1hr';
      }
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
            TSessionImageSlider(session: resolvedSession),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
                vertical: TSizes.defaultSpace / 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TRatingAndShare(),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  TProductMetaData(session: resolvedSession),
                  const SizedBox(height: TSizes.spaceBtwSections / 2),
                  if (resolvedSession.sessionVariations != null &&
                      (resolvedSession.sessionVariations?.isNotEmpty ?? false))
                    TSessionAttributes(
                      session: resolvedSession,
                      tutorId: resolvedSession.tutor?.id ?? '',
                    ),
                  if (resolvedSession.sessionVariations != null &&
                      (resolvedSession.sessionVariations?.isNotEmpty ?? false))
                    const SizedBox(height: TSizes.spaceBtwSections),
                  SizedBox(
                    width: TDeviceUtils.getScreenWidth(context),
                    child: ElevatedButton(
                      onPressed:
                          () => tutoringController.addSessionToBooking(
                            resolvedSession,
                          ),
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.all(TSizes.md),
                        ),
                        backgroundColor: WidgetStateProperty.all(
                          TColors.primary,
                        ),
                        overlayColor: WidgetStateProperty.all(
                          TColors.primary.withAlpha((0.12 * 255).round()),
                        ),
                        foregroundColor: WidgetStateProperty.all(
                          TColors.textWhite,
                        ),
                        shadowColor: WidgetStateProperty.all(
                          const Color(0xFF2C2060).withAlpha(50),
                        ),
                        elevation: WidgetStateProperty.resolveWith<double>(
                          (states) =>
                              states.contains(WidgetState.pressed) ? 2 : 4,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Book Session',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
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
