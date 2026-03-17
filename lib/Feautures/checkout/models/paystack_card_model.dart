// lib/Features/checkout/models/paystack_card_model.dart

import 'dart:convert';

class PaystackCardModel {
  final String cardholderName;
  final String maskedNumber;
  final String expiry;
  final String cardType;

  const PaystackCardModel({
    required this.cardholderName,
    required this.maskedNumber,
    required this.expiry,
    required this.cardType,
  });

  static PaystackCardModel empty() => const PaystackCardModel(
    cardholderName: '',
    maskedNumber: '',
    expiry: '',
    cardType: '',
  );

  bool get isEmpty => cardholderName.isEmpty;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() => {
    'cardholderName': cardholderName,
    'maskedNumber': maskedNumber,
    'expiry': expiry,
    'cardType': cardType,
  };

  factory PaystackCardModel.fromJson(Map<String, dynamic> json) =>
      PaystackCardModel(
        cardholderName: json['cardholderName'] ?? '',
        maskedNumber: json['maskedNumber'] ?? '',
        expiry: json['expiry'] ?? '',
        cardType: json['cardType'] ?? '',
      );

  factory PaystackCardModel.fromJsonString(String raw) =>
      PaystackCardModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() =>
      'PaystackCardModel(type: $cardType, masked: $maskedNumber, expiry: $expiry)';
}
