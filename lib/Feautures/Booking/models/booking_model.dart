import 'booking_item_model.dart';

class BookingModel {
  String bookingId;
  String userId;
  DateTime createdAt;
  List<BookingItemModel> bookings;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.createdAt,
    required this.bookings,
  });

  BookingModel copyWith({
    String? bookingId,
    String? userId,
    DateTime? createdAt,
    List<BookingItemModel>? bookings,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      bookings: bookings ?? this.bookings,
    );
  }

  static BookingModel empty() => BookingModel(
    bookingId: '',
    userId: '',
    createdAt: DateTime.now(),
    bookings: [],
  );
}
