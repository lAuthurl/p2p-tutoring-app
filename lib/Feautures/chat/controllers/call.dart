import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../../services/agora_token_service.dart';
import '../screens/widget/call_screen.dart';
import '../screens/widget/incoming_call_screen.dart';

enum TCallStatus { ringing, active, ended }

class TCallSession {
  final String id;
  final String sessionId;
  final String callerId;
  final String calleeId;
  final TCallStatus status;
  final bool isVideo;
  final String agoraChannel;

  const TCallSession({
    required this.id,
    required this.sessionId,
    required this.callerId,
    required this.calleeId,
    required this.status,
    required this.isVideo,
    required this.agoraChannel,
  });

  TCallSession copyWith({TCallStatus? status, bool? isVideo}) => TCallSession(
    id: id,
    sessionId: sessionId,
    callerId: callerId,
    calleeId: calleeId,
    status: status ?? this.status,
    isVideo: isVideo ?? this.isVideo,
    agoraChannel: agoraChannel,
  );

  static TCallSession? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return TCallSession(
      id: m['id'] as String? ?? '',
      sessionId: m['sessionId'] as String? ?? '',
      callerId: m['callerId'] as String? ?? '',
      calleeId: m['calleeId'] as String? ?? '',
      status: _statusFromString(m['status'] as String?),
      isVideo: m['isVideo'] as bool? ?? false,
      agoraChannel: m['agoraChannel'] as String? ?? '',
    );
  }

  static TCallStatus _statusFromString(String? s) {
    switch (s) {
      case 'ACTIVE':
        return TCallStatus.active;
      case 'ENDED':
        return TCallStatus.ended;
      default:
        return TCallStatus.ringing;
    }
  }

  static String _statusToString(TCallStatus s) {
    switch (s) {
      case TCallStatus.active:
        return 'ACTIVE';
      case TCallStatus.ended:
        return 'ENDED';
      case TCallStatus.ringing:
        return 'RINGING';
    }
  }

  String get statusString => _statusToString(status);
}

class CallController extends GetxController {
  static CallController get instance => Get.find();

  late RtcEngine _engine;
  RtcEngine get engine => _engine;

  final isInCall = false.obs;
  final isVideo = false.obs;
  final isMuted = false.obs;
  final remoteUid = Rx<int?>(null);
  final callStatus = Rx<TCallStatus?>(null);
  final activeCallSession = Rx<TCallSession?>(null);

  final _agoraAppId = '316cd2759ac04460a25445d08b2dcc28';

  StreamSubscription? _incomingCallSub;
  StreamSubscription? _callAcceptedSub;

  @override
  void onInit() {
    super.onInit();
    _initAgora();
    _listenForIncomingCalls();
  }

