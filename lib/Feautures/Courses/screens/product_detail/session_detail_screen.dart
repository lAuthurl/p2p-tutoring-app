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
import 't_session_review.dart';
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

  List<Review> _reviews = [];
  bool _loadingReviews = true;
  bool _isOwner = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tutoringController = Get.put(TutoringController(), tag: widget.tag);
    _creationController = Get.put(SessionCreationController(), tag: widget.tag);

    _initializeAttributes(widget.session);
    _fetchReviews();
    _checkOwnership();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (!mounted) return;
      setState(() => _currentUserId = user.userId);
    } catch (_) {
      if (mounted) setState(() => _currentUserId = null);
    }
  }

  /// Checks whether the logged-in user is the tutor who created this session.
  /// If so, the Chat button is replaced with an Inbox button.
  Future<void> _checkOwnership() async {
    final tutorId = await _tutoringController.currentUserTutorId;
    if (!mounted) return;
    setState(() {
      _isOwner = tutorId != null && tutorId == widget.session.tutor?.id;
    });
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
    final attributes = session.sessionAttributes ?? [];
    for (final attr in attributes) {
      if (attr.values != null && attr.values!.isNotEmpty) {
        sessionAttrs.putIfAbsent(attr.name, () => []);
        for (final val in attr.values!) {
          if (!sessionAttrs[attr.name]!.contains(val)) {
            sessionAttrs[attr.name]!.add(val);
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

  Future<void> _fetchReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await _tutoringController.fetchReviews(widget.session.id);
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
      });
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch reviews",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      setState(() => _loadingReviews = false);
    }
  }

  Future<Tutor?> _getTutorOrFetch(TutoringSession session) async {
    try {
      if (session.tutor != null) return session.tutor;

      final tutorId = session.tutor?.id;
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
    const buttonHeight = 56.0;
    TDeviceUtils.getScreenWidth(context);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      TRatingAndShare(reviews: _reviews),
                      const SizedBox(height: TSizes.spaceBtwItems / 2),
                      TProductMetaData(session: session, tag: widget.tag),
                      const SizedBox(height: TSizes.spaceBtwSections / 2),
                      TSessionAttributes(session: session),
                      const SizedBox(height: TSizes.spaceBtwSections / 2),

                      /// Tutor Profile & Chat Buttons
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
                              // Owners (tutors) go to their inbox.
                              // Students open their own private chat thread.
                              // chatId = sessionId + userId so each student
                              // gets an isolated conversation with the tutor.
                              onPressed: () {
                                if (_isOwner) {
                                  Get.to(() => const InboxScreen());
                                } else {
                                  if (_currentUserId == null) return;
                                  final chatId =
                                      '${session.id}_$_currentUserId';
                                  Get.to(
                                    () => ChatScreen(
                                      sessionId: chatId,
                                      sessionTitle: session.title,
                                      otherUserName:
                                          session.tutor?.name ?? 'Tutor',
                                    ),
                                  );
                                }
                              },
                              style: _outlinedButtonStyle(),
                              child: Text(
                                _isOwner ? "Go to Inbox" : "Chat",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),

                      /// Description
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
                        moreStyle: const TextStyle(fontWeight: FontWeight.bold),
                        lessStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections / 2),

                      /// Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const TSectionHeading(
                            title: "Reviews",
                            showActionButton: false,
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.arrow_right_3, size: 18),
                            onPressed: () async {
                              final updated = await Get.to(
                                () => SessionReviewScreen(session: session),
                              );
                              if (updated == true) _fetchReviews();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      _loadingReviews
                          ? const Center(child: CircularProgressIndicator())
                          : _reviews.isEmpty
                          ? const Text("No reviews yet.")
                          : Column(
                            children:
                                _reviews
                                    .map((r) => _buildReviewCard(r))
                                    .toList(),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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

  Future<void> _bookSession(TutoringSession session) async {
    try {
      final tutoringController = Get.find<TutoringController>(tag: widget.tag);
      await tutoringController.addSessionToBooking(
        session,
        selectedAttributes: Map<String, String>.from(
          tutoringController.selectedAttributes,
        ),
        quantity: 1,
      );
    } catch (e) {
      // Error handling removed (no snackbar)
    }
  }

  Widget _buildReviewCard(Review r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems / 2),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        r.user?.profilePicture != null &&
                                r.user!.profilePicture!.isNotEmpty
                            ? NetworkImage(r.user!.profilePicture!)
                            : null,
                    backgroundColor: TColors.primary,
                    child:
                        (r.user?.profilePicture == null ||
                                r.user!.profilePicture!.isEmpty)
                            ? Text(
                              r.user?.username[0].toUpperCase() ?? "?",
                              style: const TextStyle(color: Colors.white),
                            )
                            : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.user?.username ?? "Anonymous",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        size: 16,
                        color:
                            index < (r.rating)
                                ? Colors.amber
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.comment ?? ''),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  r.createdAt!.getDateTimeInUtc().toLocal().toString().split(
                    " ",
                  )[0],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlinedButtonStyle() => OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
    foregroundColor: TColors.primary,
    side: BorderSide(color: TColors.primary.withValues(alpha: 0.4)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
