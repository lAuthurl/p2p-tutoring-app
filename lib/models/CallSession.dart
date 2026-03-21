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

/** This is an auto generated class representing the CallSession type in your schema. */
class CallSession extends amplify_core.Model {
  static const classType = const _CallSessionModelType();
  final String id;
  final String? _sessionId;
  final String? _callerId;
  final String? _calleeId;
  final CallStatus? _status;
  final bool? _isVideo;
  final String? _agoraChannel;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated(
    '[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.',
  )
  @override
  String getId() => id;

  CallSessionModelIdentifier get modelIdentifier {
    return CallSessionModelIdentifier(id: id);
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

  String get callerId {
    try {
      return _callerId!;
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

  String get calleeId {
    try {
      return _calleeId!;
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

  CallStatus get status {
    try {
      return _status!;
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

  bool get isVideo {
    try {
      return _isVideo!;
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

  String get agoraChannel {
    try {
      return _agoraChannel!;
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

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const CallSession._internal({
    required this.id,
    required sessionId,
    required callerId,
    required calleeId,
    required status,
    required isVideo,
    required agoraChannel,
    createdAt,
    updatedAt,
  }) : _sessionId = sessionId,
       _callerId = callerId,
       _calleeId = calleeId,
       _status = status,
       _isVideo = isVideo,
       _agoraChannel = agoraChannel,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory CallSession({
    String? id,
    required String sessionId,
    required String callerId,
    required String calleeId,
    required CallStatus status,
    required bool isVideo,
    required String agoraChannel,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return CallSession._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      sessionId: sessionId,
      callerId: callerId,
      calleeId: calleeId,
      status: status,
      isVideo: isVideo,
      agoraChannel: agoraChannel,
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
    return other is CallSession &&
        id == other.id &&
        _sessionId == other._sessionId &&
        _callerId == other._callerId &&
        _calleeId == other._calleeId &&
        _status == other._status &&
        _isVideo == other._isVideo &&
        _agoraChannel == other._agoraChannel &&
        _createdAt == other._createdAt &&
        _updatedAt == other._updatedAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("CallSession {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("sessionId=" + "$_sessionId" + ", ");
    buffer.write("callerId=" + "$_callerId" + ", ");
    buffer.write("calleeId=" + "$_calleeId" + ", ");
    buffer.write(
      "status=" +
          (_status != null ? amplify_core.enumToString(_status)! : "null") +
          ", ",
    );
    buffer.write(
      "isVideo=" + (_isVideo != null ? _isVideo.toString() : "null") + ", ",
    );
    buffer.write("agoraChannel=" + "$_agoraChannel" + ", ");
    buffer.write(
      "createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ",
    );
    buffer.write(
      "updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"),
    );
    buffer.write("}");

    return buffer.toString();
  }

  CallSession copyWith({
    String? sessionId,
    String? callerId,
    String? calleeId,
    CallStatus? status,
    bool? isVideo,
    String? agoraChannel,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt,
  }) {
    return CallSession._internal(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      status: status ?? this.status,
      isVideo: isVideo ?? this.isVideo,
      agoraChannel: agoraChannel ?? this.agoraChannel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CallSession copyWithModelFieldValues({
    ModelFieldValue<String>? sessionId,
    ModelFieldValue<String>? callerId,
    ModelFieldValue<String>? calleeId,
    ModelFieldValue<CallStatus>? status,
    ModelFieldValue<bool>? isVideo,
    ModelFieldValue<String>? agoraChannel,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt,
  }) {
    return CallSession._internal(
      id: id,
      sessionId: sessionId == null ? this.sessionId : sessionId.value,
      callerId: callerId == null ? this.callerId : callerId.value,
      calleeId: calleeId == null ? this.calleeId : calleeId.value,
      status: status == null ? this.status : status.value,
      isVideo: isVideo == null ? this.isVideo : isVideo.value,
      agoraChannel:
          agoraChannel == null ? this.agoraChannel : agoraChannel.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value,
    );
  }

  CallSession.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _sessionId = json['sessionId'],
      _callerId = json['callerId'],
      _calleeId = json['calleeId'],
      _status = amplify_core.enumFromString<CallStatus>(
        json['status'],
        CallStatus.values,
      ),
      _isVideo = json['isVideo'],
      _agoraChannel = json['agoraChannel'],
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
    'sessionId': _sessionId,
    'callerId': _callerId,
    'calleeId': _calleeId,
    'status': amplify_core.enumToString(_status),
    'isVideo': _isVideo,
    'agoraChannel': _agoraChannel,
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'sessionId': _sessionId,
    'callerId': _callerId,
    'calleeId': _calleeId,
    'status': _status,
    'isVideo': _isVideo,
    'agoraChannel': _agoraChannel,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<CallSessionModelIdentifier>
  MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<CallSessionModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final SESSIONID = amplify_core.QueryField(fieldName: "sessionId");
  static final CALLERID = amplify_core.QueryField(fieldName: "callerId");
  static final CALLEEID = amplify_core.QueryField(fieldName: "calleeId");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final ISVIDEO = amplify_core.QueryField(fieldName: "isVideo");
  static final AGORACHANNEL = amplify_core.QueryField(
    fieldName: "agoraChannel",
  );
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(
    define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
      modelSchemaDefinition.name = "CallSession";
      modelSchemaDefinition.pluralName = "CallSessions";

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
          authStrategy: amplify_core.AuthStrategy.PRIVATE,
          operations: const [
            amplify_core.ModelOperation.READ,
            amplify_core.ModelOperation.UPDATE,
          ],
        ),
        amplify_core.AuthRule(
          authStrategy: amplify_core.AuthStrategy.PUBLIC,
          operations: const [
          
        ]),
      ];

      modelSchemaDefinition.indexes = [
        amplify_core.ModelIndex(fields: const ["sessionId"], name: "bySession"),
        amplify_core.ModelIndex(fields: const ["callerId"], name: "byCaller"),
        amplify_core.ModelIndex(fields: const ["calleeId"], name: "byCallee"),
      ];

      modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.SESSIONID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.CALLERID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.CALLEEID,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.STATUS,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.enumeration,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.ISVIDEO,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.bool,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.AGORACHANNEL,
          isRequired: true,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.string,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.CREATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );

      modelSchemaDefinition.addField(
        amplify_core.ModelFieldDefinition.field(
          key: CallSession.UPDATEDAT,
          isRequired: false,
          ofType: amplify_core.ModelFieldType(
            amplify_core.ModelFieldTypeEnum.dateTime,
          ),
        ),
      );
    },
  );
}

class _CallSessionModelType extends amplify_core.ModelType<CallSession> {
  const _CallSessionModelType();

  @override
  CallSession fromJson(Map<String, dynamic> jsonData) {
    return CallSession.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'CallSession';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [CallSession] in your schema.
 */
class CallSessionModelIdentifier
    implements amplify_core.ModelIdentifier<CallSession> {
  final String id;

  /** Create an instance of CallSessionModelIdentifier using [id] the primary key. */
  const CallSessionModelIdentifier({required this.id});

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
  String toString() => 'CallSessionModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CallSessionModelIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
