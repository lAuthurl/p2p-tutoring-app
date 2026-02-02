class TPricingCalculator {
  /// Base price constants
  static const double onlineSessionPrice = 20.0;
  static const double physicalSessionPrice = 35.0;

  /// Calculates total price for multiple sessions
  static double calculateTotalPrice({
    required int numberOfSessions,
    required List<bool> sessionTypes, // true = physical, false = online
    required List<double?> negotiatedPrices,
  }) {
    double total = 0.0;

    for (int i = 0; i < numberOfSessions; i++) {
      final isPhysical = sessionTypes[i];
      final negotiated = negotiatedPrices[i];

      double sessionPrice =
          isPhysical
              ? (negotiated ?? physicalSessionPrice)
              : onlineSessionPrice;

      total += sessionPrice;
    }

    return double.tryParse(total.toStringAsFixed(2)) ?? 0.0;
  }

  /// Calculates the price for a single session (used in billing section)
  static double calculateSessionPrice({
    required bool isPhysical,
    bool applyDiscount = false,
    double? negotiatedPrice,
  }) {
    double price =
        isPhysical
            ? (negotiatedPrice ?? physicalSessionPrice)
            : onlineSessionPrice;

    if (applyDiscount) {
      price *= 0.9; // Example: 10% discount
    }

    return double.tryParse(price.toStringAsFixed(2)) ?? 0.0;
  }
}
