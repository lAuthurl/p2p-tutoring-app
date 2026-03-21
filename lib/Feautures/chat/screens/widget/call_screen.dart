import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../models/ModelProvider.dart';
import '../../controllers/call.dart';

class CallScreen extends StatefulWidget {
  final TCallSession callSession;
  const CallScreen({super.key, required this.callSession});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _fetchCalleeName();
  }

  Future<void> _fetchCalleeName() async {
    try {
      final currentUserId = await _getCurrentUserId();

      final targetId =
          currentUserId == widget.callSession.callerId
              ? widget.callSession.calleeId
              : widget.callSession.callerId;

      debugPrint('[CallScreen] looking up name for targetId: $targetId');

      // 1️⃣ Try User table
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(targetId),
      );
      if (users.isNotEmpty && mounted) {
        debugPrint('[CallScreen] found User: ${users.first.username}');
        setState(() => _displayName = users.first.username);
        return;
      }

      // 2️⃣ Try Tutor table
      final tutors = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(targetId),
      );
      if (tutors.isNotEmpty && mounted) {
        debugPrint('[CallScreen] found Tutor: ${tutors.first.name}');
        setState(() => _displayName = tutors.first.name);
        return;
      }

      debugPrint('[CallScreen] no User or Tutor found for $targetId');

      // 3️⃣ GraphQL fallback — User
      const userQuery = '''
        query GetUser(\$id: ID!) {
          getUser(id: \$id) {
            id username
          }
        }
      ''';

      final userRes =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: userQuery,
                  variables: {'id': targetId},
                ),
              )
              .response;

      if (userRes.errors.isEmpty && userRes.data != null) {
        final decoded = jsonDecode(userRes.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final user = root['getUser'] as Map<String, dynamic>?;
        final name = user?['username'] as String?;
        if (name != null && name.isNotEmpty && mounted) {
          debugPrint('[CallScreen] found User via GraphQL: $name');
          setState(() => _displayName = name);
          return;
        }
      }

      // 4️⃣ GraphQL fallback — Tutor
      const tutorQuery = '''
        query GetTutor(\$id: ID!) {
          getTutor(id: \$id) {
            id name
          }
        }
      ''';

      final tutorRes =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: tutorQuery,
                  variables: {'id': targetId},
                ),
              )
              .response;

      if (tutorRes.errors.isEmpty && tutorRes.data != null) {
        final decoded = jsonDecode(tutorRes.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final tutor = root['getTutor'] as Map<String, dynamic>?;
        final name = tutor?['name'] as String?;
        if (name != null && name.isNotEmpty && mounted) {
          debugPrint('[CallScreen] found Tutor via GraphQL: $name');
          setState(() => _displayName = name);
          return;
        }
      }

      // 5️⃣ Last resort: truncated ID
      if (mounted) {
        setState(() => _displayName = targetId.substring(0, 8));
      }
    } catch (e) {
      debugPrint('[CallScreen] _fetchCalleeName error: $e');
      if (mounted) setState(() => _displayName = '...');
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = CallController.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(
        () => Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: remote video / local video / voice placeholder ───
            if (ctrl.isVideo.value && ctrl.remoteUid.value != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: ctrl.engine,
                  canvas: VideoCanvas(uid: ctrl.remoteUid.value!),
                  connection: RtcConnection(
                    channelId: widget.callSession.agoraChannel,
                  ),
                ),
              )
            else if (ctrl.isVideo.value)
              AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: ctrl.engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            else
              _VoicePlaceholder(
                displayName: _displayName,
                callSession: widget.callSession,
              ),

            // ── Local PiP — only when remote is also in video ────────────────
            if (ctrl.isVideo.value && ctrl.remoteUid.value != null)
              Positioned(
                right: 16,
                bottom: 120,
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: ctrl.engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Top bar ───────────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _displayName.isNotEmpty ? _displayName : '...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          ctrl.isInCall.value ? 'Connected' : 'Connecting...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Controls row ──────────────────────────────────────────────────
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Obx(
                    () => _CallButton(
                      icon:
                          ctrl.isMuted.value
                              ? Iconsax.microphone_slash
                              : Iconsax.microphone,
                      label: ctrl.isMuted.value ? 'Unmute' : 'Mute',
                      onTap: ctrl.toggleMute,
                    ),
                  ),
                  Obx(
                    () =>
                        !ctrl.isVideo.value
                            ? _CallButton(
                              icon: Iconsax.video,
                              label: 'Camera',
                              onTap: ctrl.upgradeToVideo,
                            )
                            : _CallButton(
                              icon: Icons.flip_camera_ios_rounded,
                              label: 'Flip',
                              onTap: ctrl.switchCamera,
                            ),
                  ),
                  _CallButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    color: Colors.red,
                    onTap: ctrl.endCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice placeholder ─────────────────────────────────────────────────────────

class _VoicePlaceholder extends StatelessWidget {
  final TCallSession callSession;
  final String displayName;

  const _VoicePlaceholder({
    required this.callSession,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      color: const Color(0xFF1C1C2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white12,
              child: Text(
                initial,
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName.isNotEmpty ? displayName : '...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const _WaveformIndicator(),
          ],
        ),
      ),
    );
  }
}

// ── Animated waveform ─────────────────────────────────────────────────────────

class _WaveformIndicator extends StatefulWidget {
  const _WaveformIndicator();

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, _) {
            final delay = i * 0.2;
            final t = ((_anim.value + delay) % 1.0);
            final height = 8.0 + 16.0 * (0.5 - (t - 0.5).abs()) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Call control button ───────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  color == Colors.red
                      ? Colors.red
                      : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
