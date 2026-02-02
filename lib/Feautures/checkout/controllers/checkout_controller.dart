import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/image_strings.dart';
import '../models/payment_method_model.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  final Rx<PaymentMethodModel> selectedPaymentMethod =
      PaymentMethodModel.empty().obs;

  @override
  void onInit() {
    // Default payment method
    selectedPaymentMethod.value = PaymentMethodModel(
      name: 'Paypal',
      image: TImages.paypal,
    );
    super.onInit();
  }

  /// Show payment method selection modal
  Future<void> selectPaymentMethod(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      builder:
          (_) => SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Paypal'),
                  leading: Image.asset(TImages.paypal, width: 40),
                  onTap: () {
                    selectedPaymentMethod.value = PaymentMethodModel(
                      name: 'Paypal',
                      image: TImages.paypal,
                    );
                    Get.back();
                  },
                ),
                ListTile(
                  title: const Text('Credit Card'),
                  leading: Image.asset(TImages.creditCard, width: 40),
                  onTap: () {
                    selectedPaymentMethod.value = PaymentMethodModel(
                      name: 'Credit Card',
                      image: TImages.creditCard,
                    );
                    Get.back();
                  },
                ),
              ],
            ),
          ),
    );
  }
}
