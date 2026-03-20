import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/common/widgets/layouts/grid_layout.dart';
import '../../../../sessions/screens/product_cards/t_session_card_vertical.dart';
import '../../../../../models/ModelProvider.dart';
import '../../../../../utils/device/device_utility.dart';

class AllLecturesScreen extends StatefulWidget {
  final String title;
  final List<TutoringSession> sessions;

  const AllLecturesScreen({
    super.key,
    required this.title,
    required this.sessions,
  });

  @override
  State<AllLecturesScreen> createState() => _AllLecturesScreenState();
}

class _AllLecturesScreenState extends State<AllLecturesScreen> {
  String _sortBy = 'Recent';
  bool _showMineOnly = false;

  /// The Tutor.id (DataStore PK) for the signed-in user.
  /// This is what session.tutor?.id is compared against.
  String? _currentTutorId;
  bool _loadingTutorId = false;

  final List<String> _sortOptions = ['Recent', 'Price'];

  @override
  void initState() {
    super.initState();
    _loadCurrentTutorId();
  }

  /// Resolves the signed-in user's Tutor record using the same lookup chain
  /// as TutoringController.currentUserTutorId:
  ///   1. Query Tutor by email (most reliable)
  ///   2. Query Tutor by Cognito userId as fallback
  Future<void> _loadCurrentTutorId() async {
    setState(() => _loadingTutorId = true);
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final attrs = await Amplify.Auth.fetchUserAttributes();

      // 1. Try email lookup first
      final emailAttr = attrs.firstWhere(
        (a) => a.userAttributeKey.key == 'email',
        orElse: () => attrs.first,
      );
      final email = emailAttr.value;

      if (email.isNotEmpty) {
        final byEmail = await Amplify.DataStore.query(
          Tutor.classType,
          where: Tutor.EMAIL.eq(email),
        );
        if (byEmail.isNotEmpty) {
          if (mounted) {
            setState(() {
              _currentTutorId = byEmail.first.id;
              _loadingTutorId = false;
            });
          }
          return;
        }
      }

      // 2. Fallback: query by Cognito userId
      final byId = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(authUser.userId),
      );
      if (byId.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentTutorId = byId.first.id;
            _loadingTutorId = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('AllLecturesScreen: _loadCurrentTutorId error: $e');
    }
    if (mounted) setState(() => _loadingTutorId = false);
  }

  double _avgRating(TutoringSession s) {
    final reviews = s.reviews;
    if (reviews == null || reviews.isEmpty) return 0;
    return reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
  }

  /// A session is "mine" when its tutor.id matches the signed-in user's Tutor record id.
  bool _isOwned(TutoringSession s) {
    if (_currentTutorId == null) return false;
    return s.tutor?.id == _currentTutorId;
  }

  List<TutoringSession> get _filtered {
    if (!_showMineOnly) return widget.sessions;
    return widget.sessions.where(_isOwned).toList();
  }

  List<TutoringSession> get _sorted {
    final list = [..._filtered];
    switch (_sortBy) {
      case 'Price':
        list.sort(
          (a, b) => (a.pricePerSession ?? 0).compareTo(b.pricePerSession ?? 0),
        );
      case 'Rating':
        list.sort((a, b) => _avgRating(b).compareTo(_avgRating(a)));
      default: // 'Recent' — newest first
        list.sort((a, b) {
          final aTime = a.createdAt?.getDateTimeInUtc() ?? DateTime(0);
          final bTime = b.createdAt?.getDateTimeInUtc() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sorted = _sorted;
    final totalVisible = sorted.length;
    final totalAll = widget.sessions.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      // ── App bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: TColors.dashboardAppbarBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ),

      body: Column(
        children: [
          // ── Filter / sort bar ────────────────────────────────────────────
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
              vertical: 10,
            ),
            child: Row(
              children: [
                // Session count pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _showMineOnly
                        ? '$totalVisible / $totalAll sessions'
                        : '$totalAll sessions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TColors.primary,
                    ),
                  ),
                ),

                const Spacer(),

                // ── "Mine" toggle chip ───────────────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _showMineOnly = !_showMineOnly),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _showMineOnly
                              ? TColors.primary.withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _showMineOnly
                                ? TColors.primary
                                : colorScheme.outline.withValues(alpha: 0.15),
                        width: _showMineOnly ? 1.2 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tiny spinner while tutorId is still resolving
                        if (_showMineOnly && _loadingTutorId)
                          SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: TColors.primary,
                            ),
                          )
                        else
                          Icon(
                            _showMineOnly
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            size: 13,
                            color:
                                _showMineOnly
                                    ? TColors.primary
                                    : colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          'Mine',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _showMineOnly
                                    ? TColors.primary
                                    : colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sort chips ───────────────────────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _sortOptions.map((opt) {
                        final isActive = _sortBy == opt;
                        return GestureDetector(
                          onTap: () => setState(() => _sortBy = opt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? TColors.primary
                                      : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isActive
                                        ? TColors.primary
                                        : colorScheme.outline.withValues(
                                          alpha: 0.15,
                                        ),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    isActive
                                        ? Colors.white
                                        : colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),

          // ── Grid / empty state ───────────────────────────────────────────
          Expanded(
            child:
                sorted.isEmpty
                    ? _EmptyState(isMineFilter: _showMineOnly)
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(TSizes.defaultSpace),
                      child: Column(
                        children: [
                          TGridLayout(
                            itemCount: sorted.length,
                            itemBuilder:
                                (_, index) => TSessionCardVertical(
                                  session: sorted[index],
                                ),
                          ),
                          SizedBox(
                            height:
                                TDeviceUtils.getBottomNavigationBarHeight() +
                                TSizes.defaultSpace,
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isMineFilter;
  const _EmptyState({required this.isMineFilter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMineFilter
                  ? Icons.library_add_outlined
                  : Icons.search_off_rounded,
              size: 52,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 14),
            Text(
              isMineFilter
                  ? "You haven't created any sessions yet"
                  : 'No lectures available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (isMineFilter) ...[
              const SizedBox(height: 6),
              Text(
                'Tap "Create Session" on the home screen to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
