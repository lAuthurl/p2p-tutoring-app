// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../controllers/session_creation_controller.dart';
import '../../../../../models/ModelProvider.dart';

/// Combined session header — rating row + title + live price in one cohesive unit.
class TSessionMetaHeader extends StatelessWidget {
  final TutoringSession session;
  final List<Review>? reviews;
  final String? tag;

  const TSessionMetaHeader({
    super.key,
    required this.session,
    this.reviews,
    this.tag,
  });

  double get _averageRating {
    if (reviews == null || reviews!.isEmpty) return 0;
    return reviews!.fold<double>(0, (s, r) => s + r.rating) / reviews!.length;
  }

  @override
  Widget build(BuildContext context) {
    final controllerTag = tag ?? session.id;
    final controller = Get.find<SessionCreationController>(tag: controllerTag);
    final basePrice = session.pricePerSession ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    final avg = _averageRating;
    final reviewCount = reviews?.length ?? 0;

    return Obx(() {
      final _ = controller.selectedAttributes.length;
      final adjustedPrice = controller.calculateDynamicPrice(session);
      final hasDiscount = adjustedPrice < basePrice && basePrice > 0;
      final salePercent =
          hasDiscount
              ? ((basePrice - adjustedPrice) / basePrice * 100).round()
              : 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: rating + share ─────────────────────────────────
          Row(
            children: [
              _StarRow(avg: avg),
              const SizedBox(width: 6),

              // Rating pill
              if (avg > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade800,
                    ),
                  ),
                )
              else
                Text(
                  'New',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),

              if (reviewCount > 0) ...[
                const SizedBox(width: 5),
                Text(
                  '($reviewCount reviews)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],

              const Spacer(),
              _ShareButton(session: session),
            ],
          ),

          const SizedBox(height: 14),

          // ── Rows 2+3: title + price unified with accent bar ───────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar — visually binds title and price
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        session.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Price block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₦${adjustedPrice % 1 == 0 ? adjustedPrice.toStringAsFixed(0) : adjustedPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: TColors.primary,
                              letterSpacing: -0.5,
                              height: 1,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '₦${basePrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _SaleBadge(percent: salePercent),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ── Star Row ──────────────────────────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final double avg;
  const _StarRow({required this.avg});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < avg.floor();
        // Fixed: threshold lowered to 0.25 so x.5 ratings always show half-star
        final half = !full && (avg - i) >= 0.25 && (avg - i) < 1.0;
        return Icon(
          full
              ? Iconsax.star5
              : half
              ? Iconsax.star_15
              : Iconsax.star,
          color: (full || half) ? Colors.amber.shade600 : Colors.grey.shade300,
          size: 15,
        );
      }),
    );
  }
}

// ── Share Button ──────────────────────────────────────────────────────────────
class _ShareButton extends StatelessWidget {
  final TutoringSession session;
  const _ShareButton({required this.session});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.lightImpact();
          // Implement share logic
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            Icons.share_outlined,
            size: 17,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Sale Badge ────────────────────────────────────────────────────────────────
class _SaleBadge extends StatelessWidget {
  final int percent;
  const _SaleBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
