/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;

/** This is an auto generated class representing the BookingItem type in your schema. */
class BookingItem extends amplify_core.Model {
  static const classType = const _BookingItemModelType();
  final String id;
  final User? _user;
  final Booking? _booking;
  final String? _sessionId;
  final String? _tutorId;
  final amplify_core.TemporalDateTime? _bookingDate;
  final String? _timeSlot;
  final double? _price;
  final int? _quantity;
  final double? _negotiatedPrice;
  final bool? _applyDiscount;
  final bool? _isPhysical;
  final String? _serviceTitle;
  final String? _serviceImage;
  final String? _providerName;
  final String? _providerImage;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  BookingItemModelIdentifier get modelIdentifier {
    return BookingItemModelIdentifier(id: id);
  }

  User? get user {
    return _user;
  }

  Booking? get booking {
    return _booking;
  }

  String? get sessionId {
    return _sessionId;
  }

  String? get tutorId {
    return _tutorId;
  }

  amplify_core.TemporalDateTime? get bookingDate {
    return _bookingDate;
  }

  String? get timeSlot {
    return _timeSlot;
  }

  double? get price {
    return _price;
  }

  int? get quantity {
    return _quantity;
  }

  double? get negotiatedPrice {
    return _negotiatedPrice;
  }

  bool? get applyDiscount {
    return _applyDiscount;
  }

  bool? get isPhysical {
    return _isPhysical;
  }

  String? get serviceTitle {
    return _serviceTitle;
  }

  String? get serviceImage {
    return _serviceImage;
  }

  String? get providerName {
    return _providerName;
  }

