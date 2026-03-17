// lib/Features/checkout/controllers/paystack_card_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/paystack_card_model.dart';

class PaystackCardController extends GetxController {
  static PaystackCardController get instance => Get.find();

  final Rx<PaystackCardModel> savedCard = PaystackCardModel.empty().obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  late TextEditingController cardNumberController;
  late TextEditingController cardholderController;
  late TextEditingController expiryController;
  late TextEditingController cvvController;
  late GlobalKey<FormState> formKey;

  static const String _prefKey = 'paystack_saved_card';

  @override
  void onInit() {
    super.onInit();
    cardNumberController = TextEditingController();
    cardholderController = TextEditingController();
    expiryController = TextEditingController();
    cvvController = TextEditingController();
    formKey = GlobalKey<FormState>();
    _loadSavedCard();
  }

  Future<void> _loadSavedCard() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        savedCard.value = PaystackCardModel.fromJsonString(raw);
      }
    } catch (e) {
      debugPrint('PaystackCardController: failed to load card – $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasCard => savedCard.value.isNotEmpty;

  String _detectCardType(String number) {
    final n = number.replaceAll(' ', '');
    if (n.startsWith('4')) return 'Visa';
    if (n.startsWith('5') || n.startsWith('2')) return 'Mastercard';
    if (n.startsWith('3')) return 'Amex';
    return 'Card';
  }

  String _maskNumber(String number) {
    final n = number.replaceAll(' ', '');
    if (n.length < 4) return number;
    return '•••• •••• •••• ${n.substring(n.length - 4)}';
  }

  Future<bool> saveCard() async {
    if (!formKey.currentState!.validate()) return false;

    try {
      isSaving.value = true;

      // Simulate Paystack tokenisation network call
      await Future.delayed(const Duration(milliseconds: 1400));

      final card = PaystackCardModel(
        cardholderName: cardholderController.text.trim(),
        maskedNumber: _maskNumber(cardNumberController.text),
        expiry: expiryController.text.trim(),
        cardType: _detectCardType(cardNumberController.text),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, card.toJsonString());

      savedCard.value = card;
      return true;
    } catch (e) {
      debugPrint('PaystackCardController: saveCard error – $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removeCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    savedCard.value = PaystackCardModel.empty();
  }

  @override
  void onClose() {
    cardNumberController.dispose();
    cardholderController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.onClose();
  }
}
