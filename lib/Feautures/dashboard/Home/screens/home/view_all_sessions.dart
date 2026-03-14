import 'package:flutter/material.dart';
import 'package:p2p_tutoring_app/utils/constants/colors.dart';
import 'package:p2p_tutoring_app/utils/constants/sizes.dart';
import 'package:p2p_tutoring_app/common/widgets/layouts/grid_layout.dart';
import '../../../../Courses/screens/product_cards/t_session_card_vertical.dart';
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
  final List<String> _sortOptions = ['Recent', 'Price'];

  double _avgRating(TutoringSession s) {
    final reviews = s.reviews;
    if (reviews == null || reviews.isEmpty) return 0;
    return reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
  }

  List<TutoringSession> get _sorted {
    final list = [...widget.sessions];
    switch (_sortBy) {
      case 'Price':
        list.sort(
          (a, b) => (a.pricePerSession ?? 0).compareTo(b.pricePerSession ?? 0),
        );
      case 'Rating':
        list.sort((a, b) => _avgRating(b).compareTo(_avgRating(a)));
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sorted = _sorted;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      // ── App bar ───────────────────────────────────────────────
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
          // ── Sort bar ────────────────────────────────────────────
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
                    '${widget.sessions.length} sessions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TColors.primary,
                    ),
                  ),
                ),

                const Spacer(),

                // Sort chips
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

          // ── Scrollable grid ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  TGridLayout(
                    itemCount: sorted.length,
                    itemBuilder:
                        (_, index) =>
                            TSessionCardVertical(session: sorted[index]),
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
