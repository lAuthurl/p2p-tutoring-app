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


/** This is an auto generated class representing the TutoringSession type in your schema. */
class TutoringSession extends amplify_core.Model {
  static const classType = const _TutoringSessionModelType();
  final String id;
  final Tutor? _tutor;
  final Subject? _subject;
  final List<SessionAttribute>? _sessionAttributes;
  final List<Booking>? _bookings;
  final List<Review>? _reviews;
  final String? _title;
  final String? _description;
  final String? _thumbnail;
  final List<String>? _images;
  final double? _pricePerSession;
  final bool? _isFeatured;
  final bool? _hasPaid;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  TutoringSessionModelIdentifier get modelIdentifier {
      return TutoringSessionModelIdentifier(
        id: id
      );
  }
  
  Tutor? get tutor {
    return _tutor;
  }
  
  Subject? get subject {
    return _subject;
  }
  
  List<SessionAttribute>? get sessionAttributes {
    return _sessionAttributes;
  }
  
  List<Booking>? get bookings {
    return _bookings;
  }
  
  List<Review>? get reviews {
    return _reviews;
  }
  
  String get title {
    try {
      return _title!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get description {
    return _description;
  }
  
  String? get thumbnail {
    return _thumbnail;
  }
  
  List<String>? get images {
    return _images;
  }
  
  double? get pricePerSession {
    return _pricePerSession;
  }
  
  bool? get isFeatured {
    return _isFeatured;
  }
  
  bool? get hasPaid {
    return _hasPaid;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const TutoringSession._internal({required this.id, tutor, subject, sessionAttributes, bookings, reviews, required title, description, thumbnail, images, pricePerSession, isFeatured, hasPaid, createdAt, updatedAt}): _tutor = tutor, _subject = subject, _sessionAttributes = sessionAttributes, _bookings = bookings, _reviews = reviews, _title = title, _description = description, _thumbnail = thumbnail, _images = images, _pricePerSession = pricePerSession, _isFeatured = isFeatured, _hasPaid = hasPaid, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory TutoringSession({String? id, Tutor? tutor, Subject? subject, List<SessionAttribute>? sessionAttributes, List<Booking>? bookings, List<Review>? reviews, required String title, String? description, String? thumbnail, List<String>? images, double? pricePerSession, bool? isFeatured, bool? hasPaid, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return TutoringSession._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      tutor: tutor,
      subject: subject,
      sessionAttributes: sessionAttributes != null ? List<SessionAttribute>.unmodifiable(sessionAttributes) : sessionAttributes,
      bookings: bookings != null ? List<Booking>.unmodifiable(bookings) : bookings,
      reviews: reviews != null ? List<Review>.unmodifiable(reviews) : reviews,
      title: title,
      description: description,
      thumbnail: thumbnail,
      images: images != null ? List<String>.unmodifiable(images) : images,
      pricePerSession: pricePerSession,
      isFeatured: isFeatured,
      hasPaid: hasPaid,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TutoringSession &&
      id == other.id &&
      _tutor == other._tutor &&
      _subject == other._subject &&
      DeepCollectionEquality().equals(_sessionAttributes, other._sessionAttributes) &&
      DeepCollectionEquality().equals(_bookings, other._bookings) &&
      DeepCollectionEquality().equals(_reviews, other._reviews) &&
      _title == other._title &&
      _description == other._description &&
      _thumbnail == other._thumbnail &&
      DeepCollectionEquality().equals(_images, other._images) &&
      _pricePerSession == other._pricePerSession &&
      _isFeatured == other._isFeatured &&
      _hasPaid == other._hasPaid &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("TutoringSession {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("tutor=" + (_tutor != null ? _tutor!.toString() : "null") + ", ");
    buffer.write("subject=" + (_subject != null ? _subject!.toString() : "null") + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("thumbnail=" + "$_thumbnail" + ", ");
    buffer.write("images=" + (_images != null ? _images!.toString() : "null") + ", ");
    buffer.write("pricePerSession=" + (_pricePerSession != null ? _pricePerSession!.toString() : "null") + ", ");
    buffer.write("isFeatured=" + (_isFeatured != null ? _isFeatured!.toString() : "null") + ", ");
    buffer.write("hasPaid=" + (_hasPaid != null ? _hasPaid!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  TutoringSession copyWith({Tutor? tutor, Subject? subject, List<SessionAttribute>? sessionAttributes, List<Booking>? bookings, List<Review>? reviews, String? title, String? description, String? thumbnail, List<String>? images, double? pricePerSession, bool? isFeatured, bool? hasPaid, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return TutoringSession._internal(
      id: id,
      tutor: tutor ?? this.tutor,
      subject: subject ?? this.subject,
      sessionAttributes: sessionAttributes ?? this.sessionAttributes,
      bookings: bookings ?? this.bookings,
      reviews: reviews ?? this.reviews,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      pricePerSession: pricePerSession ?? this.pricePerSession,
      isFeatured: isFeatured ?? this.isFeatured,
      hasPaid: hasPaid ?? this.hasPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  TutoringSession copyWithModelFieldValues({
    ModelFieldValue<Tutor?>? tutor,
    ModelFieldValue<Subject?>? subject,
    ModelFieldValue<List<SessionAttribute>?>? sessionAttributes,
    ModelFieldValue<List<Booking>?>? bookings,
    ModelFieldValue<List<Review>?>? reviews,
    ModelFieldValue<String>? title,
    ModelFieldValue<String?>? description,
    ModelFieldValue<String?>? thumbnail,
    ModelFieldValue<List<String>?>? images,
    ModelFieldValue<double?>? pricePerSession,
    ModelFieldValue<bool?>? isFeatured,
    ModelFieldValue<bool?>? hasPaid,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return TutoringSession._internal(
      id: id,
      tutor: tutor == null ? this.tutor : tutor.value,
      subject: subject == null ? this.subject : subject.value,
      sessionAttributes: sessionAttributes == null ? this.sessionAttributes : sessionAttributes.value,
      bookings: bookings == null ? this.bookings : bookings.value,
      reviews: reviews == null ? this.reviews : reviews.value,
      title: title == null ? this.title : title.value,
      description: description == null ? this.description : description.value,
      thumbnail: thumbnail == null ? this.thumbnail : thumbnail.value,
      images: images == null ? this.images : images.value,
      pricePerSession: pricePerSession == null ? this.pricePerSession : pricePerSession.value,
      isFeatured: isFeatured == null ? this.isFeatured : isFeatured.value,
      hasPaid: hasPaid == null ? this.hasPaid : hasPaid.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  TutoringSession.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _tutor = json['tutor'] != null
        ? json['tutor']['serializedData'] != null
          ? Tutor.fromJson(new Map<String, dynamic>.from(json['tutor']['serializedData']))
          : Tutor.fromJson(new Map<String, dynamic>.from(json['tutor']))
        : null,
      _subject = json['subject'] != null
        ? json['subject']['serializedData'] != null
          ? Subject.fromJson(new Map<String, dynamic>.from(json['subject']['serializedData']))
          : Subject.fromJson(new Map<String, dynamic>.from(json['subject']))
        : null,
      _sessionAttributes = json['sessionAttributes']  is Map
        ? (json['sessionAttributes']['items'] is List
          ? (json['sessionAttributes']['items'] as List)
              .where((e) => e != null)
              .map((e) => SessionAttribute.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['sessionAttributes'] is List
          ? (json['sessionAttributes'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => SessionAttribute.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _bookings = json['bookings']  is Map
        ? (json['bookings']['items'] is List
          ? (json['bookings']['items'] as List)
              .where((e) => e != null)
              .map((e) => Booking.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['bookings'] is List
          ? (json['bookings'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Booking.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _reviews = json['reviews']  is Map
        ? (json['reviews']['items'] is List
          ? (json['reviews']['items'] as List)
              .where((e) => e != null)
              .map((e) => Review.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['reviews'] is List
          ? (json['reviews'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Review.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _title = json['title'],
      _description = json['description'],
      _thumbnail = json['thumbnail'],
      _images = json['images']?.cast<String>(),
      _pricePerSession = (json['pricePerSession'] as num?)?.toDouble(),
      _isFeatured = json['isFeatured'],
      _hasPaid = json['hasPaid'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'tutor': _tutor?.toJson(), 'subject': _subject?.toJson(), 'sessionAttributes': _sessionAttributes?.map((SessionAttribute? e) => e?.toJson()).toList(), 'bookings': _bookings?.map((Booking? e) => e?.toJson()).toList(), 'reviews': _reviews?.map((Review? e) => e?.toJson()).toList(), 'title': _title, 'description': _description, 'thumbnail': _thumbnail, 'images': _images, 'pricePerSession': _pricePerSession, 'isFeatured': _isFeatured, 'hasPaid': _hasPaid, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'tutor': _tutor,
    'subject': _subject,
    'sessionAttributes': _sessionAttributes,
    'bookings': _bookings,
    'reviews': _reviews,
    'title': _title,
    'description': _description,
    'thumbnail': _thumbnail,
    'images': _images,
    'pricePerSession': _pricePerSession,
    'isFeatured': _isFeatured,
    'hasPaid': _hasPaid,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<TutoringSessionModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<TutoringSessionModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TUTOR = amplify_core.QueryField(
    fieldName: "tutor",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Tutor'));
  static final SUBJECT = amplify_core.QueryField(
    fieldName: "subject",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Subject'));
  static final SESSIONATTRIBUTES = amplify_core.QueryField(
    fieldName: "sessionAttributes",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'SessionAttribute'));
  static final BOOKINGS = amplify_core.QueryField(
    fieldName: "bookings",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Booking'));
  static final REVIEWS = amplify_core.QueryField(
    fieldName: "reviews",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Review'));
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final THUMBNAIL = amplify_core.QueryField(fieldName: "thumbnail");
  static final IMAGES = amplify_core.QueryField(fieldName: "images");
  static final PRICEPERSESSION = amplify_core.QueryField(fieldName: "pricePerSession");
  static final ISFEATURED = amplify_core.QueryField(fieldName: "isFeatured");
  static final HASPAID = amplify_core.QueryField(fieldName: "hasPaid");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "TutoringSession";
    modelSchemaDefinition.pluralName = "TutoringSessions";
    
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
          amplify_core.ModelOperation.DELETE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["tutorId"], name: "byTutor"),
      amplify_core.ModelIndex(fields: const ["subjectId"], name: "bySubject")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: TutoringSession.TUTOR,
      isRequired: false,
      targetNames: ['tutorId'],
      ofModelName: 'Tutor'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: TutoringSession.SUBJECT,
      isRequired: false,
      targetNames: ['subjectId'],
      ofModelName: 'Subject'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: TutoringSession.SESSIONATTRIBUTES,
      isRequired: false,
      ofModelName: 'SessionAttribute',
      associatedKey: SessionAttribute.SESSION
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: TutoringSession.BOOKINGS,
      isRequired: false,
      ofModelName: 'Booking',
      associatedKey: Booking.SESSIONID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: TutoringSession.REVIEWS,
      isRequired: false,
      ofModelName: 'Review',
      associatedKey: Review.SESSIONID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.DESCRIPTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.THUMBNAIL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.IMAGES,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.PRICEPERSESSION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.ISFEATURED,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.HASPAID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TutoringSession.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _TutoringSessionModelType extends amplify_core.ModelType<TutoringSession> {
  const _TutoringSessionModelType();
  
  @override
  TutoringSession fromJson(Map<String, dynamic> jsonData) {
    return TutoringSession.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'TutoringSession';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [TutoringSession] in your schema.
 */
class TutoringSessionModelIdentifier implements amplify_core.ModelIdentifier<TutoringSession> {
  final String id;

  /** Create an instance of TutoringSessionModelIdentifier using [id] the primary key. */
  const TutoringSessionModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'TutoringSessionModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is TutoringSessionModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}