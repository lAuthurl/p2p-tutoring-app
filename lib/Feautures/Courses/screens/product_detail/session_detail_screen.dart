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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    TDeviceUtils.getScreenWidth(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image slider (full bleed)
                TSessionImageSlider(session: session),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.defaultSpace,
                    vertical: TSizes.spaceBtwItems,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Rating & share ─────────────────────────────
                      TRatingAndShare(reviews: _reviews),
                      const SizedBox(height: 4),

                      // ── Title & price ──────────────────────────────
                      TProductMetaData(session: session, tag: widget.tag),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      // ── Session options ────────────────────────────
                      TSessionAttributes(session: session),
                      const SizedBox(height: TSizes.spaceBtwSections / 2),

                      // ── Tutor + Chat buttons ───────────────────────
                      _ActionRow(
                        isOwner: _isOwner,
                        currentUserId: _currentUserId,
                        session: session,
                        onTutorTap: () async {
                          final tutor = await _getTutorOrFetch(session);
                          if (tutor != null) {
                            Get.to(() => TutorProfileScreen(tutor: tutor));
                          }
                        },
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),

                      // ── Description ────────────────────────────────
                      _SectionLabel(title: "Description"),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.38,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ReadMoreText(
                          session.description ?? "No description provided.",
                          trimLines: 4,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: "  Show more",
                          trimExpandedText: "  Show less",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.65,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          moreStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            fontSize: 13,
                          ),
                          lessStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),

                      // ── Reviews ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _SectionLabel(title: "Reviews"),
                          TextButton.icon(
                            onPressed: () async {
                              final updated = await Get.to(
                                () => SessionReviewScreen(session: session),
                              );
                              if (updated == true) _fetchReviews();
                            },
                            icon: Icon(
                              Iconsax.star,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            label: Text(
                              "Write a review",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      if (_loadingReviews)
                        const Center(child: CircularProgressIndicator())
                      else if (_reviews.isEmpty)
                        _EmptyReviews(theme: theme, colorScheme: colorScheme)
                      else
                        Column(
                          children:
                              _reviews
                                  .take(3)
                                  .map(
                                    (r) => _ReviewCard(
                                      review: r,
                                      theme: theme,
                                      colorScheme: colorScheme,
                                    ),
                                  )
                                  .toList(),
                        ),

                      if (_reviews.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                final updated = await Get.to(
                                  () => SessionReviewScreen(session: session),
                                );
                                if (updated == true) _fetchReviews();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              child: Text("See all ${_reviews.length} reviews"),
                            ),
                          ),
                        ),

                      const SizedBox(height: TSizes.spaceBtwSections),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Book Session bar ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.09),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.defaultSpace,
                    vertical: 12,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _bookSession(session),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.calendar_add, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Book Session",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    // TSectionHeading import is kept — using it for the heading
    return TSectionHeading(title: title, showActionButton: false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tutor Profile + Chat action row
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isOwner,
    required this.currentUserId,
    required this.session,
    required this.onTutorTap,
  });

  final bool isOwner;
  final String? currentUserId;
  final TutoringSession session;
  final VoidCallback onTutorTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 13),
      foregroundColor: colorScheme.primary,
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.38)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTutorTap,
            icon: const Icon(Iconsax.profile_circle, size: 17),
            label: const Text("Tutor Profile"),
            style: buttonStyle,
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              if (isOwner) {
                Get.to(() => const InboxScreen());
              } else {
                if (currentUserId == null) return;
                Get.to(
                  () => ChatScreen(
                    sessionId: '${session.id}_$currentUserId',
                    sessionTitle: session.title,
                    otherUserName: session.tutor?.name ?? 'Tutor',
                  ),
                );
              }
            },
            icon: Icon(
              isOwner ? Iconsax.message_text : Iconsax.message,
              size: 17,
            ),
            label: Text(isOwner ? "Inbox" : "Chat"),
            style: buttonStyle,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty reviews placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.theme, required this.colorScheme});
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.star,
            size: 34,
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            "No reviews yet",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Be the first to share your experience",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review card
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.theme,
    required this.colorScheme,
  });

  final Review review;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final r = review;
    final hasAvatar =
        r.user?.profilePicture != null && r.user!.profilePicture!.isNotEmpty;
    final username = r.user?.username ?? "Anonymous";
    final initial = username.isNotEmpty ? username[0].toUpperCase() : "?";
    final dateStr =
        r.createdAt != null
            ? r.createdAt!.getDateTimeInUtc().toLocal().toString().split(" ")[0]
            : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: TColors.primary.withValues(alpha: 0.12),
                  backgroundImage:
                      hasAvatar ? NetworkImage(r.user!.profilePicture!) : null,
                  child:
                      hasAvatar
                          ? null
                          : Text(
                            initial,
                            style: TextStyle(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.38,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Star rating
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < r.rating.round();
                    return Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 15,
                      color:
                          filled
                              ? Colors.amber.shade600
                              : colorScheme.onSurface.withValues(alpha: 0.18),
                    );
                  }),
                ),
              ],
            ),

            // Comment bubble
            if ((r.comment ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.comment!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
