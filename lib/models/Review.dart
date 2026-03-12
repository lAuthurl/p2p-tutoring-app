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

/** This is an auto generated class representing the Review type in your schema. */
class Review extends amplify_core.Model {
  static const classType = const _ReviewModelType();
  final String id;
  final User? _user;
  final String? _sessionId;
  final Tutor? _tutor;
  final double? _rating;
  final String? _comment;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  ReviewModelIdentifier get modelIdentifier {
    return ReviewModelIdentifier(id: id);
  }

  User? get user {
    return _user;
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

  Tutor? get tutor {
    return _tutor;
  }

  double get rating {
    try {
      return _rating!;
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

  String? get comment {
    return _comment;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const Review._internal({
    required this.id,
    user,
    required sessionId,
    tutor,
    required rating,
    comment,
    createdAt,
    updatedAt,
  }) : _user = user,
       _sessionId = sessionId,
       _tutor = tutor,
       _rating = rating,
       _comment = comment,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory Review({
    String? id,
    User? user,
    required String sessionId,
    Tutor? tutor,
    required double rating,
    String? comment,
    amplify_core.TemporalDateTime? createdAt,
  }) {
    return Review._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      user: user,
      sessionId: sessionId,
      tutor: tutor,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }

  bool equals(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Review &&
        id == other.id &&
        _user == other._user &&
        _sessionId == other._sessionId &&
        _tutor == other._tutor &&
        _rating == other._rating &&
        _comment == other._comment &&
        _createdAt == other._createdAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("Review {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("user=" + (_user != null ? _user.toString() : "null") + ", ");
    buffer.write("sessionId=" + "$_sessionId" + ", ");
    buffer.write(
      "tutor=" + (_tutor != null ? _tutor.toString() : "null") + ", ",
    );
    buffer.write(
      "rating=" + (_rating != null ? _rating.toString() : "null") + ", ",
    );
    buffer.write("comment=" + "$_comment" + ", ");
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"),
    );
    buffer.write("}");

    return buffer.toString();
  }

  Review copyWith({
    User? user,
    String? sessionId,
    Tutor? tutor,
    double? rating,
    String? comment,
    amplify_core.TemporalDateTime? createdAt,
  }) {
    return Review._internal(
      id: id,
      user: user ?? this.user,
      sessionId: sessionId ?? this.sessionId,
      tutor: tutor ?? this.tutor,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Review copyWithModelFieldValues({
    ModelFieldValue<User?>? user,
    ModelFieldValue<String>? sessionId,
    ModelFieldValue<Tutor?>? tutor,
    ModelFieldValue<double>? rating,
    ModelFieldValue<String?>? comment,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
  }) {
    return Review._internal(
      id: id,
      user: user == null ? this.user : user.value,
      sessionId: sessionId == null ? this.sessionId : sessionId.value,
      tutor: tutor == null ? this.tutor : tutor.value,
      rating: rating == null ? this.rating : rating.value,
      comment: comment == null ? this.comment : comment.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
    );
  }

  Review.fromJson(Map<String, dynamic> json)
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
      _sessionId = json['sessionId'],
      _tutor =
          json['tutor'] != null
              ? json['tutor']['serializedData'] != null
                  ? Tutor.fromJson(
                    new Map<String, dynamic>.from(
                      json['tutor']['serializedData'],
                    ),
                  )
                  : Tutor.fromJson(new Map<String, dynamic>.from(json['tutor']))
              : null,
      _rating = (json['rating'] as num?)?.toDouble(),
      _comment = json['comment'],
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
    'sessionId': _sessionId,
    'tutor': _tutor?.toJson(),
    'rating': _rating,
    'comment': _comment,
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'user': _user,
    'sessionId': _sessionId,
    'tutor': _tutor,
    'rating': _rating,
    'comment': _comment,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<ReviewModelIdentifier>
  MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ReviewModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USER = amplify_core.QueryField(
    fieldName: "user",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'User',
    ),
  );
  static final SESSIONID = amplify_core.QueryField(fieldName: "sessionId");
  static final TUTOR = amplify_core.QueryField(
    fieldName: "tutor",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'Tutor',
    ),
  );
  static final RATING = amplify_core.QueryField(fieldName: "rating");
  static final COMMENT = amplify_core.QueryField(fieldName: "comment");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "Review";
      modelSchemaDefinition.pluralName = "Reviews";

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
        amplify_core.ModelIndex(fields: const ["tutorId"], name: "byTutor"),
      ];

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: Review.USER,
          isRequired: false,
          targetNames: ['userId'],
          ofModelName: 'User',
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Review.SESSIONID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: Review.TUTOR,
          isRequired: false,
          targetNames: ['tutorId'],
          ofModelName: 'Tutor',
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Review.RATING,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.double,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Review.COMMENT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Review.CREATEDAT,
          isRequired: false,
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

class _ReviewModelType extends amplify_core.ModelType<Review> {
  const _ReviewModelType();

  @override
  Review fromJson(Map<String, dynamic> jsonData) {
    return Review.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'Review';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Review] in your schema.
 */
class ReviewModelIdentifier implements amplify_core.ModelIdentifier<Review> {
  final String id;

  /** Create an instance of ReviewModelIdentifier using [id] the primary key. */
  const ReviewModelIdentifier({required this.id});

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
  String toString() => 'ReviewModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ReviewModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
