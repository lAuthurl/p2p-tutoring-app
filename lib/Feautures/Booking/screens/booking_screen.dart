// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../checkout/screens/checkout.dart';
import '../controllers/booking_controller.dart';
import 'widgets/booking_items.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with RouteAware {
  late final BookingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<BookingController>();
    // ✅ Always refresh from DataStore when the screen opens so newly
    //    created bookings appear immediately even before sync completes.
    _refresh();
  }

  Future<void> _refresh() async {
    await controller.fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Bookings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ Manual refresh button in case auto-refresh misses a sync gap
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          Obx(() {
            final count = controller.bookingItems.length;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count item${count == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TColors.primary,
                ),
              ),
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        // ✅ Pull-to-refresh as a second safety net
        onRefresh: _refresh,
        child: Obx(() {
          if (controller.bookingItems.isEmpty) {
            return _EmptyState(onRefresh: _refresh);
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR SESSIONS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const TBookingItems(),
                const SizedBox(height: 100),
              ],
            ),
          );
        }),
      ),

      // ── Checkout bar ──────────────────────────────────────────
      bottomNavigationBar: Obx(() {
        if (controller.bookingItems.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ElevatedButton(
                onPressed: () => Get.to(() => const CheckoutScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.arrow_right_3, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Proceed to Checkout  ·  ₦${controller.totalBookingPrice.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // ✅ Wrapped in ListView so RefreshIndicator works on empty state too
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
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
                      color: TColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: TColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(Iconsax.shopping_bag, size: 30, color: TColors.primary),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'No bookings yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sessions you book will appear here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 16),
              // ✅ Tap to force-refresh if bookings still not showing
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tap to refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Iconsax.discover_1, size: 16),
                label: const Text('Browse Sessions'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
