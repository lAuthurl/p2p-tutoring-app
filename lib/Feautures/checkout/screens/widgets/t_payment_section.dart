import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/checkout_controller.dart';
import '../../../../../utils/constants/colors.dart';

class TPaymentSection extends StatelessWidget {
  const TPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CheckoutController.instance;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final method = controller.selectedPaymentMethod.value;
      final hasMethod = method.name.isNotEmpty;

      return InkWell(
        onTap: () => controller.selectPaymentMethod(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Payment icon/image
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    method.image.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              method.image,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                        : Icon(Iconsax.card, color: TColors.primary, size: 22),
              ),
              const SizedBox(width: 14),

              // Method name
              Expanded(
                child: Text(
                  hasMethod ? method.name : 'Select payment method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        hasMethod
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      );
    });
  }
}