  @override
  void onClose() {
    _incomingCallSub?.cancel();
    _callAcceptedSub?.cancel();
    _engine.release();
    super.onClose();
  }

  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: _agoraAppId));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            isInCall.value = true;
          },
          onUserJoined: (connection, uid, elapsed) {
            remoteUid.value = uid;
          },
          onUserOffline: (connection, uid, reason) {
            remoteUid.value = null;
            endCall();
          },
        ),
      );
      debugPrint('[CallController] Agora initialized');
    } catch (e) {
      debugPrint('[CallController] _initAgora error: $e');
    }
  }

  Future<void> _listenForIncomingCalls() async {
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) return;

    try {
      const subDoc = '''
        subscription OnCreateCallSession {
          onCreateCallSession {
            id sessionId callerId calleeId
            status isVideo agoraChannel createdAt
          }
        }
      ''';

      _incomingCallSub = Amplify.API
          .subscribe(
            GraphQLRequest<String>(document: subDoc),
            onEstablished:
                () => debugPrint('[CallController] incoming-call sub ready'),
          )
          .listen((event) {
            if (event.data == null) return;
            try {
              final decoded = jsonDecode(event.data!) as Map<String, dynamic>;
              final root =
                  (decoded['data'] as Map<String, dynamic>?) ?? decoded;
              final raw = root['onCreateCallSession'] as Map<String, dynamic>?;
              final session = TCallSession.fromJson(raw);
              if (session == null) return;

              if (session.calleeId != currentUserId) return;
              if (session.status == TCallStatus.ringing) {
                _onIncomingCall(session);
              }
            } catch (e) {
              debugPrint('[CallController] sub parse error: $e');
            }
          }, onError: (e) => debugPrint('[CallController] sub error: $e'));
    } catch (e) {
      debugPrint('[CallController] _listenForIncomingCalls error: $e');
    }
  }

  void _listenForCallAccepted(String callSessionId) {
    const subDoc = '''
      subscription OnUpdateCallSession {
        onUpdateCallSession {
          id status agoraChannel isVideo
        }
      }
    ''';

    _callAcceptedSub?.cancel();
    _callAcceptedSub = Amplify.API
        .subscribe(
          GraphQLRequest<String>(document: subDoc),
          onEstablished:
              () => debugPrint('[CallController] call-accepted sub ready'),
        )
        .listen(
          (event) async {
            if (event.data == null) return;
            try {
              final decoded = jsonDecode(event.data!) as Map<String, dynamic>;
              final root =
                  (decoded['data'] as Map<String, dynamic>?) ?? decoded;
              final raw = root['onUpdateCallSession'] as Map<String, dynamic>?;
              if (raw == null) return;

              // Filter in Dart — only react to OUR call session
              final id = raw['id'] as String?;
              if (id != callSessionId) return;

              final status = TCallSession._statusFromString(
                raw['status'] as String?,
              );

              if (status == TCallStatus.active) {
                final channel = raw['agoraChannel'] as String;
                final video = raw['isVideo'] as bool? ?? false;
                final token = await _fetchAgoraToken(channel);
                await _joinChannel(channel, token, video);
              } else if (status == TCallStatus.ended) {
                _callAcceptedSub?.cancel();
                endCall();
              }
            } catch (e) {
              debugPrint('[CallController] call-accepted parse error: $e');
            }
          },
          onError:
              (e) => debugPrint('[CallController] call-accepted sub error: $e'),
        );
  }

  void _onIncomingCall(TCallSession callSession) {
    activeCallSession.value = callSession;
    callStatus.value = TCallStatus.ringing;

    Get.to(
      () => IncomingCallScreen(callSession: callSession),
      fullscreenDialog: true,
    );
  }

  Future<void> startCall({
    required String sessionId,
    required String calleeId,
    required bool withVideo,
  }) async {
    await Permission.microphone.request();
    if (withVideo) await Permission.camera.request();

    isVideo.value = withVideo;
    callStatus.value = TCallStatus.ringing;

    final callerId = await _getCurrentUserId();
    if (callerId == null) {
      debugPrint('[CallController] startCall: no current user');
      return;
    }

    final callSession = await _createCallSession(
      callerId: callerId,
      sessionId: sessionId,
      calleeId: calleeId,
      isVideo: withVideo,
    );
    if (callSession == null) {
      Get.snackbar(
        'Call Failed',
        'Could not initiate call. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    activeCallSession.value = callSession;
    _startRingTimeout();
    _listenForCallAccepted(callSession.id);

    Get.to(() => CallScreen(callSession: callSession));
  }

  Future<void> acceptCall(TCallSession callSession) async {
    await Permission.microphone.request();
    if (callSession.isVideo) await Permission.camera.request();

    isVideo.value = callSession.isVideo;
    callStatus.value = TCallStatus.active;
    activeCallSession.value = callSession;

    await _updateCallStatus(callSession.id, TCallStatus.active);

    final token = await _fetchAgoraToken(callSession.agoraChannel);
    await _joinChannel(callSession.agoraChannel, token, callSession.isVideo);

    Get.off(() => CallScreen(callSession: callSession));
  }

  Future<void> rejectCall(TCallSession callSession) async {
    await _updateCallStatus(callSession.id, TCallStatus.ended);
    callStatus.value = TCallStatus.ended;
    activeCallSession.value = null;
    Get.back();
  }

  Future<void> endCall() async {
    _callAcceptedSub?.cancel();
    _callAcceptedSub = null;

    final session = activeCallSession.value;
    if (session != null) {
      await _updateCallStatus(session.id, TCallStatus.ended);
    }

    try {
      await _engine.leaveChannel();
    } catch (e) {
      debugPrint('[CallController] leaveChannel error: $e');
    }

    isInCall.value = false;
    remoteUid.value = null;
    isVideo.value = false;
    callStatus.value = TCallStatus.ended;
    activeCallSession.value = null;

    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    } else {
      try {
        Get.back();
      } catch (_) {}
    }
  }

  Future<void> upgradeToVideo() async {
    await Permission.camera.request();
    await _engine.enableLocalVideo(true);
    await _engine.enableVideo();
    isVideo.value = true;
    await _pushVideoUpgradeSignal();
  }

  Future<void> switchCamera() async {
    try {
      await _engine.switchCamera();
    } catch (e) {
      debugPrint('[CallController] switchCamera error: $e');
    }
  }

  Future<void> toggleMute() async {
    isMuted.toggle();
    await _engine.muteLocalAudioStream(isMuted.value);
  }

  void _startRingTimeout() {
    Future.delayed(const Duration(seconds: 30), () {
      if (callStatus.value == TCallStatus.ringing) {
        debugPrint('[CallController] Ring timeout — ending call');
        endCall();
      }
    });
  }

  Future<TCallSession?> _createCallSession({
    required String callerId,
    required String sessionId,
    required String calleeId,
    required bool isVideo,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      const mutDoc = '''
        mutation CreateCallSession(\$input: CreateCallSessionInput!) {
          createCallSession(input: \$input) {
            id sessionId callerId calleeId
            status isVideo agoraChannel createdAt
          }
        }
      ''';

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutDoc,
                  variables: {
                    'input': {
                      'id': id,
                      'sessionId': sessionId,
                      'callerId': callerId,
                      'calleeId': calleeId,
                      'status': 'RINGING',
                      'isVideo': isVideo,
                      'agoraChannel': id.split('-').first,
                      'createdAt': now,
                    },
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        debugPrint(
          '[CallController] createCallSession errors: ${response.errors}',
        );
        return null;
      }

      if (response.data == null) return null;

      final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final raw = root['createCallSession'] as Map<String, dynamic>?;
      return TCallSession.fromJson(raw);
    } catch (e) {
      debugPrint('[CallController] _createCallSession error: $e');
      return null;
    }
  }

  Future<void> _updateCallStatus(
    String callSessionId,
    TCallStatus status,
  ) async {
    try {
      const getDoc = '''
        query GetCallSession(\$id: ID!) {
          getCallSession(id: \$id) {
            id status _version _deleted
          }
        }
      ''';

      final getRes =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': callSessionId},
                ),
              )
              .response;

      int version = 1;
      if (getRes.errors.isEmpty && getRes.data != null) {
        final decoded = jsonDecode(getRes.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final obj = root['getCallSession'] as Map<String, dynamic>?;
        if (obj == null || obj['_deleted'] == true) return;
        final v = obj['_version'];
        if (v != null) version = (v as num).toInt();
      }

      const mutDoc = '''
        mutation UpdateCallSession(\$input: UpdateCallSessionInput!) {
          updateCallSession(input: \$input) {
            id status _version
          }
        }
      ''';

      final mutRes =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutDoc,
                  variables: {
                    'input': {
                      'id': callSessionId,
                      'status': TCallSession._statusToString(status),
                      '_version': version,
                    },
                  },
                ),
              )
              .response;

      if (mutRes.errors.isNotEmpty) {
        debugPrint(
          '[CallController] _updateCallStatus errors: ${mutRes.errors}',
        );
      }
    } catch (e) {
      debugPrint('[CallController] _updateCallStatus error: $e');
    }
  }

  Future<void> _pushVideoUpgradeSignal() async {
    final session = activeCallSession.value;
    if (session == null) return;
    try {
      const mutDoc = '''
        mutation UpdateCallSession(\$input: UpdateCallSessionInput!) {
          updateCallSession(input: \$input) {
            id isVideo _version
          }
        }
      ''';
      await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: mutDoc,
              variables: {
                'input': {'id': session.id, 'isVideo': true},
              },
            ),
          )
          .response;
    } catch (e) {
      debugPrint('[CallController] _pushVideoUpgradeSignal error: $e');
    }
  }

  Future<String> _fetchAgoraToken(String channelId) async {
    return AgoraTokenService.fetchToken(channelName: channelId);
  }

  Future<void> _joinChannel(
    String channelId,
    String token,
    bool withVideo,
  ) async {
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    if (withVideo) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (_) {
      return null;
    }
  }
}
