import 'package:get/get.dart';
import '../models/booking_item_model.dart';
import '../models/booking_model.dart';

class BookingController extends GetxController {
  static BookingController get instance => Get.find();

  /// Aggregate booking model (used for backend submission)
  Rx<BookingModel> currentBooking = BookingModel.empty().obs;

  /// List of booked items (UI-friendly)
  RxList<BookingItemModel> bookingItems = <BookingItemModel>[].obs;

  /// Total booking cost
  RxDouble totalBookingPrice = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _syncBookingModel();
    _recalculateTotal();
  }

  /// Create or update a booking item
  void addBooking({
    required String serviceId,
    required String providerId,
    required DateTime bookingDate,
    required String timeSlot,
    required double price,
    int quantity = 1,

    // Optional display details
    String? serviceTitle,
    String? serviceImage,
    String? providerName,
    String? providerImage,
    bool isPhysical = false,
    bool applyDiscount = false,
    double? negotiatedPrice,
  }) {
    final bookingItem = bookingItems.firstWhere(
      (item) =>
          item.serviceId == serviceId &&
          item.bookingDate == bookingDate &&
          item.timeSlot == timeSlot,
      orElse:
          () => BookingItemModel(
            serviceId: serviceId,
            providerId: providerId,
            serviceTitle: serviceTitle ?? '',
            serviceImage: serviceImage ?? '',
            providerName: providerName ?? '',
            providerImage: providerImage ?? '',
            bookingDate: bookingDate,
            timeSlot: timeSlot,
            price: price,
            quantity: 0,
            isPhysical: isPhysical,
            applyDiscount: applyDiscount,
            negotiatedPrice: negotiatedPrice,
          ),
    );

    if (bookingItem.quantity == 0) {
      // Ensure display fields are populated for newly added items
      bookingItem.serviceTitle = serviceTitle ?? bookingItem.serviceTitle;
      bookingItem.serviceImage = serviceImage ?? bookingItem.serviceImage;
      bookingItem.providerName = providerName ?? bookingItem.providerName;
      bookingItem.providerImage = providerImage ?? bookingItem.providerImage;

      bookingItems.add(bookingItem);
    }

    bookingItem.quantity += quantity;
    totalBookingPrice.value += price * quantity;

    _syncBookingModel();
    bookingItems.refresh();
  }

  /// Update number of booked sessions
  void updateBookingQuantity(BookingItemModel bookingItem, int newQuantity) {
    if (newQuantity <= 0) {
      removeBooking(bookingItem);
      return;
    }

    final difference = newQuantity - bookingItem.quantity;
    totalBookingPrice.value += bookingItem.price * difference;

    bookingItem.quantity = newQuantity;

    _syncBookingModel();
    bookingItems.refresh();
  }

  /// Remove a booking item
  void removeBooking(BookingItemModel bookingItem) {
    bookingItems.remove(bookingItem);
    totalBookingPrice.value -= bookingItem.price * bookingItem.quantity;

    _syncBookingModel();
    bookingItems.refresh();
  }

  /// Clear all bookings
  void clearBookings() {
    bookingItems.clear();
    totalBookingPrice.value = 0.0;

    currentBooking.value = BookingModel.empty();
  }

  /// Total booked sessions count
  int totalBookedSessions() {
    return bookingItems
        .map((e) => e.quantity)
        .fold(0, (prev, next) => prev + next);
  }

  /// Sync UI list with aggregate booking model
  void _syncBookingModel() {
    currentBooking.value = currentBooking.value.copyWith(
      bookings: List.from(bookingItems),
      createdAt: DateTime.now(),
    );
  }

  void _recalculateTotal() {
    totalBookingPrice.value = bookingItems
        .map((e) => e.price * e.quantity)
        .fold(0.0, (prev, next) => prev + next);
  }
}
