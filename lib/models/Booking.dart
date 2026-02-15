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
import 'package:collection/collection.dart';

/** This is an auto generated class representing the Booking type in your schema. */
class Booking extends amplify_core.Model {
  static const classType = const _BookingModelType();
  final String id;
  final User? _user;
  final List<BookingItem>? _bookingItems;
  final double? _totalPrice;
  final String? _status;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  BookingModelIdentifier get modelIdentifier {
    return BookingModelIdentifier(id: id);
  }

  User? get user {
    return _user;
  }

  List<BookingItem>? get bookingItems {
    return _bookingItems;
  }

  double? get totalPrice {
    return _totalPrice;
  }

  String? get status {
    return _status;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const Booking._internal({
    required this.id,
    user,
    bookingItems,
    totalPrice,
    status,
    createdAt,
    updatedAt,
  }) : _user = user,
       _bookingItems = bookingItems,
       _totalPrice = totalPrice,
       _status = status,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory Booking({
    String? id,
    User? user,
    List<BookingItem>? bookingItems,
    double? totalPrice,
    String? status,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return Booking._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      user: user,
      bookingItems:
          bookingItems != null
              ? List<BookingItem>.unmodifiable(bookingItems)
              : bookingItems,
      totalPrice: totalPrice,
      status: status,
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
    return other is Booking &&
        id == other.id &&
        _user == other._user &&
        DeepCollectionEquality().equals(_bookingItems, other._bookingItems) &&
        _totalPrice == other._totalPrice &&
        _status == other._status &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("Booking {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("user=" + (_user != null ? _user.toString() : "null") + ", ");
    buffer.write(
      "totalPrice=" +
          (_totalPrice != null ? _totalPrice.toString() : "null") +
          ", ",
    );
    buffer.write("status=" + "$_status" + ", ");
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"),
    );
    buffer.write("}");

    return buffer.toString();
  }

  Booking copyWith({
    User? user,
    List<BookingItem>? bookingItems,
    double? totalPrice,
    String? status,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return Booking._internal(
      id: id,
      user: user ?? this.user,
      bookingItems: bookingItems ?? this.bookingItems,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Booking copyWithModelFieldValues({
    ModelFieldValue<User?>? user,
    ModelFieldValue<List<BookingItem>?>? bookingItems,
    ModelFieldValue<double?>? totalPrice,
    ModelFieldValue<String?>? status,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt,
  }) {
    return Booking._internal(
      id: id,
      user: user == null ? this.user : user.value,
      bookingItems:
          bookingItems == null ? this.bookingItems : bookingItems.value,
      totalPrice: totalPrice == null ? this.totalPrice : totalPrice.value,
      status: status == null ? this.status : status.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value,
    );
  }

  Booking.fromJson(Map<String, dynamic> json)
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
      _bookingItems =
          json['bookingItems'] is Map
              ? (json['bookingItems']['items'] is List
                  ? (json['bookingItems']['items'] as List)
                      .where((e) => e != null)
                      .map(
                        (e) => BookingItem.fromJson(
                          new Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList()
                  : null)
              : (json['bookingItems'] is List
                  ? (json['bookingItems'] as List)
                      .where((e) => e?['serializedData'] != null)
                      .map(
                        (e) => BookingItem.fromJson(
                          new Map<String, dynamic>.from(e?['serializedData']),
                        ),
                      )
                      .toList()
                  : null),
      _totalPrice = (json['totalPrice'] as num?)?.toDouble(),
      _status = json['status'],
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
    'bookingItems':
        _bookingItems?.map((BookingItem? e) => e?.toJson()).toList(),
    'totalPrice': _totalPrice,
    'status': _status,
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'user': _user,
    'bookingItems': _bookingItems,
    'totalPrice': _totalPrice,
    'status': _status,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<BookingModelIdentifier>
  MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<BookingModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USER = amplify_core.QueryField(
    fieldName: "user",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'User',
    ),
  );
  static final BOOKINGITEMS = amplify_core.QueryField(
    fieldName: "bookingItems",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'BookingItem',
    ),
  );
  static final TOTALPRICE = amplify_core.QueryField(fieldName: "totalPrice");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "Booking";
      modelSchemaDefinition.pluralName = "Bookings";

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

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: Booking.USER,
          isRequired: false,
          targetNames: ['userId'],
          ofModelName: 'User',
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.hasMany(
          key: Booking.BOOKINGITEMS,
          isRequired: false,
          ofModelName: 'BookingItem',
          associatedKey: BookingItem.BOOKING,
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Booking.TOTALPRICE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.double,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Booking.STATUS,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Booking.CREATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Booking.UPDATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );
    },
  );
}

class _BookingModelType extends amplify_core.ModelType<Booking> {
  const _BookingModelType();

  @override
  Booking fromJson(Map<String, dynamic> jsonData) {
    return Booking.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'Booking';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Booking] in your schema.
 */
class BookingModelIdentifier implements amplify_core.ModelIdentifier<Booking> {
  final String id;

  /** Create an instance of BookingModelIdentifier using [id] the primary key. */
  const BookingModelIdentifier({required this.id});

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
  String toString() => 'BookingModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is BookingModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
