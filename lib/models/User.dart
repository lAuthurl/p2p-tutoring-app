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

/** This is an auto generated class representing the User type in your schema. */
class User extends amplify_core.Model {
  static const classType = const _UserModelType();
  final String id;
  final String? _username;
  final String? _email;
  final String? _phoneNumber;
  final String? _profilePicture;
  final String? _deviceToken;
  final bool? _isEmailVerified;
  final bool? _isProfileActive;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;
  final String? _role;
  final String? _verificationStatus;
  final List<Booking>? _bookings;
  final List<BookingItem>? _bookingItems;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  UserModelIdentifier get modelIdentifier {
    return UserModelIdentifier(id: id);
  }

  String get username {
    try {
      return _username!;
    } catch (e) {
      throw amplify_core.AmplifyCodeGenModelException(
        amplify_core
            .AmplifyExceptionMessages
            .codeGenRequiredFieldForceCastExceptionMessage,
        recoverySuggestion:
            amplify_core
                .AmplifyExceptionMessages
                .codeGenRequiredFieldForceCastRecoverySuggestion,
        underlyingException: e.toString(),
      );
    }
  }

  String get email {
    try {
      return _email!;
    } catch (e) {
      throw amplify_core.AmplifyCodeGenModelException(
        amplify_core
            .AmplifyExceptionMessages
            .codeGenRequiredFieldForceCastExceptionMessage,
        recoverySuggestion:
            amplify_core
                .AmplifyExceptionMessages
                .codeGenRequiredFieldForceCastRecoverySuggestion,
        underlyingException: e.toString(),
      );
    }
  }

  String? get phoneNumber {
    return _phoneNumber;
  }

  String? get profilePicture {
    return _profilePicture;
  }

  String? get deviceToken {
    return _deviceToken;
  }

  bool? get isEmailVerified {
    return _isEmailVerified;
  }

  bool? get isProfileActive {
    return _isProfileActive;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  String? get role {
    return _role;
  }

  String? get verificationStatus {
    return _verificationStatus;
  }

  List<Booking>? get bookings {
    return _bookings;
  }

  List<BookingItem>? get bookingItems {
    return _bookingItems;
  }

  const User._internal({
    required this.id,
    required username,
    required email,
    phoneNumber,
    profilePicture,
    deviceToken,
    isEmailVerified,
    isProfileActive,
    createdAt,
    updatedAt,
    role,
    verificationStatus,
    bookings,
    bookingItems,
  }) : _username = username,
       _email = email,
       _phoneNumber = phoneNumber,
       _profilePicture = profilePicture,
       _deviceToken = deviceToken,
       _isEmailVerified = isEmailVerified,
       _isProfileActive = isProfileActive,
       _createdAt = createdAt,
       _updatedAt = updatedAt,
       _role = role,
       _verificationStatus = verificationStatus,
       _bookings = bookings,
       _bookingItems = bookingItems;

  factory User({
    String? id,
    required String username,
    required String email,
    String? phoneNumber,
    String? profilePicture,
    String? deviceToken,
    bool? isEmailVerified,
    bool? isProfileActive,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
    String? role,
    String? verificationStatus,
    List<Booking>? bookings,
    List<BookingItem>? bookingItems,
  }) {
    return User._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      profilePicture: profilePicture,
      deviceToken: deviceToken,
      isEmailVerified: isEmailVerified,
      isProfileActive: isProfileActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      role: role,
      verificationStatus: verificationStatus,
      bookings:
          bookings != null ? List<Booking>.unmodifiable(bookings) : bookings,
      bookingItems:
          bookingItems != null
              ? List<BookingItem>.unmodifiable(bookingItems)
              : bookingItems,
    );
  }

