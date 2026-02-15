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

/** This is an auto generated class representing the SessionVariation type in your schema. */
class SessionVariation extends amplify_core.Model {
  static const classType = const _SessionVariationModelType();
  final String id;
  final String? _tutorId;
  final int? _availableSeats;
  final double? _pricePerSession;
  final amplify_core.TemporalDateTime? _lectureTime;
  final String? _image;
  final String? _metadata;
  final List<SessionAttribute>? _sessionAttributes;
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

  SessionVariationModelIdentifier get modelIdentifier {
    return SessionVariationModelIdentifier(id: id);
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

  int? get availableSeats {
    return _availableSeats;
  }

  double? get pricePerSession {
    return _pricePerSession;
  }

  amplify_core.TemporalDateTime? get lectureTime {
    return _lectureTime;
  }

  String? get image {
    return _image;
  }

  String? get metadata {
    return _metadata;
  }

  List<SessionAttribute>? get sessionAttributes {
    return _sessionAttributes;
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

  const SessionVariation._internal({
    required this.id,
    required tutorId,
    availableSeats,
    pricePerSession,
    lectureTime,
    image,
    metadata,
    sessionAttributes,
    session,
    createdAt,
    updatedAt,
  }) : _tutorId = tutorId,
       _availableSeats = availableSeats,
       _pricePerSession = pricePerSession,
       _lectureTime = lectureTime,
       _image = image,
       _metadata = metadata,
       _sessionAttributes = sessionAttributes,
       _session = session,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory SessionVariation({
    String? id,
    required String tutorId,
    int? availableSeats,
    double? pricePerSession,
    amplify_core.TemporalDateTime? lectureTime,
    String? image,
    String? metadata,
    List<SessionAttribute>? sessionAttributes,
    TutoringSession? session,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return SessionVariation._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      tutorId: tutorId,
      availableSeats: availableSeats,
      pricePerSession: pricePerSession,
      lectureTime: lectureTime,
      image: image,
      metadata: metadata,
      sessionAttributes:
          sessionAttributes != null
              ? List<SessionAttribute>.unmodifiable(sessionAttributes)
              : sessionAttributes,
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
    return other is SessionVariation &&
        id == other.id &&
        _tutorId == other._tutorId &&
        _availableSeats == other._availableSeats &&
        _pricePerSession == other._pricePerSession &&
        _lectureTime == other._lectureTime &&
        _image == other._image &&
        _metadata == other._metadata &&
        DeepCollectionEquality().equals(
          _sessionAttributes,
          other._sessionAttributes,
        ) &&
        _session == other._session &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("SessionVariation {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("tutorId=" + "$_tutorId" + ", ");
    buffer.write(
      "availableSeats=" +
          (_availableSeats != null ? _availableSeats.toString() : "null") +
          ", ",
    );
    buffer.write(
      "pricePerSession=" +
          (_pricePerSession != null ? _pricePerSession.toString() : "null") +
          ", ",
    );
    buffer.write(
      "lectureTime=" +
          (_lectureTime != null ? _lectureTime.format() : "null") +
          ", ",
    );
    buffer.write("image=" + "$_image" + ", ");
    buffer.write("metadata=" + "$_metadata" + ", ");
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

  SessionVariation copyWith({
    String? tutorId,
    int? availableSeats,
    double? pricePerSession,
    amplify_core.TemporalDateTime? lectureTime,
    String? image,
    String? metadata,
    List<SessionAttribute>? sessionAttributes,
    TutoringSession? session,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return SessionVariation._internal(
      id: id,
      tutorId: tutorId ?? this.tutorId,
      availableSeats: availableSeats ?? this.availableSeats,
      pricePerSession: pricePerSession ?? this.pricePerSession,
      lectureTime: lectureTime ?? this.lectureTime,
      image: image ?? this.image,
      metadata: metadata ?? this.metadata,
      sessionAttributes: sessionAttributes ?? this.sessionAttributes,
      session: session ?? this.session,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  SessionVariation copyWithModelFieldValues({
    ModelFieldValue<String>? tutorId,
    ModelFieldValue<int?>? availableSeats,
    ModelFieldValue<double?>? pricePerSession,
    ModelFieldValue<amplify_core.TemporalDateTime?>? lectureTime,
    ModelFieldValue<String?>? image,
    ModelFieldValue<String?>? metadata,
    ModelFieldValue<List<SessionAttribute>?>? sessionAttributes,
    ModelFieldValue<TutoringSession?>? session,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt,
  }) {
    return SessionVariation._internal(
      id: id,
      tutorId: tutorId == null ? this.tutorId : tutorId.value,
      availableSeats:
          availableSeats == null ? this.availableSeats : availableSeats.value,
      pricePerSession:
          pricePerSession == null
              ? this.pricePerSession
              : pricePerSession.value,
      lectureTime: lectureTime == null ? this.lectureTime : lectureTime.value,
      image: image == null ? this.image : image.value,
      metadata: metadata == null ? this.metadata : metadata.value,
      sessionAttributes:
          sessionAttributes == null
              ? this.sessionAttributes
              : sessionAttributes.value,
      session: session == null ? this.session : session.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value,
    );
  }

  SessionVariation.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _tutorId = json['tutorId'],
      _availableSeats = (json['availableSeats'] as num?)?.toInt(),
      _pricePerSession = (json['pricePerSession'] as num?)?.toDouble(),
      _lectureTime =
          json['lectureTime'] != null
              ? amplify_core.TemporalDateTime.fromString(json['lectureTime'])
              : null,
      _image = json['image'],
      _metadata = json['metadata'],
      _sessionAttributes =
          json['sessionAttributes'] is Map
              ? (json['sessionAttributes']['items'] is List
                  ? (json['sessionAttributes']['items'] as List)
                      .where((e) => e != null)
                      .map(
                        (e) => SessionAttribute.fromJson(
                          new Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList()
                  : null)
              : (json['sessionAttributes'] is List
                  ? (json['sessionAttributes'] as List)
                      .where((e) => e?['serializedData'] != null)
                      .map(
                        (e) => SessionAttribute.fromJson(
                          new Map<String, dynamic>.from(e?['serializedData']),
                        ),
                      )
                      .toList()
                  : null),
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
    'availableSeats': _availableSeats,
    'pricePerSession': _pricePerSession,
    'lectureTime': _lectureTime?.format(),
    'image': _image,
    'metadata': _metadata,
    'sessionAttributes':
        _sessionAttributes?.map((SessionAttribute? e) => e?.toJson()).toList(),
    'session': _session?.toJson(),
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'tutorId': _tutorId,
    'availableSeats': _availableSeats,
    'pricePerSession': _pricePerSession,
    'lectureTime': _lectureTime,
    'image': _image,
    'metadata': _metadata,
    'sessionAttributes': _sessionAttributes,
    'session': _session,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<
    SessionVariationModelIdentifier
  >
  MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<SessionVariationModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TUTORID = amplify_core.QueryField(fieldName: "tutorId");
  static final AVAILABLESEATS = amplify_core.QueryField(
    fieldName: "availableSeats",
  );
  static final PRICEPERSESSION = amplify_core.QueryField(
    fieldName: "pricePerSession",
  );
  static final LECTURETIME = amplify_core.QueryField(fieldName: "lectureTime");
  static final IMAGE = amplify_core.QueryField(fieldName: "image");
  static final METADATA = amplify_core.QueryField(fieldName: "metadata");
  static final SESSIONATTRIBUTES = amplify_core.QueryField(
    fieldName: "sessionAttributes",
    fieldType: amplify_core.ModelFieldType(
      amplify_core.ModelFieldTypeEnum.model,
      ofModelName: 'SessionAttribute',
    ),
  );
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
      modelSchemaDefinition.name = "SessionVariation";
      modelSchemaDefinition.pluralName = "SessionVariations";

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
          key: SessionVariation.TUTORID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionVariation.AVAILABLESEATS,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.int,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionVariation.PRICEPERSESSION,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.double,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionVariation.LECTURETIME,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionVariation.IMAGE,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionVariation.METADATA,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.hasMany(
          key: SessionVariation.SESSIONATTRIBUTES,
          isRequired: false,
          ofModelName: 'SessionAttribute',
          associatedKey: SessionAttribute.ID,
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.belongsTo(
          key: SessionVariation.SESSION,
          isRequired: false,
          targetNames: ['sessionId'],
          ofModelName: 'TutoringSession',
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionVariation.CREATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: SessionVariation.UPDATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );
    },
  );
}

class _SessionVariationModelType
    extends amplify_core.ModelType<SessionVariation> {
  const _SessionVariationModelType();

  @override
  SessionVariation fromJson(Map<String, dynamic> jsonData) {
    return SessionVariation.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'SessionVariation';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [SessionVariation] in your schema.
 */
class SessionVariationModelIdentifier
    implements amplify_core.ModelIdentifier<SessionVariation> {
  final String id;

  /** Create an instance of SessionVariationModelIdentifier using [id] the primary key. */
  const SessionVariationModelIdentifier({required this.id});

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
  String toString() => 'SessionVariationModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SessionVariationModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
