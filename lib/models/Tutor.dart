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

/** This is an auto generated class representing the Tutor type in your schema. */
class Tutor extends amplify_core.Model {
  static const classType = const _TutorModelType();
  final String id;
  final String? _name;
  final String? _email;
  final String? _image;
  final List<String>? _skills;
  final String? _about;
  final List<TutoringSession>? _tutoringSessions;
  final List<Review>? _reviews;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  TutorModelIdentifier get modelIdentifier {
    return TutorModelIdentifier(id: id);
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

  String? get image {
    return _image;
  }

  List<String>? get skills {
    return _skills;
  }

  String? get about {
    return _about;
  }

  List<TutoringSession>? get tutoringSessions {
    return _tutoringSessions;
  }

  List<Review>? get reviews {
    return _reviews;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const Tutor._internal({
    required this.id,
    required name,
    required email,
    image,
    skills,
    about,
    tutoringSessions,
    reviews,
    createdAt,
    updatedAt,
  }) : _name = name,
       _email = email,
       _image = image,
       _skills = skills,
       _about = about,
       _tutoringSessions = tutoringSessions,
       _reviews = reviews,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory Tutor({
    String? id,
    required String name,
    required String email,
    String? image,
    List<String>? skills,
    String? about,
    List<TutoringSession>? tutoringSessions,
    List<Review>? reviews,
  }) {
    return Tutor._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      name: name,
      email: email,
      image: image,
      skills: skills != null ? List<String>.unmodifiable(skills) : skills,
      about: about,
      tutoringSessions:
          tutoringSessions != null
              ? List<TutoringSession>.unmodifiable(tutoringSessions)
              : tutoringSessions,
      reviews: reviews != null ? List<Review>.unmodifiable(reviews) : reviews,
    );
  }

  bool equals(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Tutor &&
        id == other.id &&
        _name == other._name &&
        _email == other._email &&
        _image == other._image &&
        DeepCollectionEquality().equals(_skills, other._skills) &&
        _about == other._about &&
        DeepCollectionEquality().equals(
          _tutoringSessions,
          other._tutoringSessions,
        ) &&
        DeepCollectionEquality().equals(_reviews, other._reviews);
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("Tutor {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("image=" + "$_image" + ", ");
    buffer.write(
      "skills=" + (_skills != null ? _skills.toString() : "null") + ", ",
    );
    buffer.write("about=" + "$_about" + ", ");
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"),
    );
    buffer.write("}");

    return buffer.toString();
  }

  Tutor copyWith({
    String? name,
    String? email,
    String? image,
    List<String>? skills,
    String? about,
    List<TutoringSession>? tutoringSessions,
    List<Review>? reviews,
  }) {
    return Tutor._internal(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      skills: skills ?? this.skills,
      about: about ?? this.about,
      tutoringSessions: tutoringSessions ?? this.tutoringSessions,
      reviews: reviews ?? this.reviews,
    );
  }

  Tutor copyWithModelFieldValues({
    ModelFieldValue<String>? name,
    ModelFieldValue<String>? email,
    ModelFieldValue<String?>? image,
    ModelFieldValue<List<String>?>? skills,
    ModelFieldValue<String?>? about,
    ModelFieldValue<List<TutoringSession>?>? tutoringSessions,
    ModelFieldValue<List<Review>?>? reviews,
  }) {
    return Tutor._internal(
      id: id,
      name: name == null ? this.name : name.value,
      email: email == null ? this.email : email.value,
      image: image == null ? this.image : image.value,
      skills: skills == null ? this.skills : skills.value,
      about: about == null ? this.about : about.value,
      tutoringSessions:
          tutoringSessions == null
              ? this.tutoringSessions
              : tutoringSessions.value,
      reviews: reviews == null ? this.reviews : reviews.value,
    );
  }

  Tutor.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _name = json['name'],
      _email = json['email'],
      _image = json['image'],
      _skills = json['skills']?.cast<String>(),
      _about = json['about'],
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
      _reviews =
          json['reviews'] is Map
              ? (json['reviews']['items'] is List
                  ? (json['reviews']['items'] as List)
                      .where((e) => e != null)
                      .map(
                        (e) =>
                            Review.fromJson(new Map<String, dynamic>.from(e)),
                      )
                      .toList()
                  : null)
              : (json['reviews'] is List
                  ? (json['reviews'] as List)
                      .where((e) => e?['serializedData'] != null)
                      .map(
                        (e) => Review.fromJson(
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
    'email': _email,
    'image': _image,
    'skills': _skills,
    'about': _about,
    'tutoringSessions':
        _tutoringSessions?.map((TutoringSession? e) => e?.toJson()).toList(),
    'reviews': _reviews?.map((Review? e) => e?.toJson()).toList(),
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'name': _name,
    'email': _email,
    'image': _image,
    'skills': _skills,
    'about': _about,
    'tutoringSessions': _tutoringSessions,
    'reviews': _reviews,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<TutorModelIdentifier>
  MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<TutorModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final IMAGE = amplify_core.QueryField(fieldName: "image");
  static final SKILLS = amplify_core.QueryField(fieldName: "skills");
  static final ABOUT = amplify_core.QueryField(fieldName: "about");
  static final TUTORINGSESSIONS = amplify_core.QueryField(
    fieldName: "tutoringSessions",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'TutoringSession',
    ),
  );
  static final REVIEWS = amplify_core.QueryField(
    fieldName: "reviews",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'Review',
    ),
  );
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "Tutor";
      modelSchemaDefinition.pluralName = "Tutors";

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

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Tutor.NAME,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Tutor.EMAIL,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Tutor.IMAGE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Tutor.SKILLS,
          isRequired: false,
          isArray: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.collection,
            ofModelName: amplify_core.ModelFieldTypeEnum.string.name,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Tutor.ABOUT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.hasMany(
          key: Tutor.TUTORINGSESSIONS,
          isRequired: false,
          ofModelName: 'TutoringSession',
          associatedKey: TutoringSession.TUTOR,
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.hasMany(
          key: Tutor.REVIEWS,
          isRequired: false,
          ofModelName: 'Review',
          associatedKey: Review.TUTOR,
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

class _TutorModelType extends amplify_core.ModelType<Tutor> {
  const _TutorModelType();

  @override
  Tutor fromJson(Map<String, dynamic> jsonData) {
    return Tutor.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'Tutor';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Tutor] in your schema.
 */
class TutorModelIdentifier implements amplify_core.ModelIdentifier<Tutor> {
  final String id;

  /** Create an instance of TutorModelIdentifier using [id] the primary key. */
  const TutorModelIdentifier({required this.id});

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
  String toString() => 'TutorModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TutorModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
