// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide Transition;
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../models/ModelProvider.dart';
import '../../controllers/tutoring_controller.dart';
import 'tutor_report_screen.dart';

class TutorProfileScreen extends StatefulWidget {
  final Tutor tutor;
  const TutorProfileScreen({super.key, required this.tutor});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  final TutoringController _tutoringController = Get.find();

  List<Review> _reviews = [];
  bool _loadingReviews = true;

  static const int _initialReviewCount = 5;
  bool _showAllReviews = false;

  // ✅ Reactive tutor — keeps about/skills/image in sync with DataStore
  //    without requiring a full navigation push.
  late final Rx<Tutor> _tutor;
  StreamSubscription<dynamic>? _tutorSubscription;

  String? get _reportReason =>
      _tutoringController.getReportReason(widget.tutor.id);

  @override
  void initState() {
    super.initState();
    _tutor = widget.tutor.obs;
    _fetchTutorReviews();
    _observeTutor();
  }

  @override
  void dispose() {
    _tutorSubscription?.cancel();
    super.dispose();
  }

  // ── Watch DataStore for changes to this tutor ────────────────────────────
  // observeQuery fires on ANY local DataStore.save() — unlike observe() which
  // only fires on remote AppSync sync events. This means the screen updates
  // the moment updateUserProfile() saves the Tutor record locally, with no
  // navigation or manual refresh required.
  void _observeTutor() {
    try {
      _tutorSubscription = Amplify.DataStore.observeQuery(
        Tutor.classType,
        where: Tutor.ID.eq(widget.tutor.id),
      ).listen((snapshot) {
        if (!mounted) return;
        if (snapshot.items.isNotEmpty) {
          _tutor.value = snapshot.items.first;
        }
      });
    } catch (e) {
      debugPrint('⚠️ TutorProfileScreen: could not observeQuery tutor: $e');
    }
  }

