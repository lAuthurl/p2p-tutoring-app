import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/checkout_controller.dart';

class TPaymentSection extends StatelessWidget {
  const TPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CheckoutController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Obx(
          () => ListTile(
            leading:
                controller.selectedPaymentMethod.value.image.isNotEmpty
                    ? Image.asset(
                      controller.selectedPaymentMethod.value.image,
                      width: 40,
                    )
                    : null,
            title: Text(
              controller.selectedPaymentMethod.value.name.isNotEmpty
                  ? controller.selectedPaymentMethod.value.name
                  : 'Select Payment Method',
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => controller.selectPaymentMethod(context),
          ),
        ),
      ],
    );
  }
}