  bool equals(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User &&
        id == other.id &&
        _username == other._username &&
        _email == other._email &&
        _phoneNumber == other._phoneNumber &&
        _profilePicture == other._profilePicture &&
        _deviceToken == other._deviceToken &&
        _isEmailVerified == other._isEmailVerified &&
        _isProfileActive == other._isProfileActive &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt &&
        _role == other._role &&
        _verificationStatus == other._verificationStatus &&
        DeepCollectionEquality().equals(_bookings, other._bookings) &&
        DeepCollectionEquality().equals(_bookingItems, other._bookingItems);
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("User {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("username=" + "$_username" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("phoneNumber=" + "$_phoneNumber" + ", ");
    buffer.write("profilePicture=" + "$_profilePicture" + ", ");
    buffer.write("deviceToken=" + "$_deviceToken" + ", ");
    buffer.write(
      "isEmailVerified=" +
          (_isEmailVerified != null ? _isEmailVerified.toString() : "null") +
          ", ",
    );
    buffer.write(
      "isProfileActive=" +
          (_isProfileActive != null ? _isProfileActive.toString() : "null") +
          ", ",
    );
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null") + ", ",
    );
    buffer.write("role=" + "$_role" + ", ");
    buffer.write("verificationStatus=" + "$_verificationStatus");
    buffer.write("}");

    return buffer.toString();
  }

  User copyWith({
    String? username,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? deviceToken,
    bool? isEmailVerified,
    bool? isProfileActive,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
    String? role,
    String? verificationStatus,
    List<Booking>? bookings,
    List<BookingItem>? bookingItems,
  }) {
    return User._internal(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      deviceToken: deviceToken ?? this.deviceToken,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileActive: isProfileActive ?? this.isProfileActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      bookings: bookings ?? this.bookings,
      bookingItems: bookingItems ?? this.bookingItems,
    );
  }

  User copyWithModelFieldValues({
    ModelFieldValue<String>? username,
    ModelFieldValue<String>? email,
    ModelFieldValue<String?>? phoneNumber,
    ModelFieldValue<String?>? profilePicture,
    ModelFieldValue<String?>? deviceToken,
    ModelFieldValue<bool?>? isEmailVerified,
    ModelFieldValue<bool?>? isProfileActive,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt,
    ModelFieldValue<String?>? role,
    ModelFieldValue<String?>? verificationStatus,
    ModelFieldValue<List<Booking>?>? bookings,
    ModelFieldValue<List<BookingItem>?>? bookingItems,
  }) {
    return User._internal(
      id: id,
      username: username == null ? this.username : username.value,
      email: email == null ? this.email : email.value,
      phoneNumber: phoneNumber == null ? this.phoneNumber : phoneNumber.value,
      profilePicture:
          profilePicture == null ? this.profilePicture : profilePicture.value,
      deviceToken: deviceToken == null ? this.deviceToken : deviceToken.value,
      isEmailVerified:
          isEmailVerified == null
              ? this.isEmailVerified
              : isEmailVerified.value,
      isProfileActive:
          isProfileActive == null
              ? this.isProfileActive
              : isProfileActive.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value,
      role: role == null ? this.role : role.value,
      verificationStatus:
          verificationStatus == null
              ? this.verificationStatus
              : verificationStatus.value,
      bookings: bookings == null ? this.bookings : bookings.value,
      bookingItems:
          bookingItems == null ? this.bookingItems : bookingItems.value,
    );
  }