  // ── Reviews ───────────────────────────────────────────────────────────────
  Future<void> _fetchTutorReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await _tutoringController.fetchReviewsByTutor(
        widget.tutor.id,
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
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _loadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching tutor reviews: $e');
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  // Only rated reviews count toward the average.
  double get _averageRating {
    final rated = _reviews.where((r) => r.rating > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.fold<double>(0, (sum, r) => sum + r.rating) / rated.length;
  }

  int get _ratedCount => _reviews.where((r) => r.rating > 0).length;

  void _openReportScreen() async {
    final result = await Get.to<String>(
      () => TutorReportScreen(tutorName: widget.tutor.name),
      transition: Transition.downToUp,
    );
    if (result != null && result.isNotEmpty && mounted) {
      _tutoringController.reportTutor(widget.tutor.id, result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final visibleReviews =
        _showAllReviews
            ? _reviews
            : _reviews.take(_initialReviewCount).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F14) : const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: TColors.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.flag_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: 'Report tutor',
                onPressed: _openReportScreen,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TColors.primary,
                          TColors.primary.withValues(alpha: 0.75),
                          isDark
                              ? const Color(0xFF0F0F14)
                              : const Color(0xFFF6F7FB),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: TSizes.defaultSpace,
                    right: TSizes.defaultSpace,
                    // ✅ Obx wraps the hero content so name/image/rating
                    //    update automatically when the tutor record changes.
                    child: Obx(() {
                      final tutor = _tutor.value;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  tutor.image?.isNotEmpty == true
                                      ? NetworkImage(tutor.image!)
                                      : null,
                              child:
                                  tutor.image?.isNotEmpty != true
                                      ? Text(
                                        tutor.name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: TColors.primary,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Name + email + rating
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tutor.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tutor.email,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _loadingReviews
                                    ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Row(
                                      children: [
                                        RatingBarIndicator(
                                          rating: _averageRating,
                                          itemBuilder:
                                              (context, _) => const Icon(
                                                Icons.star_rounded,
                                                color: Colors.amber,
                                              ),
                                          itemCount: 5,
                                          itemSize: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _ratedCount > 0
                                              ? "${_averageRating.toStringAsFixed(1)}  ·  $_ratedCount ${_ratedCount == 1 ? 'review' : 'reviews'}"
                                              : _reviews.isNotEmpty
                                              ? "${_reviews.length} ${_reviews.length == 1 ? 'comment' : 'comments'}"
                                              : "No reviews yet",
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TSizes.defaultSpace,
                20,
                TSizes.defaultSpace,
                100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Under Investigation Banner ────────────────────
                  if (_reportReason != null) ...[
                    _InvestigationBanner(reason: _reportReason!),
                    const SizedBox(height: 20),
                  ],

                  // ── Rating Summary Card ───────────────────────────
                  if (!_loadingReviews && _reviews.isNotEmpty) ...[
                    _RatingSummaryCard(
                      averageRating: _averageRating,
                      ratedCount: _ratedCount,
                      totalCount: _reviews.length,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── About — reactive via Obx ──────────────────────
                  Obx(() {
                    final about = _tutor.value.about;
                    final aboutText =
                        about?.isNotEmpty == true
                            ? about!
                            : "No information provided by this tutor.";
                    return _SectionCard(
                      icon: Icons.person_outline_rounded,
                      title: 'About',
                      child: Text(
                        aboutText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Skills — reactive via Obx ─────────────────────
                  Obx(() {
                    final skills = _tutor.value.skills;
                    final skillsList =
                        skills?.isNotEmpty == true ? skills! : <String>[];
                    return _SectionCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Skills',
                      child:
                          skillsList.isNotEmpty
                              ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    skillsList
                                        .map((s) => _SkillChip(label: s))
                                        .toList(),
                              )
                              : Text(
                                "No skills added yet.",
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Reviews ───────────────────────────────────────
                  _SectionCard(
                    icon: Icons.reviews_outlined,
                    title:
                        _reviews.isNotEmpty
                            ? 'Reviews  (${_reviews.length})'
                            : 'Reviews',
                    child:
                        _loadingReviews
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : _reviews.isEmpty
                            ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.rate_review_outlined,
                                    size: 20,
                                    color:
                                        isDark
                                            ? Colors.white24
                                            : Colors.black26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "No reviews yet.",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color:
                                          isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Column(
                              children: [
                                ...visibleReviews.map(
                                  (r) => _ReviewTile(review: r, isDark: isDark),
                                ),
                                if (_reviews.length > _initialReviewCount)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                _showAllReviews =
                                                    !_showAllReviews,
                                          ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: TColors.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _showAllReviews
                                                  ? 'Show less'
                                                  : 'Show all ${_reviews.length} reviews',
                                              style: TextStyle(
                                                color: TColors.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              _showAllReviews
                                                  ? Icons
                                                      .keyboard_arrow_up_rounded
                                                  : Icons
                                                      .keyboard_arrow_down_rounded,
                                              color: TColors.primary,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          TSizes.defaultSpace,
          12,
          TSizes.defaultSpace,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _openReportScreen,
              icon: const Icon(
                Icons.flag_rounded,
                size: 18,
                color: Colors.redAccent,
              ),
              label: const Text(
                'Report',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Book Session',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rating Summary Card ───────────────────────────────────────────────────────
class _RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int ratedCount;
  final int totalCount;
  final bool isDark;

  const _RatingSummaryCard({
    required this.averageRating,
    required this.ratedCount,
    required this.totalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (ratedCount > 0) ...[
            Text(
              averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: TColors.primary,
                height: 1,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ratedCount > 0)
                RatingBarIndicator(
                  rating: averageRating,
                  itemBuilder:
                      (context, _) =>
                          const Icon(Icons.star_rounded, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 22,
                ),
              const SizedBox(height: 4),
              Text(
                ratedCount > 0
                    ? '$ratedCount rated · $totalCount total across all sessions'
                    : '$totalCount ${totalCount == 1 ? 'comment' : 'comments'} across all sessions',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Investigation Banner ──────────────────────────────────────────────────────
class _InvestigationBanner extends StatelessWidget {
  final String reason;
  const _InvestigationBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.redAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tutor Under Investigation',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reported for: $reason',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: TColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Skill Chip ────────────────────────────────────────────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: TColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: TColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Review Tile ───────────────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final Review review;
  final bool isDark;
  const _ReviewTile({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final date =
        review.createdAt != null
            ? DateFormat.yMMMd().format(review.createdAt!.getDateTimeInUtc())
            : '';
    final username = review.user?.username ?? 'Anonymous';
    final initial = username[0].toUpperCase();

    final isCreator =
        review.user?.email != null &&
        review.tutor?.email != null &&
        review.user!.email == review.tutor!.email;

    // Creator reviews have rating == 0 — don't show empty stars.
    final hasRating = review.rating > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 19,
            backgroundColor: TColors.primary.withValues(alpha: 0.15),
            backgroundImage:
                review.user?.profilePicture?.isNotEmpty == true
                    ? NetworkImage(review.user!.profilePicture!)
                    : null,
            child:
                review.user?.profilePicture?.isNotEmpty != true
                    ? Text(
                      initial,
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isCreator
                        ? TColors.primary.withValues(alpha: 0.06)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(
                  color:
                      isCreator
                          ? TColors.primary.withValues(alpha: 0.25)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCreator) ...[
                              const SizedBox(width: 6),
                              const _CreatorTag(),
                            ],
                          ],
                        ),
                      ),
                      // Stars only shown when there is an actual rating.
                      if (hasRating) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color:
                                  i < review.rating.round()
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (review.comment?.isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text(
                      review.comment!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Creator Tag ───────────────────────────────────────────────────────────────
class _CreatorTag extends StatelessWidget {
  const _CreatorTag();

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
