/// Model representing a booked tutoring session/item
class BookingItemModel {
  // --- Core booking identifiers
  String serviceId;
  String providerId;

  // --- Human-readable details for display
  String serviceTitle;
  String serviceImage; // path or url
  String providerName;
  String providerImage;

  // --- Booking details
  DateTime bookingDate;
  String timeSlot;
  int quantity;

  // --- Pricing
  double price; // base price
  bool isPhysical; // true if in-person session
  bool applyDiscount; // true if discount applies
  double? negotiatedPrice; // optional negotiated price for physical sessions

  BookingItemModel({
    required this.serviceId,
    required this.providerId,
    required this.serviceTitle,
    required this.serviceImage,
    required this.providerName,
    required this.providerImage,
    required this.bookingDate,
    required this.timeSlot,
    required this.price,
    this.quantity = 1,
    this.isPhysical = false,
    this.applyDiscount = false,
    this.negotiatedPrice,
  });

  /// Returns an empty booking item
  static BookingItemModel empty() => BookingItemModel(
    serviceId: '',
    providerId: '',
    serviceTitle: '',
    serviceImage: '',
    providerName: '',
    providerImage: '',
    bookingDate: DateTime.now(),
    timeSlot: '',
    price: 0.0,
    quantity: 0,
  );

  /// Creates a copy with overridden fields
  BookingItemModel copyWith({
    String? serviceId,
    String? providerId,
    String? serviceTitle,
    String? serviceImage,
    String? providerName,
    String? providerImage,
    DateTime? bookingDate,
    String? timeSlot,
    int? quantity,
    double? price,
    bool? isPhysical,
    bool? applyDiscount,
    double? negotiatedPrice,
  }) {
    return BookingItemModel(
      serviceId: serviceId ?? this.serviceId,
      providerId: providerId ?? this.providerId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceImage: serviceImage ?? this.serviceImage,
      providerName: providerName ?? this.providerName,
      providerImage: providerImage ?? this.providerImage,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isPhysical: isPhysical ?? this.isPhysical,
      applyDiscount: applyDiscount ?? this.applyDiscount,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
    );
  }
}
