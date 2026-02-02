import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../Booking/controllers/booking_controller.dart';
import '../../dashboard/Home/controllers/dummy_tutoring_data.dart';
import '../models/tutoring_session_model.dart';
import '../models/session_variation_model.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';

class TutoringController extends GetxController {
  static TutoringController get instance {
    if (Get.isRegistered<TutoringController>()) return Get.find();
    return Get.put(TutoringController());
  }

  /// Sessions list
  final sessions = <TutoringSessionModel>[].obs;

  /// Selected state
  RxInt selectedQuantity = 0.obs;
  RxMap<String, String> selectedAttributes = <String, String>{}.obs;
  Rx<SessionVariationModel> selectedVariation =
      SessionVariationModel.empty().obs;
  RxString variationStockStatus = ''.obs;
  RxString selectedSessionImage = ''.obs;

  /// Favorites: SessionID -> true/false
  final favorites = <String, RxBool>{}.obs;

  @override
  void onInit() {
    sessions.value = DummyTutoringData.tutoringSessions;
    super.onInit();
  }

  /// Calculate sale percentage (if needed)
  int? calculateSalePercentage(double price, double? salePrice) {
    if (salePrice == null || salePrice <= 0) {
      return null;
    }
    return ((1 - (salePrice / price)) * 100).round();
  }

  /// Get session display price
  /// Compute adjusted numeric price taking selected attributes into account.
  double _computeAdjustedPrice(TutoringSessionModel session) {
    double price = session.pricePerSession;
    // Only apply the global selected variation price if that variation belongs to this session
    if (session.sessionVariations != null &&
        session.sessionVariations!.isNotEmpty &&
        selectedVariation.value.id.isNotEmpty &&
        (session.sessionVariations ?? []).any(
          (v) => v.id == selectedVariation.value.id,
        )) {
      price = selectedVariation.value.pricePerSession;
    }

    // Duration: if '2hr' selected, double the price
    final duration =
        (selectedAttributes['Duration'] ?? '').toString().toLowerCase();
    if (duration.contains('2hr') ||
        duration.contains('2 hr') ||
        duration.contains('2h')) {
      price *= 2;
    }

    // Mode: if a physical mode is selected (in-person/offline/physical), increase by 20%
    final mode =
        (selectedAttributes['Mode'] ?? selectedAttributes['mode'] ?? '')
            .toString()
            .toLowerCase();
    if (mode.contains('in-person') ||
        mode.contains('in person') ||
        mode.contains('physical') ||
        mode.contains('offline')) {
      price *= 1.2;
    }

    return price;
  }

  String getSessionPrice(TutoringSessionModel session) {
    final price = _computeAdjustedPrice(session);

    // Format to match homepage: no decimal when whole number, otherwise two decimals
    if (price % 1 == 0) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }

  /// Initialize selected quantity for a session
  void initializeAlreadySelectedQuantity(TutoringSessionModel session) {
    // Reset per-session selections to avoid leaking previous session choices
    selectedAttributes.clear();
    // Reset selectedVariation if it does not belong to this session
    if (selectedVariation.value.id.isNotEmpty &&
        !(session.sessionVariations ?? []).any(
          (v) => v.id == selectedVariation.value.id,
        )) {
      selectedVariation.value = SessionVariationModel.empty();
    }
    // Default session image
    selectedSessionImage.value =
        (session.images != null && session.images!.isNotEmpty)
            ? session.images!.first
            : session.thumbnail;

    if (session.sessionVariations == null ||
        session.sessionVariations!.isEmpty) {
      selectedQuantity.value = BookingController.instance.bookingItems.fold(
        0,
        (prev, item) => prev + item.quantity,
      );
    } else {
      final variationId = selectedVariation.value.id;
      if (variationId.isNotEmpty) {
        selectedQuantity.value = BookingController.instance.bookingItems
            .where((item) => item.timeSlot == variationId)
            .fold<int>(0, (prev, item) => prev + item.quantity);
      } else {
        selectedQuantity.value = 0;
      }

      // Auto-select the only variation when there's exactly one variation
      if (session.sessionVariations!.length == 1 &&
          selectedVariation.value.id.isEmpty) {
        final single = session.sessionVariations!.first;
        selectedVariation.value = single;

        // Populate selected attributes from the selected variation
        selectedAttributes.clear();
        for (final entry in single.sessionAttributes.entries) {
          selectedAttributes[entry.key] = entry.value;
        }

        // If Duration isn't present on the variation, infer a default to keep UI consistent
        if (!selectedAttributes.containsKey('Duration')) {
          final dv =
              single.sessionAttributes['Duration'] ??
              single.sessionAttributes['duration'] ??
              '';
          selectedAttributes['Duration'] = dv.isNotEmpty ? dv : '1hr';
        }

        // Ensure selected image reflects the variation
        if ((single.image ?? '').isNotEmpty) {
          selectedSessionImage.value = single.image!;
        }

        // Recompute selected quantity for that variation
        selectedQuantity.value = BookingController.instance.bookingItems
            .where((i) => i.timeSlot == single.id)
            .fold<int>(0, (prev, item) => prev + item.quantity);
      }
    }
  }

