// lib/Features/Sessions/screens/session_detail_screen.dart
// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/images/t_user_avatar.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../services/session_access_cache.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../controllers/session_creation_controller.dart';
import '../../controllers/tutoring_controller.dart';

import 'widgets/t_session_attributes.dart';
import 'widgets/t_session_image_slider.dart';
import '../../../../models/ModelProvider.dart';
import '../../../chat/screens/chat.dart';
import 't_session_review.dart';
import '../../../Tutor/screens/tutor_profile.dart';
import 'widgets/session_meta_header.dart';

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

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with RouteAware {
  late final TutoringController _tutoringController;
  late final SessionCreationController _creationController;

  List<Review> _reviews = [];
  bool _loadingReviews = true;
  bool _isOwner = false;
  String? _currentUserId;

  bool _hasPaid = false;
  bool _checkingPayment = true;

  static final RouteObserver<ModalRoute> _routeObserver =
      RouteObserver<ModalRoute>();

  bool get _isFreeSession => (widget.session.pricePerSession ?? 0) <= 0;

  @override
  void initState() {
    super.initState();
    _tutoringController = Get.put(TutoringController(), tag: widget.tag);
    _creationController = Get.put(SessionCreationController(), tag: widget.tag);

    _initializeAttributes(widget.session);

    _fetchReviews();
    _initAccess();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _recheckPayment();
  }

  Future<void> _recheckPayment() async {
    if (_isFreeSession || _currentUserId == null || _isOwner) return;
    setState(() => _checkingPayment = true);
    await _checkPaymentStatus();
  }

  Future<void> _initAccess() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (!mounted) return;
      setState(() => _currentUserId = user.userId);
    } catch (_) {
      if (mounted) setState(() => _checkingPayment = false);
      return;
    }

    final userId = _currentUserId!;

    final isOwner = await SessionAccessCache.instance.getIsTutor(
      userId: userId,
      sessionId: widget.session.id,
      fetcher: () async {
        final tutorId = await _tutoringController.currentUserTutorId;
        return tutorId != null && tutorId == widget.session.tutor?.id;
      },
    );

    if (!mounted) return;

    if (isOwner) {
      setState(() {
        _isOwner = true;
        _checkingPayment = false;
      });
      return;
    }

    setState(() => _isOwner = false);
    await _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    if (_isFreeSession) {
      if (mounted) {
        setState(() {
          _hasPaid = true;
          _checkingPayment = false;
        });
      }
      return;
    }

    if (_isOwner || _currentUserId == null) {
      if (mounted) setState(() => _checkingPayment = false);
      return;
    }

    final paid = await _fetchPaymentFromApi(_currentUserId!, widget.session.id);

    if (mounted) {
      setState(() {
        _hasPaid = paid;
        _checkingPayment = false;
      });
    }
  }

  Future<bool> _fetchPaymentFromApi(String userId, String sessionId) async {
    try {
      const queryDoc = r"""
        query ListPaymentsByUser($userId: ID!, $limit: Int) {
          listUserSessionPaymentsByUser(userId: $userId, limit: $limit) {
            items { id userId sessionId hasPaid _deleted }
          }
        }
      """;

      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: queryDoc,
                  variables: {'userId': userId, 'limit': 200},
                ),
              )
              .response;

      if (response.errors.isEmpty && response.data != null) {
        final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final items =
            (root['listUserSessionPaymentsByUser']
                    as Map<String, dynamic>?)?['items']
                as List<dynamic>? ??
            [];

        return items.any((raw) {
          final item = raw as Map<String, dynamic>;
          return item['sessionId'] == sessionId &&
              item['hasPaid'] == true &&
              item['_deleted'] != true;
        });
      }
    } catch (e) {
      safePrint('_fetchPaymentFromApi error: $e');
    }
    return false;
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
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
    };
    _creationController.initializeAttributesForSession({
      ...defaultAttrs,
      ...sessionAttrs,
    });
  }

  Future<void> _fetchReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await SessionAccessCache.instance.getReviews<Review>(
        sessionId: widget.session.id,
        fetcher: () => _tutoringController.fetchReviews(widget.session.id),
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
      Get.snackbar(
        'Error',
        'Failed to fetch reviews',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      if (mounted) setState(() => _loadingReviews = false);
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
        'Error',
        'Tutor information not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    } catch (e, st) {
      safePrint('❌ Failed to fetch tutor for session ${session.id}: $e\n$st');
      return null;
    }
  }

  Future<void> _bookSession(TutoringSession session) async {
    try {
      final tutoringController = Get.find<TutoringController>(tag: widget.tag);
      final attrs = Map<String, String>.from(
        _creationController.selectedAttributes,
      );
      await tutoringController.addSessionToBooking(
        session,
        selectedAttributes: attrs.isEmpty ? null : attrs,
        quantity: 1,
        controllerTag: widget.tag,
      );
    } catch (e) {
      safePrint('❌ _bookSession error: $e');
    }
  }

  Future<void> _openReviewScreen() async {
    if (_isOwner) {
      await Get.to(() => SessionReviewScreen(session: widget.session));
      SessionAccessCache.instance.invalidateReviews(widget.session.id);
      _fetchReviews();
      return;
    }

    if (_checkingPayment) {
      Get.snackbar(
        'Please wait',
        'Verifying your access…',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (!_isFreeSession && !_hasPaid) {
      Get.snackbar(
        'Payment Required',
        'Book and complete payment to write a review.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Iconsax.lock_1, color: Colors.white, size: 18),
      );
      return;
    }

    await Get.to(() => SessionReviewScreen(session: widget.session));
    SessionAccessCache.instance.invalidateReviews(widget.session.id);
    _fetchReviews();
  }

  // ── Whether to show the book button ────────────────────────────────────────
  bool get _showBookButton {
    if (_isOwner) return false;
    if (_isFreeSession) return false;
    if (_hasPaid) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    TDeviceUtils.getScreenWidth(context);

    final canReview = _isOwner || _isFreeSession || _hasPaid;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            // Only add bottom padding when book button is visible
            padding: EdgeInsets.only(bottom: _showBookButton ? 96 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TSessionImageSlider(session: session),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.defaultSpace,
                    vertical: TSizes.spaceBtwItems,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TSessionMetaHeader(
                        session: session,
                        reviews: _reviews,
                        tag: widget.tag,
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      TSessionAttributes(session: session),
                      const SizedBox(height: TSizes.spaceBtwSections / 2),

                      _ActionRow(
                        isOwner: _isOwner,
                        isFreeSession: _isFreeSession,
                        currentUserId: _currentUserId,
                        session: session,
                        hasPaid: _hasPaid,
                        checking: _checkingPayment,
                        onTutorTap: () async {
                          final tutor = await _getTutorOrFetch(session);
                          if (tutor != null) {
                            Get.to(() => TutorProfileScreen(tutor: tutor));
                          }
                        },
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),

                      const _SectionLabel(title: "Description"),
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
                          session.description ?? 'No description provided.',
                          trimLines: 4,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: '  Show more',
                          trimExpandedText: '  Show less',
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _SectionLabel(title: 'Reviews'),
                          Tooltip(
                            message:
                                (!canReview && !_checkingPayment)
                                    ? 'Pay to unlock reviews'
                                    : '',
                            child: TextButton.icon(
                              onPressed: _openReviewScreen,
                              icon: Icon(
                                canReview ? Iconsax.star : Iconsax.lock_1,
                                size: 14,
                                color:
                                    canReview
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withValues(
                                          alpha: 0.35,
                                        ),
                              ),
                              label: Text(
                                canReview
                                    ? 'Write a review'
                                    : _checkingPayment
                                    ? 'Checking…'
                                    : 'Write a review 🔒',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      canReview
                                          ? colorScheme.primary
                                          : colorScheme.onSurface.withValues(
                                            alpha: 0.35,
                                          ),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      if (!_isOwner &&
                          !_isFreeSession &&
                          !_checkingPayment &&
                          !_hasPaid) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outline.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.lock_1,
                                size: 15,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Complete payment to write a review for this session.',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.55,
                                    ),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),
                      ],

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
                              onPressed: _openReviewScreen,
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
                              child: Text('See all ${_reviews.length} reviews'),
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

          // ── Bottom CTA — hidden if owner, free, or already paid ────────────
          if (_showBookButton)
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
                            'Book Session',
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

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      TSectionHeading(title: title, showActionButton: false);
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isOwner,
    required this.isFreeSession,
    required this.currentUserId,
    required this.session,
    required this.hasPaid,
    required this.checking,
    required this.onTutorTap,
  });

  final bool isOwner;
  final bool isFreeSession;
  final String? currentUserId;
  final TutoringSession session;
  final bool hasPaid;
  final bool checking;
  final VoidCallback onTutorTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatEnabled = isOwner || isFreeSession || hasPaid;

    final activeButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 13),
      foregroundColor: colorScheme.primary,
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.38)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final disabledButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 13),
      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.35),
      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTutorTap,
                icon: const Icon(Iconsax.profile_circle, size: 17),
                label: const Text('Tutor Profile'),
                style: activeButtonStyle,
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Tooltip(
                message:
                    (!isOwner && !chatEnabled && !checking)
                        ? 'Book & pay to unlock chat'
                        : '',
                preferBelow: false,
                child: OutlinedButton.icon(
                  onPressed:
                      (isOwner || chatEnabled)
                          ? () {
                            if (isOwner) {
                              Get.to(() => const InboxScreen());
                            } else {
                              if (currentUserId == null) return;
                              Get.to(
                                () => ChatScreen(
                                  sessionId: '${session.id}_$currentUserId',
                                  sessionTitle: session.title,
                                  otherUserName: session.tutor?.name ?? 'Tutor',
                                  otherUserId: session.tutor?.id ?? '',
                                ),
                              );
                            }
                          }
                          : null,
                  icon:
                      isOwner
                          ? const Icon(Iconsax.message_text, size: 17)
                          : checking
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                          : Icon(
                            chatEnabled ? Iconsax.message : Iconsax.lock_1,
                            size: 17,
                          ),
                  label: Text(
                    isOwner
                        ? 'Inbox'
                        : checking
                        ? 'Checking…'
                        : chatEnabled
                        ? 'Chat'
                        : 'Chat 🔒',
                  ),
                  style:
                      (isOwner || chatEnabled)
                          ? activeButtonStyle
                          : disabledButtonStyle,
                ),
              ),
            ),
          ],
        ),
        if (!isOwner && !isFreeSession && !checking && !hasPaid) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.lock_1,
                  size: 15,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Book and complete payment to unlock chat and reviews.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

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
            'No reviews yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Be the first to share your experience',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final username = r.user?.username ?? 'Anonymous';
    final dateStr =
        r.createdAt != null
            ? r.createdAt!.getDateTimeInUtc().toLocal().toString().split(' ')[0]
            : '';
    final isCreator =
        r.user?.email != null &&
        r.tutor?.email != null &&
        r.user!.email == r.tutor!.email;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isCreator
                  ? TColors.primary.withValues(alpha: 0.05)
                  : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isCreator
                    ? TColors.primary.withValues(alpha: 0.25)
                    : colorScheme.outline.withValues(alpha: 0.12),
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
                TUserAvatar(
                  imageKeyOrUrl: r.user?.profilePicture,
                  radius: 18,
                  fallbackInitial: r.user?.username ?? '?',
                  backgroundColor: TColors.primary.withValues(alpha: 0.12),
                  foregroundColor: TColors.primary,
                ),
                const SizedBox(width: 10),
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
                            const _CreatorTag(),
                          ],
                        ],
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
