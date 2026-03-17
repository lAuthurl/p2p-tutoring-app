// lib/Features/checkout/screens/widgets/t_payment_section.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/paystack_card_controller.dart';
import '../paystack_card_entry_screen.dart';

class TPaymentSection extends StatelessWidget {
  const TPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cardCtrl = Get.put(PaystackCardController());
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Obx(() {
      if (cardCtrl.isLoading.value) {
        return const Center(
          child: SizedBox(
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      final card = cardCtrl.savedCard.value;

      if (card.isEmpty) {
        // ── No card saved ──────────────────────────────────────────
        return GestureDetector(
          onTap: () => Get.to(() => const PaystackCardEntryScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0BA4DB).withValues(alpha: 0.05),
              border: Border.all(
                color: const Color(0xFF0BA4DB).withValues(alpha: 0.45),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0BA4DB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_card_outlined,
                    color: Color(0xFF0BA4DB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add a card',
                        style: TextStyle(
                          color: Color(0xFF0BA4DB),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Pay securely via Paystack',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF0BA4DB),
                ),
              ],
            ),
          ),
        );
      }

      // ── Card saved ─────────────────────────────────────────────
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0BA4DB).withValues(alpha: 0.06),
          border: Border.all(
            color: const Color(0xFF0BA4DB).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Card type icon
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF0BA4DB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        card.cardType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 10,
                              color: Colors.green,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.maskedNumber,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Expires ${card.expiry}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const PaystackCardEntryScreen()),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  color: Color(0xFF0BA4DB),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
