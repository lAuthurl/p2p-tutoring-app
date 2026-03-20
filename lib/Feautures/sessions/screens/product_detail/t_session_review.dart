// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../models/ModelProvider.dart';
import '../../controllers/tutoring_controller.dart';

class SessionReviewScreen extends StatefulWidget {
  final TutoringSession session;

  const SessionReviewScreen({super.key, required this.session});

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  final TutoringController _tutoringController = Get.find();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;

  late TutoringSession _currentSession;
  List<Review> _reviews = [];
  bool _loading = true;
  bool _submitting = false;

  // Whether the currently signed-in user is the creator of this session.
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _fetchReviews();
    _checkIfCreator();
  }

  // ── Determine if the current user is the session creator ─────────────────
  Future<void> _checkIfCreator() async {
    try {
      final tutorId = await _tutoringController.currentUserTutorId;
      if (!mounted) return;
      setState(() {
        _isCreator = tutorId != null && tutorId == _currentSession.tutor?.id;
      });
    } catch (_) {}
  }

  Future<void> _fetchReviews() async {
    setState(() => _loading = true);
    try {
      final reviews = await _tutoringController.fetchReviews(
        _currentSession.id,
      );
      reviews.sort((a, b) {
        final aIsCreator =
            a.user?.email != null &&
            a.tutor?.email != null &&
            a.user!.email == a.tutor!.email;
        final bIsCreator =
            b.user?.email != null &&
            b.tutor?.email != null &&
            b.user!.email == b.tutor!.email;
        if (aIsCreator != bIsCreator) return aIsCreator ? -1 : 1;
        final aDate = a.createdAt?.getDateTimeInUtc() ?? DateTime(0);
        final bDate = b.createdAt?.getDateTimeInUtc() ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      setState(() {
        _reviews = reviews;
        _loading = false;
      });
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch reviews",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    // ✅ Creators don't need a star rating — a comment alone is enough.
    //    Everyone else must supply both a rating and a comment.
    if (!_isCreator && _rating == 0) {
      Get.snackbar(
        "Rating required",
        "Please select a star rating before submitting",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (comment.isEmpty) {
      Get.snackbar(
        "Comment required",
        "Please write a comment before submitting",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Resolve tutor if the lazy BelongsTo stub is null.
      if (_currentSession.tutor == null) {
        final tutorId = _currentSession.tutor?.id;
        if (tutorId != null && tutorId.isNotEmpty) {
          final tutors = await Amplify.DataStore.query(
            Tutor.classType,
            where: Tutor.ID.eq(tutorId),
          );
          if (tutors.isNotEmpty) {
            _currentSession = _currentSession.copyWith(tutor: tutors.first);
          } else {
            throw Exception("Tutor not found");
          }
        } else {
          throw Exception("Session has no tutor assigned");
        }
      }

      // Creators submit with rating = 0 (no stars shown/required).
      // Regular reviewers submit with the rating they selected.
      await _tutoringController.addReview(
        session: _currentSession,
        rating: _isCreator ? 0 : _rating,
        comment: comment,
      );

      final updatedReviews = await _tutoringController.fetchReviews(
        _currentSession.id,
      );

      setState(() {
        _reviews = updatedReviews;
        _rating = 0;
        _commentController.clear();
        _submitting = false;
      });

      Get.snackbar(
        "Success",
        "Review submitted successfully",
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back(result: true);
    } catch (e) {
      setState(() => _submitting = false);
      Get.snackbar(
        "Error",
        "Failed to submit review: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double get _averageRating {
    // Exclude creator reviews (rating == 0) from the average.
    final ratedReviews = _reviews.where((r) => r.rating > 0).toList();
    if (ratedReviews.isEmpty) return 0;
    return ratedReviews.fold<double>(0, (sum, r) => sum + r.rating) /
        ratedReviews.length;
  }

  // Count only reviews that have a rating for the summary display.
  int get _ratedReviewCount => _reviews.where((r) => r.rating > 0).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Reviews"),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary hero ──────────────────────────────────────
                    _RatingSummaryCard(
                      averageRating: _averageRating,
                      reviewCount: _ratedReviewCount,
                      totalReviewCount: _reviews.length,
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // ── Write a review ────────────────────────────────────
                    _WriteReviewCard(
                      rating: _rating,
                      commentController: _commentController,
                      submitting: _submitting,
                      isCreator: _isCreator,
                      colorScheme: colorScheme,
                      theme: theme,
                      onRatingUpdate: (r) => setState(() => _rating = r),
                      onSubmit: _submitReview,
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // ── All reviews ───────────────────────────────────────
                    if (_reviews.isNotEmpty) ...[
                      Text(
                        "All Reviews",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      ..._reviews.map(
                        (r) => _ReviewTile(
                          review: r,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating summary hero card
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.averageRating,
    required this.reviewCount,
    required this.totalReviewCount,
    required this.colorScheme,
    required this.theme,
  });

  final double averageRating;
  // Number of reviews that carry a star rating.
  final int reviewCount;
  // Total reviews including creator comments with no rating.
  final int totalReviewCount;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child:
          totalReviewCount == 0
              ? Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 40,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No reviews yet",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Be the first to leave a review",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  // Show average only if there are rated reviews.
                  if (reviewCount > 0) ...[
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reviewCount > 0)
                        RatingBarIndicator(
                          rating: averageRating,
                          itemBuilder:
                              (context, _) => Icon(
                                Icons.star_rounded,
                                color: Colors.amber.shade600,
                              ),
                          itemCount: 5,
                          itemSize: 22,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        reviewCount > 0
                            ? "$reviewCount rated · $totalReviewCount total ${totalReviewCount == 1 ? 'review' : 'reviews'}"
                            : "$totalReviewCount ${totalReviewCount == 1 ? 'review' : 'reviews'}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Write a review card
// ─────────────────────────────────────────────────────────────────────────────

class _WriteReviewCard extends StatelessWidget {
  const _WriteReviewCard({
    required this.rating,
    required this.commentController,
    required this.submitting,
    required this.isCreator,
    required this.colorScheme,
    required this.theme,
    required this.onRatingUpdate,
    required this.onSubmit,
  });

  final double rating;
  final TextEditingController commentController;
  final bool submitting;
  // When true, the star rating row is hidden and not required.
  final bool isCreator;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final ValueChanged<double> onRatingUpdate;
  final VoidCallback onSubmit;

  String get _ratingLabel {
    if (rating == 0) return "Tap to rate";
    if (rating <= 1) return "Poor";
    if (rating <= 2) return "Fair";
    if (rating <= 3) return "Good";
    if (rating <= 4) return "Very Good";
    return "Excellent!";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Write a Review",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCreator
                ? "Share a note about your session with students."
                : "Share your experience with other students.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),

          // ── Star rating row — hidden for creators ─────────────────────
          if (!isCreator) ...[
            Row(
              children: [
                RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 36,
                  unratedColor: colorScheme.onSurface.withValues(alpha: 0.15),
                  itemBuilder:
                      (context, _) => Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade600,
                      ),
                  onRatingUpdate: onRatingUpdate,
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _ratingLabel,
                    key: ValueKey(_ratingLabel),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          rating > 0
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight:
                          rating > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Creator badge note ────────────────────────────────────────
          if (isCreator) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: TColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 15,
                    color: TColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "As the session creator, your comment will be pinned at the top.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Comment field ─────────────────────────────────────────────
          TextField(
            controller: commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  isCreator
                      ? "Add a note for your students..."
                      : "What did you think of this session?",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.35),
                fontSize: 14,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),

          // ── Submit button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: TColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child:
                  submitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        "Submit Review",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
// Individual review tile
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.theme,
    required this.colorScheme,
  });

  final Review review;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final date =
        review.createdAt != null
            ? DateFormat.yMMMd().format(review.createdAt!.getDateTimeInUtc())
            : '';
    final username = review.user?.username ?? "Anonymous";
    final initial = username.isNotEmpty ? username[0].toUpperCase() : "?";
    final hasAvatar = review.user?.profilePicture?.isNotEmpty ?? false;

    final isCreator =
        review.user?.email != null &&
        review.tutor?.email != null &&
        review.user!.email == review.tutor!.email;

    // A creator review has no star rating (stored as 0).
    final hasRating = review.rating > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isCreator
                  ? TColors.primary.withValues(alpha: 0.05)
                  : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isCreator
                    ? TColors.primary.withValues(alpha: 0.25)
                    : colorScheme.outline.withValues(alpha: 0.15),
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
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: TColors.primary.withValues(alpha: 0.15),
                  backgroundImage:
                      hasAvatar
                          ? NetworkImage(review.user!.profilePicture!)
                          : null,
                  child:
                      hasAvatar
                          ? null
                          : Text(
                            initial,
                            style: TextStyle(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                ),
                const SizedBox(width: 10),

                // Name + creator tag + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              username,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCreator) ...[
                            const SizedBox(width: 6),
                            _CreatorTag(colorScheme: colorScheme),
                          ],
                        ],
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ),

                // Stars — only shown when there is an actual rating.
                if (hasRating)
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < review.rating.round();
                      return Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color:
                            filled
                                ? Colors.amber.shade600
                                : colorScheme.onSurface.withValues(alpha: 0.2),
                      );
                    }),
                  ),
              ],
            ),

            if ((review.comment ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  review.comment!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
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

// ─────────────────────────────────────────────────────────────────────────────
// Creator tag badge
// ─────────────────────────────────────────────────────────────────────────────

class _CreatorTag extends StatelessWidget {
  const _CreatorTag({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: TColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Creator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
