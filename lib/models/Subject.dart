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

/** This is an auto generated class representing the Subject type in your schema. */
class Subject extends amplify_core.Model {
  static const classType = const _SubjectModelType();
  final String id;
  final String? _name;
  final String? _icon;
  final String? _thumbnail;
  final bool? _isFeatured;
  final List<TutoringSession>? _tutoringSessions;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  SubjectModelIdentifier get modelIdentifier {
    return SubjectModelIdentifier(id: id);
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

  String? get icon {
    return _icon;
  }

  String? get thumbnail {
    return _thumbnail;
  }

  bool? get isFeatured {
    return _isFeatured;
  }

  List<TutoringSession>? get tutoringSessions {
    return _tutoringSessions;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const Subject._internal({
    required this.id,
    required name,
    icon,
    thumbnail,
    isFeatured,
    tutoringSessions,
    createdAt,
    updatedAt,
  }) : _name = name,
       _icon = icon,
       _thumbnail = thumbnail,
       _isFeatured = isFeatured,
       _tutoringSessions = tutoringSessions,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory Subject({
    String? id,
    required String name,
    String? icon,
    String? thumbnail,
    bool? isFeatured,
    List<TutoringSession>? tutoringSessions,
  }) {
    return Subject._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      name: name,
      icon: icon,
      thumbnail: thumbnail,
      isFeatured: isFeatured,
      tutoringSessions:
          tutoringSessions != null
              ? List<TutoringSession>.unmodifiable(tutoringSessions)
              : tutoringSessions,
    );
  }

  bool equals(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Subject &&
        id == other.id &&
        _name == other._name &&
        _icon == other._icon &&
        _thumbnail == other._thumbnail &&
        _isFeatured == other._isFeatured &&
        DeepCollectionEquality().equals(
          _tutoringSessions,
          other._tutoringSessions,
        );
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("Subject {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("icon=" + "$_icon" + ", ");
    buffer.write("thumbnail=" + "$_thumbnail" + ", ");
    buffer.write(
      "isFeatured=" +
          (_isFeatured != null ? _isFeatured.toString() : "null") +
          ", ",
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

  Subject copyWith({
    String? name,
    String? icon,
    String? thumbnail,
    bool? isFeatured,
    List<TutoringSession>? tutoringSessions,
  }) {
    return Subject._internal(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      thumbnail: thumbnail ?? this.thumbnail,
      isFeatured: isFeatured ?? this.isFeatured,
      tutoringSessions: tutoringSessions ?? this.tutoringSessions,
    );
  }

  Subject copyWithModelFieldValues({
    ModelFieldValue<String>? name,
    ModelFieldValue<String?>? icon,
    ModelFieldValue<String?>? thumbnail,
    ModelFieldValue<bool?>? isFeatured,
    ModelFieldValue<List<TutoringSession>?>? tutoringSessions,
  }) {
    return Subject._internal(
      id: id,
      name: name == null ? this.name : name.value,
      icon: icon == null ? this.icon : icon.value,
      thumbnail: thumbnail == null ? this.thumbnail : thumbnail.value,
      isFeatured: isFeatured == null ? this.isFeatured : isFeatured.value,
      tutoringSessions:
          tutoringSessions == null
              ? this.tutoringSessions
              : tutoringSessions.value,
    );
  }

  Subject.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _name = json['name'],
      _icon = json['icon'],
      _thumbnail = json['thumbnail'],
      _isFeatured = json['isFeatured'],
      _tutoringSessions =
          json['tutoringSessions'] is Map
              ? (json['tutoringSessions']['items'] is List
                  ? (json['tutoringSessions']['items'] as List)
                      .where((e) => e != null)
                      .map(
                        (e) => TutoringSession.fromJson(
                          new Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList()
                  : null)
              : (json['tutoringSessions'] is List
                  ? (json['tutoringSessions'] as List)
                      .where((e) => e?['serializedData'] != null)
                      .map(
                        (e) => TutoringSession.fromJson(
                          new Map<String, dynamic>.from(e?['serializedData']),
                        ),
                      )
                      .toList()
                  : null),
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
    'name': _name,
    'icon': _icon,
    'thumbnail': _thumbnail,
    'isFeatured': _isFeatured,
    'tutoringSessions':
        _tutoringSessions?.map((TutoringSession? e) => e?.toJson()).toList(),
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'name': _name,
    'icon': _icon,
    'thumbnail': _thumbnail,
    'isFeatured': _isFeatured,
    'tutoringSessions': _tutoringSessions,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<SubjectModelIdentifier>
  MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<SubjectModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final ICON = amplify_core.QueryField(fieldName: "icon");
  static final THUMBNAIL = amplify_core.QueryField(fieldName: "thumbnail");
  static final ISFEATURED = amplify_core.QueryField(fieldName: "isFeatured");
  static final TUTORINGSESSIONS = amplify_core.QueryField(
    fieldName: "tutoringSessions",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'TutoringSession',
    ),
  );
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "Subject";
      modelSchemaDefinition.pluralName = "Subjects";

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
          key: Subject.NAME,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Subject.ICON,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Subject.THUMBNAIL,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Subject.ISFEATURED,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.bool,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.hasMany(
          key: Subject.TUTORINGSESSIONS,
          isRequired: false,
          ofModelName: 'TutoringSession',
          associatedKey: TutoringSession.SUBJECT,
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.nonQueryField(
          fieldName: 'createdAt',
          isRequired: false,
          isReadOnly: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.nonQueryField(
          fieldName: 'updatedAt',
          isRequired: false,
          isReadOnly: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );
    },
  );
}

class _SubjectModelType extends amplify_core.ModelType<Subject> {
  const _SubjectModelType();

  @override
  Subject fromJson(Map<String, dynamic> jsonData) {
    return Subject.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'Subject';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Subject] in your schema.
 */
class SubjectModelIdentifier implements amplify_core.ModelIdentifier<Subject> {
  final String id;

  /** Create an instance of SubjectModelIdentifier using [id] the primary key. */
  const SubjectModelIdentifier({required this.id});

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
  String toString() => 'SubjectModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SubjectModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