  String? get providerImage {
    return _providerImage;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const BookingItem._internal({
    required this.id,
    user,
    booking,
    sessionId,
    tutorId,
    bookingDate,
    timeSlot,
    price,
    quantity,
    negotiatedPrice,
    applyDiscount,
    isPhysical,
    serviceTitle,
    serviceImage,
    providerName,
    providerImage,
    createdAt,
    updatedAt,
  }) : _user = user,
       _booking = booking,
       _sessionId = sessionId,
       _tutorId = tutorId,
       _bookingDate = bookingDate,
       _timeSlot = timeSlot,
       _price = price,
       _quantity = quantity,
       _negotiatedPrice = negotiatedPrice,
       _applyDiscount = applyDiscount,
       _isPhysical = isPhysical,
       _serviceTitle = serviceTitle,
       _serviceImage = serviceImage,
       _providerName = providerName,
       _providerImage = providerImage,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory BookingItem({
    String? id,
    User? user,
    Booking? booking,
    String? sessionId,
    String? tutorId,
    amplify_core.TemporalDateTime? bookingDate,
    String? timeSlot,
    double? price,
    int? quantity,
    double? negotiatedPrice,
    bool? applyDiscount,
    bool? isPhysical,
    String? serviceTitle,
    String? serviceImage,
    String? providerName,
    String? providerImage,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return BookingItem._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      user: user,
      booking: booking,
      sessionId: sessionId,
      tutorId: tutorId,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      price: price,
      quantity: quantity,
      negotiatedPrice: negotiatedPrice,
      applyDiscount: applyDiscount,
      isPhysical: isPhysical,
      serviceTitle: serviceTitle,
      serviceImage: serviceImage,
      providerName: providerName,
      providerImage: providerImage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool equals(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BookingItem &&
        id == other.id &&
        _user == other._user &&
        _booking == other._booking &&
        _sessionId == other._sessionId &&
        _tutorId == other._tutorId &&
        _bookingDate == other._bookingDate &&
        _timeSlot == other._timeSlot &&
        _price == other._price &&
        _quantity == other._quantity &&
        _negotiatedPrice == other._negotiatedPrice &&
        _applyDiscount == other._applyDiscount &&
        _isPhysical == other._isPhysical &&
        _serviceTitle == other._serviceTitle &&
        _serviceImage == other._serviceImage &&
        _providerName == other._providerName &&
        _providerImage == other._providerImage &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("BookingItem {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("user=" + (_user != null ? _user.toString() : "null") + ", ");
    buffer.write(
      "booking=" + (_booking != null ? _booking.toString() : "null") + ", ",
    );
    buffer.write("sessionId=" + "$_sessionId" + ", ");
    buffer.write("tutorId=" + "$_tutorId" + ", ");
    buffer.write(
      "bookingDate=" +
          (_bookingDate != null ? _bookingDate.format() : "null") +
          ", ",
    );
    buffer.write("timeSlot=" + "$_timeSlot" + ", ");
    buffer.write(
      "price=" + (_price != null ? _price.toString() : "null") + ", ",
    );
    buffer.write(
      "quantity=" + (_quantity != null ? _quantity.toString() : "null") + ", ",
    );
    buffer.write(
      "negotiatedPrice=" +
          (_negotiatedPrice != null ? _negotiatedPrice.toString() : "null") +
          ", ",
    );
    buffer.write(
      "applyDiscount=" +
          (_applyDiscount != null ? _applyDiscount.toString() : "null") +
          ", ",
    );
    buffer.write(
      "isPhysical=" +
          (_isPhysical != null ? _isPhysical.toString() : "null") +
          ", ",
    );
    buffer.write("serviceTitle=" + "$_serviceTitle" + ", ");
    buffer.write("serviceImage=" + "$_serviceImage" + ", ");
    buffer.write("providerName=" + "$_providerName" + ", ");
    buffer.write("providerImage=" + "$_providerImage" + ", ");
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"),
    );
    buffer.write("}");

    return buffer.toString();
  }

  BookingItem copyWith({
    User? user,
    Booking? booking,
    String? sessionId,
    String? tutorId,
    amplify_core.TemporalDateTime? bookingDate,
    String? timeSlot,
    double? price,
    int? quantity,
    double? negotiatedPrice,
    bool? applyDiscount,
    bool? isPhysical,
    String? serviceTitle,
    String? serviceImage,
    String? providerName,
    String? providerImage,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return BookingItem._internal(
      id: id,
      user: user ?? this.user,
      booking: booking ?? this.booking,
      sessionId: sessionId ?? this.sessionId,
      tutorId: tutorId ?? this.tutorId,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
      applyDiscount: applyDiscount ?? this.applyDiscount,
      isPhysical: isPhysical ?? this.isPhysical,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceImage: serviceImage ?? this.serviceImage,
      providerName: providerName ?? this.providerName,
      providerImage: providerImage ?? this.providerImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  BookingItem copyWithModelFieldValues({
    ModelFieldValue<User?>? user,
    ModelFieldValue<Booking?>? booking,
    ModelFieldValue<String?>? sessionId,
    ModelFieldValue<String?>? tutorId,
    ModelFieldValue<amplify_core.TemporalDateTime?>? bookingDate,
    ModelFieldValue<String?>? timeSlot,
    ModelFieldValue<double?>? price,
    ModelFieldValue<int?>? quantity,
    ModelFieldValue<double?>? negotiatedPrice,
    ModelFieldValue<bool?>? applyDiscount,
    ModelFieldValue<bool?>? isPhysical,
    ModelFieldValue<String?>? serviceTitle,
    ModelFieldValue<String?>? serviceImage,
    ModelFieldValue<String?>? providerName,
    ModelFieldValue<String?>? providerImage,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt,
  }) {
    return BookingItem._internal(
      id: id,
      user: user == null ? this.user : user.value,
      booking: booking == null ? this.booking : booking.value,
      sessionId: sessionId == null ? this.sessionId : sessionId.value,
      tutorId: tutorId == null ? this.tutorId : tutorId.value,
      bookingDate: bookingDate == null ? this.bookingDate : bookingDate.value,
      timeSlot: timeSlot == null ? this.timeSlot : timeSlot.value,
      price: price == null ? this.price : price.value,
      quantity: quantity == null ? this.quantity : quantity.value,
      negotiatedPrice:
          negotiatedPrice == null
              ? this.negotiatedPrice
              : negotiatedPrice.value,
      applyDiscount:
          applyDiscount == null ? this.applyDiscount : applyDiscount.value,
      isPhysical: isPhysical == null ? this.isPhysical : isPhysical.value,
      serviceTitle:
          serviceTitle == null ? this.serviceTitle : serviceTitle.value,
      serviceImage:
          serviceImage == null ? this.serviceImage : serviceImage.value,
      providerName:
          providerName == null ? this.providerName : providerName.value,
      providerImage:
          providerImage == null ? this.providerImage : providerImage.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value,
    );
  }

  BookingItem.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _user =
          json['user'] != null
              ? json['user']['serializedData'] != null
                  ? User.fromJson(
                    new Map<String, dynamic>.from(
                      json['user']['serializedData'],
                    ),
                  )
                  : User.fromJson(new Map<String, dynamic>.from(json['user']))
              : null,
      _booking =
          json['booking'] != null
              ? json['booking']['serializedData'] != null
                  ? Booking.fromJson(
                    new Map<String, dynamic>.from(
                      json['booking']['serializedData'],
                    ),
                  )
                  : Booking.fromJson(
                    new Map<String, dynamic>.from(json['booking']),
                  )
              : null,
      _sessionId = json['sessionId'],
      _tutorId = json['tutorId'],
      _bookingDate =
          json['bookingDate'] != null
              ? amplify_core.TemporalDateTime.fromString(json['bookingDate'])
              : null,
      _timeSlot = json['timeSlot'],
      _price = (json['price'] as num?)?.toDouble(),
      _quantity = (json['quantity'] as num?)?.toInt(),
      _negotiatedPrice = (json['negotiatedPrice'] as num?)?.toDouble(),
      _applyDiscount = json['applyDiscount'],
      _isPhysical = json['isPhysical'],
      _serviceTitle = json['serviceTitle'],
      _serviceImage = json['serviceImage'],
      _providerName = json['providerName'],
      _providerImage = json['providerImage'],
      _createdAt =
          json['createdAt'] != null
              ? amplify_core.TemporalDateTime.fromString(json['createdAt'])
              : null,
      _updatedAt =
          json['updatedAt'] != null
              ? amplify_core.TemporalDateTime.fromString(json['updatedAt'])
              : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': _user?.toJson(),
    'booking': _booking?.toJson(),
    'sessionId': _sessionId,
    'tutorId': _tutorId,
    'bookingDate': _bookingDate?.format(),
    'timeSlot': _timeSlot,
    'price': _price,
    'quantity': _quantity,
    'negotiatedPrice': _negotiatedPrice,
    'applyDiscount': _applyDiscount,
    'isPhysical': _isPhysical,
    'serviceTitle': _serviceTitle,
    'serviceImage': _serviceImage,
    'providerName': _providerName,
    'providerImage': _providerImage,
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'user': _user,
    'booking': _booking,
    'sessionId': _sessionId,
    'tutorId': _tutorId,
    'bookingDate': _bookingDate,
    'timeSlot': _timeSlot,
    'price': _price,
    'quantity': _quantity,
    'negotiatedPrice': _negotiatedPrice,
    'applyDiscount': _applyDiscount,
    'isPhysical': _isPhysical,
    'serviceTitle': _serviceTitle,
    'serviceImage': _serviceImage,
    'providerName': _providerName,
    'providerImage': _providerImage,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<BookingItemModelIdentifier>
  MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<BookingItemModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USER = amplify_core.QueryField(
    fieldName: "user",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'User',
    ),
  );
  static final BOOKING = amplify_core.QueryField(
    fieldName: "booking",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'Booking',
    ),
  );
  static final SESSIONID = amplify_core.QueryField(fieldName: "sessionId");
  static final TUTORID = amplify_core.QueryField(fieldName: "tutorId");
  static final BOOKINGDATE = amplify_core.QueryField(fieldName: "bookingDate");
  static final TIMESLOT = amplify_core.QueryField(fieldName: "timeSlot");
  static final PRICE = amplify_core.QueryField(fieldName: "price");
  static final QUANTITY = amplify_core.QueryField(fieldName: "quantity");
  static final NEGOTIATEDPRICE = amplify_core.QueryField(
    fieldName: "negotiatedPrice",
  );
  static final APPLYDISCOUNT = amplify_core.QueryField(
    fieldName: "applyDiscount",
  );
  static final ISPHYSICAL = amplify_core.QueryField(fieldName: "isPhysical");
  static final SERVICETITLE = amplify_core.QueryField(
    fieldName: "serviceTitle",
  );
  static final SERVICEIMAGE = amplify_core.QueryField(
    fieldName: "serviceImage",
  );
  static final PROVIDERNAME = amplify_core.QueryField(
    fieldName: "providerName",
  );
  static final PROVIDERIMAGE = amplify_core.QueryField(
    fieldName: "providerImage",
  );
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "BookingItem";
      modelSchemaDefinition.pluralName = "BookingItems";

      modelSchemaDefinition.authRules = [
        amplify_core.AuthRule(
          authStrategy: amplify_core.AuthStrategy.OWNER,
          ownerField: "userId",
          identityClaim: "cognito:username",
          provider: amplify_core.AuthRuleProvider.USERPOOLS,
          operations: const [
            amplify_core.ModelOperation.CREATE,
            amplify_core.ModelOperation.READ,
            amplify_core.ModelOperation.UPDATE,
            amplify_core.ModelOperation.DELETE,
          ],
        ),
        amplify_core.AuthRule(
          authStrategy: amplify_core.AuthStrategy.PUBLIC,
          operations: const [amplify_core.ModelOperation.READ],
        ),
      ];

      modelSchemaDefinition.indexes = [
        amplify_core.ModelIndex(
          fields: const ["bookingId", "createdAt"],
          name: "byBooking",
        ),
      ];

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: BookingItem.USER,
          isRequired: false,
          targetNames: ['userId'],
          ofModelName: 'User',
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: BookingItem.BOOKING,
          isRequired: false,
          targetNames: ['bookingId'],
          ofModelName: 'Booking',
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.SESSIONID,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.TUTORID,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.BOOKINGDATE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.TIMESLOT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.PRICE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.double,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.QUANTITY,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.int,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.NEGOTIATEDPRICE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.double,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.APPLYDISCOUNT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.bool,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.ISPHYSICAL,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.bool,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.SERVICETITLE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.SERVICEIMAGE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.PROVIDERNAME,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.PROVIDERIMAGE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.CREATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: BookingItem.UPDATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );
    },
  );
}

class _BookingItemModelType extends amplify_core.ModelType<BookingItem> {
  const _BookingItemModelType();

  @override
  BookingItem fromJson(Map<String, dynamic> jsonData) {
    return BookingItem.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'BookingItem';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [BookingItem] in your schema.
 */
class BookingItemModelIdentifier
    implements amplify_core.ModelIdentifier<BookingItem> {
  final String id;

  /** Create an instance of BookingItemModelIdentifier using [id] the primary key. */
  const BookingItemModelIdentifier({required this.id});

  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{'id': id});

  @override
  List<Map<String, dynamic>> serializeAsList() =>
      serializeAsMap().entries
          .map((entry) => (<String, dynamic>{entry.key: entry.value}))
          .toList();

  @override
  String serializeAsString() => serializeAsMap().values.join('#');

  @override
  String toString() => 'BookingItemModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is BookingItemModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