  /// Get all images for a session
  List<String> getAllSessionImages(TutoringSessionModel session) {
    final images = <String>[];
    if (session.images != null && session.images!.isNotEmpty) {
      images.addAll(session.images!);
    }
    if (session.thumbnail.isNotEmpty) {
      images.add(session.thumbnail);
    }
    if (session.sessionVariations != null) {
      for (var v in session.sessionVariations!) {
        if (v.image != null && v.image!.isNotEmpty) {
          images.add(v.image!);
        }
      }
    }
    final filtered = images.where((s) => s.isNotEmpty).toList();
    final unique = filtered.toSet().toList();
    if (unique.isEmpty) return [TImages.courseOthers];
    return unique;
  }

  /// Attribute selection
  void onAttributeSelected(String name, String value) {
    // Normalize mode values to match variations if needed
    if (name.toLowerCase() == 'mode' &&
        sessions.isNotEmpty &&
        sessions.first.sessionVariations != null) {
      final modeValues =
          sessions.first.sessionVariations!
              .map(
                (v) =>
                    v.sessionAttributes['Mode'] ??
                    v.sessionAttributes['mode'] ??
                    '',
              )
              .where((v) => v.isNotEmpty)
              .toSet();

      if (!modeValues.contains(value)) {
        // if user picked 'Offline' but variations use 'In-Person', map it
        if (value.toLowerCase() == 'offline' &&
            modeValues.contains('In-Person')) {
          value = 'In-Person';
        } else if (value.toLowerCase() == 'offline' &&
            modeValues.contains('Offline')) {
          value = 'Offline';
        }
      }
    }

    // Set the selected attribute value
    selectedAttributes[name] = value;

    // Find the matching variation
    final variation = sessions.first.sessionVariations!.firstWhere(
      (v) => _isSameAttributeValues(
        Map<String, String>.from(selectedAttributes),
        v.sessionAttributes,
      ),
      orElse: () => SessionVariationModel.empty(),
    );

    // Update selected image if variation provides one
    if ((variation.image ?? '').isNotEmpty) {
      selectedSessionImage.value = variation.image!;
    }

    // Update selected quantity for this variation
    if (variation.id.isNotEmpty) {
      selectedQuantity.value = BookingController.instance.bookingItems
          .where((i) => i.timeSlot == variation.id)
          .fold<int>(0, (prev, item) => prev + item.quantity);
    }

    selectedVariation.value = variation;
  }

  bool _isSameAttributeValues(
    Map<String, String> selectedAttrs,
    Map<String, String> sessionAttributes,
  ) {
    // Consider a variation a match if all selected attributes match the variation's attributes (subset match).
    for (final key in selectedAttrs.keys) {
      final vVal = sessionAttributes[key];
      final sVal = selectedAttrs[key];
      if (vVal == null || vVal != sVal) {
        return false;
      }
    }
    return true;
  }

  /// Add to booking
  void addSessionToBooking(TutoringSessionModel session) {
    final variation = selectedVariation.value;

    if (session.sessionVariations != null &&
        session.sessionVariations!.isNotEmpty &&
        variation.id.isEmpty) {
      Get.snackbar(
        'Selection required',
        'Please select a variation before booking.',
      );
      return;
    }

    // Resolve a representative image for display (session images > thumbnail > variation image)
    String serviceImage = '';
    if (session.images != null && session.images!.isNotEmpty) {
      serviceImage = session.images!.first;
    } else if (session.thumbnail.isNotEmpty) {
      serviceImage = session.thumbnail;
    } else if (variation.image != null && variation.image!.isNotEmpty) {
      serviceImage = variation.image!;
    }

    final adjustedPrice = _computeAdjustedPrice(session);

    BookingController.instance.addBooking(
      serviceId: session.id,
      providerId: session.tutor?.id ?? '',
      bookingDate: variation.lectureTime ?? DateTime.now(),
      timeSlot: variation.id,
      price: adjustedPrice,

      // Display details
      serviceTitle: session.title,
      serviceImage: serviceImage,
      providerName: session.tutor?.name ?? '',
      providerImage: session.tutor?.image ?? '',
    );

    Get.back();
  }

  /// Favorites
  bool isFavourite(String sessionId) => favorites[sessionId]?.value ?? false;

  void toggleFavoriteSession(String sessionId) {
    if (!favorites.containsKey(sessionId)) {
      favorites[sessionId] = true.obs;
    } else {
      favorites[sessionId]!.value = !favorites[sessionId]!.value;
    }
  }

  List<TutoringSessionModel> favoriteSessions() =>
      sessions.where((s) => isFavourite(s.id)).toList();

  /// Get attribute values available in variations
  List<String> getAttributesAvailabilityInVariation(
    List<SessionVariationModel> variations,
    String attributeName,
  ) {
    final values = <String>{};
    for (final v in variations) {
      final val = v.sessionAttributes[attributeName];
      if (val != null && val.isNotEmpty && v.availableSeats > 0) {
        values.add(val);
      }
    }
    return values.toList();
  }

  void showEnlargedImage(String imageUrl) {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Container(
            color: Colors.black,
            child: Center(
              child: Builder(
                builder: (_) {
                  final cleaned = THelperFunctions.normalizeImagePath(imageUrl);
                  if (cleaned.isEmpty) {
                    return Image.asset(
                      TImages.tutorPromo1,
                      fit: BoxFit.contain,
                    );
                  }
                  if (THelperFunctions.isNetworkImagePath(imageUrl)) {
                    return Image.network(cleaned, fit: BoxFit.contain);
                  }
                  return Image.asset(cleaned, fit: BoxFit.contain);
                },
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
