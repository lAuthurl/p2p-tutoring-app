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
  final String? _userId;
  final String? _reviewText;
  final double? _rating;
  final Tutor? _tutor;
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

  String? get userId {
    return _userId;
  }

  String? get reviewText {
    return _reviewText;
  }

  double? get rating {
    return _rating;
  }

  Tutor? get tutor {
    return _tutor;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const Review._internal({
    required this.id,
    userId,
    reviewText,
    rating,
    tutor,
    createdAt,
    updatedAt,
  }) : _userId = userId,
       _reviewText = reviewText,
       _rating = rating,
       _tutor = tutor,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory Review({
    String? id,
    String? userId,
    String? reviewText,
    double? rating,
    Tutor? tutor,
  }) {
    return Review._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      userId: userId,
      reviewText: reviewText,
      rating: rating,
      tutor: tutor,
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
        _userId == other._userId &&
        _reviewText == other._reviewText &&
        _rating == other._rating &&
        _tutor == other._tutor;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("Review {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("userId=" + "$_userId" + ", ");
    buffer.write("reviewText=" + "$_reviewText" + ", ");
    buffer.write(
      "rating=" + (_rating != null ? _rating.toString() : "null") + ", ",
    );
    buffer.write(
      "tutor=" + (_tutor != null ? _tutor.toString() : "null") + ", ",
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

  Review copyWith({
    String? userId,
    String? reviewText,
    double? rating,
    Tutor? tutor,
  }) {
    return Review._internal(
      id: id,
      userId: userId ?? this.userId,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      tutor: tutor ?? this.tutor,
    );
  }

  Review copyWithModelFieldValues({
    ModelFieldValue<String?>? userId,
    ModelFieldValue<String?>? reviewText,
    ModelFieldValue<double?>? rating,
    ModelFieldValue<Tutor?>? tutor,
  }) {
    return Review._internal(
      id: id,
      userId: userId == null ? this.userId : userId.value,
      reviewText: reviewText == null ? this.reviewText : reviewText.value,
      rating: rating == null ? this.rating : rating.value,
      tutor: tutor == null ? this.tutor : tutor.value,
    );
  }

  Review.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _userId = json['userId'],
      _reviewText = json['reviewText'],
      _rating = (json['rating'] as num?)?.toDouble(),
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
    'reviewText': _reviewText,
    'rating': _rating,
    'tutor': _tutor?.toJson(),
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': _userId,
    'reviewText': _reviewText,
    'rating': _rating,
    'tutor': _tutor,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<ReviewModelIdentifier>
  MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ReviewModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USERID = amplify_core.QueryField(fieldName: "userId");
  static final REVIEWTEXT = amplify_core.QueryField(fieldName: "reviewText");
  static final RATING = amplify_core.QueryField(fieldName: "rating");
  static final TUTOR = amplify_core.QueryField(
    fieldName: "tutor",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'Tutor',
    ),
  );
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "Review";
      modelSchemaDefinition.pluralName = "Reviews";

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Review.USERID,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Review.REVIEWTEXT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: Review.RATING,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.double,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: Review.TUTOR,
          isRequired: false,
          targetNames: ['tutorReviewsId'],
          ofModelName: 'Tutor',
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