  User.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _username = json['username'],
      _email = json['email'],
      _phoneNumber = json['phoneNumber'],
      _profilePicture = json['profilePicture'],
      _deviceToken = json['deviceToken'],
      _isEmailVerified = json['isEmailVerified'],
      _isProfileActive = json['isProfileActive'],
      _createdAt =
          json['createdAt'] != null
              ? amplify_core.TemporalDateTime.fromString(json['createdAt'])
              : null,
      _updatedAt =
          json['updatedAt'] != null
              ? amplify_core.TemporalDateTime.fromString(json['updatedAt'])
              : null,
      _role = json['role'],
      _verificationStatus = json['verificationStatus'],
      _bookings =
          json['bookings'] is Map
              ? (json['bookings']['items'] is List
                  ? (json['bookings']['items'] as List)
                      .where((e) => e != null)
                      .map(
                        (e) =>
                            Booking.fromJson(new Map<String, dynamic>.from(e)),
                      )
                      .toList()
                  : null)
              : (json['bookings'] is List
                  ? (json['bookings'] as List)
                      .where((e) => e?['serializedData'] != null)
                      .map(
                        (e) => Booking.fromJson(
                          new Map<String, dynamic>.from(e?['serializedData']),
                        ),
                      )
                      .toList()
                  : null),
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
                  : null);

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': _username,
    'email': _email,
    'phoneNumber': _phoneNumber,
    'profilePicture': _profilePicture,
    'deviceToken': _deviceToken,
    'isEmailVerified': _isEmailVerified,
    'isProfileActive': _isProfileActive,
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
    'role': _role,
    'verificationStatus': _verificationStatus,
    'bookings': _bookings?.map((Booking? e) => e?.toJson()).toList(),
    'bookingItems':
        _bookingItems?.map((BookingItem? e) => e?.toJson()).toList(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'username': _username,
    'email': _email,
    'phoneNumber': _phoneNumber,
    'profilePicture': _profilePicture,
    'deviceToken': _deviceToken,
    'isEmailVerified': _isEmailVerified,
    'isProfileActive': _isProfileActive,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
    'role': _role,
    'verificationStatus': _verificationStatus,
    'bookings': _bookings,
    'bookingItems': _bookingItems,
  };

  static final amplify_core.QueryModelIdentifier<UserModelIdentifier>
  MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USERNAME = amplify_core.QueryField(fieldName: "username");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final PHONENUMBER = amplify_core.QueryField(fieldName: "phoneNumber");
  static final PROFILEPICTURE = amplify_core.QueryField(
    fieldName: "profilePicture",
  );
  static final DEVICETOKEN = amplify_core.QueryField(fieldName: "deviceToken");
  static final ISEMAILVERIFIED = amplify_core.QueryField(
    fieldName: "isEmailVerified",
  );
  static final ISPROFILEACTIVE = amplify_core.QueryField(
    fieldName: "isProfileActive",
  );
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static final ROLE = amplify_core.QueryField(fieldName: "role");
  static final VERIFICATIONSTATUS = amplify_core.QueryField(
    fieldName: "verificationStatus",
  );
  static final BOOKINGS = amplify_core.QueryField(
    fieldName: "bookings",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'Booking',
    ),
  );
  static final BOOKINGITEMS = amplify_core.QueryField(
    fieldName: "bookingItems",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'BookingItem',
    ),
  );
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "User";
      modelSchemaDefinition.pluralName = "Users";

      modelSchemaDefinition.authRules = [
        amplify_core.AuthRule(
          authStrategy: amplify_core.AuthStrategy.OWNER,
          ownerField: "id",
          identityClaim: "cognito:username",
          provider: amplify_core.AuthRuleProvider.USERPOOLS,
          operations: const [
            amplify_core.ModelOperation.CREATE,
            amplify_core.ModelOperation.READ,
            amplify_core.ModelOperation.UPDATE,
            amplify_core.ModelOperation.DELETE,
          ],
        ),
      ];

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.USERNAME,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.EMAIL,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.PHONENUMBER,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.PROFILEPICTURE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.DEVICETOKEN,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.ISEMAILVERIFIED,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.bool,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.ISPROFILEACTIVE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.bool,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.CREATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.UPDATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.ROLE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: User.VERIFICATIONSTATUS,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.hasMany(
          key: User.BOOKINGS,
          isRequired: false,
          ofModelName: 'Booking',
          associatedKey: Booking.USER,
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.hasMany(
          key: User.BOOKINGITEMS,
          isRequired: false,
          ofModelName: 'BookingItem',
          associatedKey: BookingItem.USER,
        ),
      );
    },
  );
}

class _UserModelType extends amplify_core.ModelType<User> {
  const _UserModelType();

  @override
  User fromJson(Map<String, dynamic> jsonData) {
    return User.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'User';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [User] in your schema.
 */
class UserModelIdentifier implements amplify_core.ModelIdentifier<User> {
  final String id;

  /** Create an instance of UserModelIdentifier using [id] the primary key. */
  const UserModelIdentifier({required this.id});

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
  String toString() => 'UserModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
