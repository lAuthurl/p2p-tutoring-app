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

/** This is an auto generated class representing the UserSessionPayment type in your schema. */
class UserSessionPayment extends amplify_core.Model {
  static const classType = const _UserSessionPaymentModelType();
  final String id;
  final String? _userId;
  final String? _sessionId;
  final bool? _hasPaid;
  final amplify_core.TemporalDateTime? _paidAt;
  final double? _amountPaid;
  final String? _reference;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  UserSessionPaymentModelIdentifier get modelIdentifier {
    return UserSessionPaymentModelIdentifier(id: id);
  }

  String get userId {
    try {
      return _userId!;
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

  String get sessionId {
    try {
      return _sessionId!;
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

  bool get hasPaid {
    try {
      return _hasPaid!;
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

  amplify_core.TemporalDateTime? get paidAt {
    return _paidAt;
  }

  double? get amountPaid {
    return _amountPaid;
  }

  String? get reference {
    return _reference;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const UserSessionPayment._internal({
    required this.id,
    required userId,
    required sessionId,
    required hasPaid,
    paidAt,
    amountPaid,
    reference,
    createdAt,
    updatedAt,
  }) : _userId = userId,
       _sessionId = sessionId,
       _hasPaid = hasPaid,
       _paidAt = paidAt,
       _amountPaid = amountPaid,
       _reference = reference,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory UserSessionPayment({
    String? id,
    required String userId,
    required String sessionId,
    required bool hasPaid,
    amplify_core.TemporalDateTime? paidAt,
    double? amountPaid,
    String? reference,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return UserSessionPayment._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      userId: userId,
      sessionId: sessionId,
      hasPaid: hasPaid,
      paidAt: paidAt,
      amountPaid: amountPaid,
      reference: reference,
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
    return other is UserSessionPayment &&
        id == other.id &&
        _userId == other._userId &&
        _sessionId == other._sessionId &&
        _hasPaid == other._hasPaid &&
        _paidAt == other._paidAt &&
        _amountPaid == other._amountPaid &&
        _reference == other._reference &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("UserSessionPayment {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("userId=" + "$_userId" + ", ");
    buffer.write("sessionId=" + "$_sessionId" + ", ");
    buffer.write(
      "hasPaid=" + (_hasPaid != null ? _hasPaid.toString() : "null") + ", ",
    );
    buffer.write(
      "paidAt=" + (_paidAt != null ? _paidAt.format() : "null") + ", ",
    );
    buffer.write(
      "amountPaid=" +
          (_amountPaid != null ? _amountPaid.toString() : "null") +
          ", ",
    );
    buffer.write("reference=" + "$_reference" + ", ");
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"),
    );
    buffer.write("}");

    return buffer.toString();
  }

  UserSessionPayment copyWith({
    String? userId,
    String? sessionId,
    bool? hasPaid,
    amplify_core.TemporalDateTime? paidAt,
    double? amountPaid,
    String? reference,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return UserSessionPayment._internal(
      id: id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      hasPaid: hasPaid ?? this.hasPaid,
      paidAt: paidAt ?? this.paidAt,
      amountPaid: amountPaid ?? this.amountPaid,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserSessionPayment copyWithModelFieldValues({
    ModelFieldValue<String>? userId,
    ModelFieldValue<String>? sessionId,
    ModelFieldValue<bool>? hasPaid,
    ModelFieldValue<amplify_core.TemporalDateTime?>? paidAt,
    ModelFieldValue<double?>? amountPaid,
    ModelFieldValue<String?>? reference,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt,
  }) {
    return UserSessionPayment._internal(
      id: id,
      userId: userId == null ? this.userId : userId.value,
      sessionId: sessionId == null ? this.sessionId : sessionId.value,
      hasPaid: hasPaid == null ? this.hasPaid : hasPaid.value,
      paidAt: paidAt == null ? this.paidAt : paidAt.value,
      amountPaid: amountPaid == null ? this.amountPaid : amountPaid.value,
      reference: reference == null ? this.reference : reference.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value,
    );
  }

  UserSessionPayment.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _userId = json['userId'],
      _sessionId = json['sessionId'],
      _hasPaid = json['hasPaid'],
      _paidAt =
          json['paidAt'] != null
              ? amplify_core.TemporalDateTime.fromString(json['paidAt'])
              : null,
      _amountPaid = (json['amountPaid'] as num?)?.toDouble(),
      _reference = json['reference'],
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
    'userId': _userId,
    'sessionId': _sessionId,
    'hasPaid': _hasPaid,
    'paidAt': _paidAt?.format(),
    'amountPaid': _amountPaid,
    'reference': _reference,
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': _userId,
    'sessionId': _sessionId,
    'hasPaid': _hasPaid,
    'paidAt': _paidAt,
    'amountPaid': _amountPaid,
    'reference': _reference,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<
    UserSessionPaymentModelIdentifier
  >
  MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<UserSessionPaymentModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USERID = amplify_core.QueryField(fieldName: "userId");
  static final SESSIONID = amplify_core.QueryField(fieldName: "sessionId");
  static final HASPAID = amplify_core.QueryField(fieldName: "hasPaid");
  static final PAIDAT = amplify_core.QueryField(fieldName: "paidAt");
  static final AMOUNTPAID = amplify_core.QueryField(fieldName: "amountPaid");
  static final REFERENCE = amplify_core.QueryField(fieldName: "reference");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "UserSessionPayment";
      modelSchemaDefinition.pluralName = "UserSessionPayments";

      modelSchemaDefinition.authRules = [
        amplify_core.AuthRule(
          authStrategy: amplify_core.AuthStrategy.OWNER,
          ownerField: "owner",
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
        amplify_core.ModelIndex(fields: const ["userId"], name: "byUser"),
        amplify_core.ModelIndex(fields: const ["sessionId"], name: "bySession"),
      ];

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.USERID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.SESSIONID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.HASPAID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.bool,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.PAIDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.AMOUNTPAID,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.double,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.REFERENCE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.CREATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: UserSessionPayment.UPDATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );
    },
  );
}

class _UserSessionPaymentModelType
    extends amplify_core.ModelType<UserSessionPayment> {
  const _UserSessionPaymentModelType();

  @override
  UserSessionPayment fromJson(Map<String, dynamic> jsonData) {
    return UserSessionPayment.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'UserSessionPayment';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UserSessionPayment] in your schema.
 */
class UserSessionPaymentModelIdentifier
    implements amplify_core.ModelIdentifier<UserSessionPayment> {
  final String id;

  /** Create an instance of UserSessionPaymentModelIdentifier using [id] the primary key. */
  const UserSessionPaymentModelIdentifier({required this.id});

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
  String toString() => 'UserSessionPaymentModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserSessionPaymentModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
