// ignore_for_file: public_member_api_docs, use_build_context_synchronously

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

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, this.sessionIdFromCtor, this.session});

  final String? sessionIdFromCtor;
  final TutoringSession? session;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late final TutoringController tutoringController;
  late final SessionCreationController sessionCreationController;
  TutoringSession? _session;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    tutoringController = Get.put(TutoringController(), permanent: true);
    sessionCreationController = Get.put(
      SessionCreationController(),
      permanent: true,
    );

    _resolveSession();
  }

  void _resolveSession() {
    // Prefer session passed via constructor
    _session = widget.session;

    // If null, try arguments or sessionId
    if (_session == null) {
      final args = Get.arguments;
      final sessionId = widget.sessionIdFromCtor ?? _extractSessionId(args);

      if (sessionId == null) {
        _error = 'No session provided';
        return;
      }

      try {
        _session = tutoringController.sessions.firstWhere(
          (s) => s.id == sessionId,
        );
      } catch (_) {
        _error = 'Session not found';
      }
    }

    if (_session != null) {
      _initializeSelectedAttributes(_session!);
    }
  }

  void _initializeSelectedAttributes(TutoringSession session) {
    final controller = sessionCreationController;

    // 1️⃣ Extract session-specific attributes from variations
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

    // 2️⃣ Default attributes
    final defaultAttrs = {
      "Mode": ["Online", "Offline"],
      "Duration": ["1hr", "2hr"],
      "Payment": ["Before Session", "After Session"],
    };

    // 3️⃣ Merge defaults with session-specific attributes
    final mergedAttrs = {...defaultAttrs, ...sessionAttrs};

    // 4️⃣ Initialize controller once
    controller.initializeAttributesForSession(mergedAttrs);
  }

  String? _extractSessionId(dynamic args) {
    if (args == null) return null;
    if (args is String) return args;
    if (args is Map) {
      return (args['sessionId'] ?? args['id'] ?? args['session']?['id'])
          ?.toString();
    }
    try {
      return args.id;
    } catch (_) {
      return null;
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

    final session = _session!;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider
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

                  // Meta: title, price, tutor info
                  TProductMetaData(session: session),
                  const SizedBox(height: TSizes.spaceBtwSections / 2),

                  // Session Attributes (interactive)
                  TSessionAttributes(session: session),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // Book button
                  SizedBox(
                    width: TDeviceUtils.getScreenWidth(context),
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedAttrs = Map<String, String>.from(
                          sessionCreationController.selectedAttributes,
                        );

                        tutoringController.addSessionToBooking(
                          session,
                          selectedAttributes: selectedAttrs,
                        );

                        Get.snackbar(
                          "Added to Booking",
                          "Session added with your selected options",
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.all(TSizes.md),
                        ),
                        backgroundColor: MaterialStateProperty.all(
                          TColors.primary,
                        ),
                        overlayColor: MaterialStateProperty.all(
                          TColors.primary.withAlpha((0.12 * 255).round()),
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          TColors.textWhite,
                        ),
                        shadowColor: MaterialStateProperty.all(
                          const Color(0xFF2C2060).withAlpha(50),
                        ),
                        elevation: MaterialStateProperty.resolveWith<double>(
                          (states) =>
                              states.contains(MaterialState.pressed) ? 2 : 4,
                        ),
                        shape: MaterialStateProperty.all(
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
                    session.description ?? 'No description provided.',
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

                  // Reviews
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
