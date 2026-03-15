import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../common/widgets/layouts/grid_layout.dart';
import '../Courses/screens/product_cards/t_session_card_vertical.dart';
import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/home_controller.dart';

import '../dashboard/Home/controllers/favorites_controller.dart';

class FavouriteScreen extends StatefulWidget {
  final HomeController homeController;

  const FavouriteScreen({super.key, required this.homeController});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen>
    with WidgetsBindingObserver {
  final _favCtrl = FavoritesController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reload every time the screen is pushed — covers the login-then-open case.
    _favCtrl.reloadForUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when the app comes back to the foreground.
  /// Also fires when the user returns to this screen from another route
  /// because WidgetsBindingObserver catches resumed lifecycle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _favCtrl.reloadForUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Obx(() {
        final isLoading = _favCtrl.isLoading.value;
        final favoriteSessions = _favCtrl.favoritedSessions;

        return CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => Get.back(),
              ),
              title: Text(
                'Favourites',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),

            // ── Loading indicator ─────────────────────────────────
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else ...[
              // ── Stats banner ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TSizes.defaultSpace,
                    4,
                    TSizes.defaultSpace,
                    20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _StatCard(
                            icon: Iconsax.heart5,
                            iconColor: Colors.pink,
                            label: 'Saved',
                            value: '${favoriteSessions.length}',
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Iconsax.teacher,
                            iconColor: Colors.teal,
                            label: 'Tutors',
                            value:
                                '${favoriteSessions.map((e) => e.tutor?.id).toSet().length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        icon: Iconsax.money,
                        iconColor: TColors.primary,
                        label: 'Total value of saved sessions',
                        value:
                            favoriteSessions.isEmpty
                                ? '₦0'
                                : '₦${favoriteSessions.fold<double>(0, (s, e) => s + (e.pricePerSession ?? 0)).toStringAsFixed(0)}',
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Empty state ────────────────────────────────────────
              if (favoriteSessions.isEmpty)
                const SliverFillRemaining(child: _EmptyState()),

              // ── Grid ──────────────────────────────────────────────
              if (favoriteSessions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.defaultSpace,
                    ),
                    child: TGridLayout(
                      itemCount: favoriteSessions.length,
                      itemBuilder:
                          (_, index) => TSessionCardVertical(
                            session: favoriteSessions[index],
                          ),
                    ),
                  ),
                ),
            ],

            // ── Bottom padding ─────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    TDeviceUtils.getBottomNavigationBarHeight() +
                    TSizes.defaultSpace,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool fullWidth;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child:
          fullWidth
              ? Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
    );

    return fullWidth ? content : Expanded(child: content);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Iconsax.heart, size: 32, color: Colors.pink),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing saved yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on any session\nto save it here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Iconsax.discover_1, size: 16),
            label: const Text('Explore Sessions'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
