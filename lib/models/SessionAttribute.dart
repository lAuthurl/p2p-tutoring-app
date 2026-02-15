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

/** This is an auto generated class representing the SessionAttribute type in your schema. */
class SessionAttribute extends amplify_core.Model {
  static const classType = const _SessionAttributeModelType();
  final String id;
  final String? _tutorId;
  final String? _name;
  final List<String>? _values;
  final TutoringSession? _session;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  SessionAttributeModelIdentifier get modelIdentifier {
    return SessionAttributeModelIdentifier(id: id);
  }

  String get tutorId {
    try {
      return _tutorId!;
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

  String get name {
    try {
      return _name!;
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

  List<String>? get values {
    return _values;
  }

  TutoringSession? get session {
    return _session;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const SessionAttribute._internal({
    required this.id,
    required tutorId,
    required name,
    values,
    session,
    createdAt,
    updatedAt,
  }) : _tutorId = tutorId,
       _name = name,
       _values = values,
       _session = session,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory SessionAttribute({
    String? id,
    required String tutorId,
    required String name,
    List<String>? values,
    TutoringSession? session,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return SessionAttribute._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      tutorId: tutorId,
      name: name,
      values: values != null ? List<String>.unmodifiable(values) : values,
      session: session,
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
    return other is SessionAttribute &&
        id == other.id &&
        _tutorId == other._tutorId &&
        _name == other._name &&
        DeepCollectionEquality().equals(_values, other._values) &&
        _session == other._session &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("SessionAttribute {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("tutorId=" + "$_tutorId" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write(
      "values=" + (_values != null ? _values.toString() : "null") + ", ",
    );
    buffer.write(
      "session=" + (_session != null ? _session.toString() : "null") + ", ",
    );
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"),
    );
    buffer.write("}");

    return buffer.toString();
  }

  SessionAttribute copyWith({
    String? tutorId,
    String? name,
    List<String>? values,
    TutoringSession? session,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return SessionAttribute._internal(
      id: id,
      tutorId: tutorId ?? this.tutorId,
      name: name ?? this.name,
      values: values ?? this.values,
      session: session ?? this.session,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  SessionAttribute copyWithModelFieldValues({
    ModelFieldValue<String>? tutorId,
    ModelFieldValue<String>? name,
    ModelFieldValue<List<String>?>? values,
    ModelFieldValue<TutoringSession?>? session,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt,
  }) {
    return SessionAttribute._internal(
      id: id,
      tutorId: tutorId == null ? this.tutorId : tutorId.value,
      name: name == null ? this.name : name.value,
      values: values == null ? this.values : values.value,
      session: session == null ? this.session : session.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value,
    );
  }

  SessionAttribute.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _tutorId = json['tutorId'],
      _name = json['name'],
      _values = json['values']?.cast<String>(),
      _session =
          json['session'] != null
              ? json['session']['serializedData'] != null
                  ? TutoringSession.fromJson(
                    new Map<String, dynamic>.from(
                      json['session']['serializedData'],
                    ),
                  )
                  : TutoringSession.fromJson(
                    new Map<String, dynamic>.from(json['session']),
                  )
              : null,
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
    'tutorId': _tutorId,
    'name': _name,
    'values': _values,
    'session': _session?.toJson(),
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'tutorId': _tutorId,
    'name': _name,
    'values': _values,
    'session': _session,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<
    SessionAttributeModelIdentifier
  >
  MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<SessionAttributeModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TUTORID = amplify_core.QueryField(fieldName: "tutorId");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final VALUES = amplify_core.QueryField(fieldName: "values");
  static final SESSION = amplify_core.QueryField(
    fieldName: "session",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'TutoringSession',
    ),
  );
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "SessionAttribute";
      modelSchemaDefinition.pluralName = "SessionAttributes";

      modelSchemaDefinition.authRules = [
        amplify_core.AuthRule(
          authStrategy: amplify_core.AuthStrategy.OWNER,
          ownerField: "tutorId",
          identityClaim: "cognito:username",
          provider: amplify_core.AuthRuleProvider.USERPOOLS,
          operations: const [
            amplify_core.ModelOperation.CREATE,
            amplify_core.ModelOperation.UPDATE,
            amplify_core.ModelOperation.DELETE,
            amplify_core.ModelOperation.READ,
          ],
        ),
        amplify_core.AuthRule(
          authStrategy: amplify_core.AuthStrategy.PUBLIC,
          operations: const [amplify_core.ModelOperation.READ],
        ),
      ];

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionAttribute.TUTORID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionAttribute.NAME,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionAttribute.VALUES,
          isRequired: false,
          isArray: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.collection,
            ofModelName: amplify_core.ModelFieldTypeEnum.string.name,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: SessionAttribute.SESSION,
          isRequired: false,
          targetNames: ['sessionId'],
          ofModelName: 'TutoringSession',
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionAttribute.CREATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionAttribute.UPDATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );
    },
  );
}

class _SessionAttributeModelType
    extends amplify_core.ModelType<SessionAttribute> {
  const _SessionAttributeModelType();

  @override
  SessionAttribute fromJson(Map<String, dynamic> jsonData) {
    return SessionAttribute.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'SessionAttribute';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [SessionAttribute] in your schema.
 */
class SessionAttributeModelIdentifier
    implements amplify_core.ModelIdentifier<SessionAttribute> {
  final String id;

  /** Create an instance of SessionAttributeModelIdentifier using [id] the primary key. */
  const SessionAttributeModelIdentifier({required this.id});

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
  String toString() => 'SessionAttributeModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SessionAttributeModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
