// ignore_for_file: public_member_api_docs, avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../models/ModelProvider.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../sessions/controllers/tutoring_controller.dart';

// ── InboxScreen ───────────────────────────────────────────────────────────────
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TutoringController controller = Get.find();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await controller.fetchTutorSessions();
    await controller.fetchAllStudentThreads();
    for (final session in controller.activeSessions) {
      controller.observeChat(session.id);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.setting_2,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body:
          _loading
              ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TColors.primary,
                ),
              )
              : Obx(() {
                final sessionMap = controller.sessionMessages;
                final baseSessions = controller.activeSessions;
                final baseIds = baseSessions.map((s) => s.id).toSet();
                controller.unreadCounts.entries; // reactive touch

                final chatIds =
                    sessionMap.keys
                        .where(
                          (chatId) =>
                              baseIds.any((id) => chatId.startsWith(id)),
                        )
                        .where((chatId) => sessionMap[chatId]!.isNotEmpty)
                        .toList();

                if (chatIds.isEmpty) return _EmptyInbox();

                chatIds.sort((a, b) {
                  final aTime =
                      sessionMap[a]?.last.createdAt?.getDateTimeInUtc();
                  final bTime =
                      sessionMap[b]?.last.createdAt?.getDateTimeInUtc();
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.defaultSpace,
                    vertical: 12,
                  ),
                  itemCount: chatIds.length,
                  itemBuilder: (context, index) {
                    final chatId = chatIds[index];
                    final messages = sessionMap[chatId] ?? [];
                    final lastMessage = messages.last;
                    final lastTime = lastMessage.createdAt?.getDateTimeInUtc();
                    final unreadCount = controller.unreadCounts[chatId] ?? 0;
                    final hasUnread = unreadCount > 0;
                    final lastText =
                        (lastMessage.isVoice == true)
                            ? '🎤 Voice message'
                            : (lastMessage.text ?? '');
                    final studentName = lastMessage.senderName ?? 'Student';
                    final baseSession = baseSessions.firstWhereOrNull(
                      (s) => chatId.startsWith(s.id),
                    );
                    final sessionTitle = baseSession?.title ?? chatId;
                    final initials =
                        studentName.isNotEmpty
                            ? studentName
                                .trim()
                                .split(' ')
                                .map((e) => e[0])
                                .take(2)
                                .join()
                                .toUpperCase()
                            : '?';

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.markSessionRead(chatId);
                        Get.to(
                          () => ChatScreen(
                            sessionId: chatId,
                            sessionTitle: sessionTitle,
                            otherUserName: studentName,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                hasUnread
                                    ? TColors.primary.withValues(alpha: 0.2)
                                    : colorScheme.outline.withValues(
                                      alpha: 0.1,
                                    ),
                            width: hasUnread ? 1 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: TColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: TColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sessionTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                hasUnread
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                            color: colorScheme.onSurface,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      if (lastTime != null)
                                        Text(
                                          _formatTime(lastTime),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                hasUnread
                                                    ? TColors.primary
                                                    : colorScheme.onSurface
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                            fontWeight:
                                                hasUnread
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$studentName · $lastText',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                hasUnread
                                                    ? colorScheme.onSurface
                                                        .withValues(alpha: 0.7)
                                                    : colorScheme.onSurface
                                                        .withValues(alpha: 0.4),
                                            fontWeight:
                                                hasUnread
                                                    ? FontWeight.w500
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (hasUnread)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: TColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}

// ── Empty inbox ───────────────────────────────────────────────────────────────
class _EmptyInbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: TColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(Iconsax.message, size: 30, color: TColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Student messages will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VOICE BUBBLE
// ═════════════════════════════════════════════════════════════════════════════

// ── Waveform painter ──────────────────────────────────────────────────────────
//
// IDLE:    bars at 50% height, single flat dim colour, NO playhead, NO animation.
// PLAYING: bars at full height with ripple pulse near playhead, two-tone
//          played/unplayed split, visible playhead line.
//
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.barHeights,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
    required this.idleColor,
    required this.playheadColor,
    required this.animValue,
    required this.isPlaying,
  });

  final List<double> barHeights;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;
  final Color idleColor;
  final Color playheadColor;
  final double animValue;
  final bool isPlaying;

  static const double _barW = 3.0;
  static const double _gap = 2.5;
  static const double _idleScale = 0.50;

  @override
  void paint(Canvas canvas, Size size) {
    final playheadX = size.width * progress.clamp(0.0, 1.0);

    for (int i = 0; i < barHeights.length; i++) {
      final x = i * (_barW + _gap);
      double h = barHeights[i] * size.height;
      Color color;

      if (isPlaying) {
        final dist = (x / size.width - progress).abs();
        if (dist < 0.16) {
          h *= 1.0 + 0.32 * (1.0 - dist / 0.16) * sin(animValue * 2 * pi);
        }
        color = x < playheadX ? playedColor : unplayedColor;
      } else {
        h *= _idleScale;
        color = idleColor;
      }

      h = h.clamp(3.0, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, _barW, h),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }

    if (isPlaying && progress > 0.01 && progress < 0.99) {
      canvas.drawLine(
        Offset(playheadX, 2),
        Offset(playheadX, size.height - 2),
        Paint()
          ..color = playheadColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.animValue != animValue ||
      old.isPlaying != isPlaying;
}

// ── VoiceBubble ───────────────────────────────────────────────────────────────
//
// FIX: No longer uses a local AnimationController.
// Instead it receives `animValue` (0.0–1.0) ticked by the parent _ChatScreenState
// via a single app-level Ticker. This means:
//   • No controller lifecycle / key destruction issues.
//   • `isPlaying` flip is always reflected immediately on next tick.
//   • Only one Ticker runs for the whole screen regardless of message count.
//
class VoiceBubble extends StatelessWidget {
  const VoiceBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isPlaying,
    required this.progress,
    required this.animValue,
    required this.onTap,
    this.realDurationSecs, // null until first onProgress event
  });

  final ChatMessage message;
  final bool isMe;
  final bool isPlaying;
  final double progress;
  final double animValue;
  final VoidCallback onTap;
  final double? realDurationSecs;

  static const int _barCount = 28;

  static List<double> _barsFor(String id) {
    final rng = Random(id.hashCode);
    return List.generate(_barCount, (i) {
      final t = i / (_barCount - 1);
      final env = 1.0 - (2 * t - 1).abs() * 0.55;
      return 0.20 + rng.nextDouble() * 0.62 * env;
    });
  }

  String _timeLabel(double prog) {
    // Use real duration once available, fall back to placeholder until first play
    final total = realDurationSecs ?? 0.0;
    String fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    if (total <= 0) {
      // Duration not yet known — show blank or dashes until played once
      return isPlaying ? '...' : '--:--';
    }
    return isPlaying
        ? '${fmt((total * prog).floor())} / ${fmt(total.floor())}'
        : fmt(total.floor());
  }

  @override
  Widget build(BuildContext context) {
    final bars = _barsFor(message.id);

    final playedColor = isMe ? Colors.white : TColors.primary;
    final unplayedColor =
        isMe
            ? Colors.white.withValues(alpha: 0.28)
            : TColors.primary.withValues(alpha: 0.22);
    final idleColor =
        isMe
            ? Colors.white.withValues(alpha: 0.32)
            : TColors.primary.withValues(alpha: 0.25);
    final playheadColor =
        isMe
            ? Colors.white.withValues(alpha: 0.92)
            : TColors.primary.withValues(alpha: 0.82);
    final labelColor =
        isMe
            ? Colors.white.withValues(alpha: isPlaying ? 0.80 : 0.48)
            : Colors.black.withValues(alpha: isPlaying ? 0.50 : 0.28);
    final iconColor = isMe ? Colors.white : TColors.primary;
    final iconBg =
        isMe
            ? Colors.white.withValues(alpha: isPlaying ? 0.30 : 0.14)
            : TColors.primary.withValues(alpha: isPlaying ? 0.20 : 0.09);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 210,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Play / Pause button
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 21,
                color: iconColor,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Waveform — rebuilt every tick from parent setState
                  SizedBox(
                    height: 34,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        barHeights: bars,
                        progress: progress,
                        playedColor: playedColor,
                        unplayedColor: unplayedColor,
                        idleColor: idleColor,
                        playheadColor: playheadColor,
                        animValue: animValue,
                        isPlaying: isPlaying,
                      ),
                      size: const Size(double.infinity, 34),
                    ),
                  ),

                  const SizedBox(height: 5),

                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    child: Text(_timeLabel(progress)),
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

// ── ChatScreen ────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TutoringController controller = Get.find();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _audioReady = false;
  StreamSubscription? _playerSubscription;

  bool _isRecording = false;
  bool _loadingMessages = true;
  String? _currentUserId;
  String? _currentlyPlayingId;
  final Map<String, double> _playbackProgress = {};
  // Real duration in seconds per message id — populated from onProgress events
  final Map<String, double> _audioDurations = {};
  // Local file cache: message id → downloaded temp path (avoids re-downloading)
  final Map<String, String> _localAudioCache = {};

  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  Worker? _messagesWorker;

  // ── Single AnimationController drives ALL waveform animations ──────────────
  // Replaces the raw Ticker — AnimationController is available directly from
  // SingleTickerProviderStateMixin which is already on this State class.
  late final AnimationController _waveformCtrl;
  double _waveAnimValue = 0.0;

  @override
  void initState() {
    super.initState();

    // AnimationController cycles 0→1 every 1600 ms.
    // The listener only calls setState while something is playing,
    // so the screen doesn't rebuild unnecessarily when idle.
    _waveformCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _waveformCtrl.addListener(() {
      if (_currentlyPlayingId != null && mounted) {
        setState(() {
          _waveAnimValue = _waveformCtrl.value;
        });
      }
    });

    _initAudio();
    _fetchCurrentUser();
    _fetchMessagesFromAppSync();
    controller.observeChat(widget.sessionId);
    _textController.addListener(() => setState(() {}));

    _messagesWorker = ever(controller.sessionMessages, (_) {
      final updated = controller.sessionMessages[widget.sessionId];
      if (updated != null && mounted) {
        final seen = <String>{};
        final deduped =
            updated.where((m) => seen.add(m.id)).toList()..sort(
              (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now())
                  .compareTo(b.createdAt?.getDateTimeInUtc() ?? DateTime.now()),
            );
        _messages.assignAll(deduped);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.markSessionRead(widget.sessionId);
    });
  }

  @override
  void dispose() {
    controller.clearCurrentOpenSession();
    _waveformCtrl.dispose();
    _messagesWorker?.dispose();
    _playerSubscription?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() => _currentUserId = user.userId);
    } catch (_) {
      if (mounted) {
        setState(() => _currentUserId = null);
      }
    }
  }

  Future<void> _fetchMessagesFromAppSync() async {
    if (mounted) {
      setState(() => _loadingMessages = true);
    }
    try {
      const queryDoc = r"""
        query ListMessagesBySession($sessionId: String!, $limit: Int) {
          listChatMessagesBySession(sessionId: $sessionId, limit: $limit) {
            items {
              id sessionId senderId senderName text audioUrl isVoice createdAt _version _deleted
            }
          }
        }
      """;

      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: queryDoc,
                  variables: {'sessionId': widget.sessionId, 'limit': 500},
                ),
              )
              .response;

      if (response.errors.isNotEmpty || response.data == null) {
        _loadFromDataStore();
        return;
      }

      final parsed = _parseMessages(response.data!);
      parsed.sort(
        (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          b.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );
      _messages.assignAll(parsed);
      // Prefetch durations in background so labels show before first play
      _prefetchVoiceDurations(parsed);
    } catch (e) {
      print('❌ ChatScreen._fetchMessagesFromAppSync: $e');
      _loadFromDataStore();
    } finally {
      if (mounted) {
        setState(() => _loadingMessages = false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _loadFromDataStore() {
    final ds = controller.sessionMessages[widget.sessionId] ?? [];
    _messages.assignAll(ds);
  }

  List<ChatMessage> _parseMessages(String responseData) {
    final result = <ChatMessage>[];
    try {
      final decoded = jsonDecode(responseData) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final items =
          (root['listChatMessagesBySession'] as Map<String, dynamic>?)?['items']
              as List<dynamic>? ??
          [];
      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        if (item['_deleted'] == true) continue;
        final id = item['id'] as String?;
        if (id == null) continue;
        final createdAtStr = item['createdAt'] as String?;
        result.add(
          ChatMessage(
            id: id,
            sessionId: item['sessionId'] as String? ?? widget.sessionId,
            senderId: item['senderId'] as String? ?? '',
            senderName: item['senderName'] as String?,
            text: item['text'] as String?,
            audioUrl: item['audioUrl'] as String?,
            isVoice: item['isVoice'] as bool? ?? false,
            createdAt:
                createdAtStr != null
                    ? TemporalDateTime.fromString(createdAtStr)
                    : null,
          ),
        );
      }
    } catch (e) {
      print('❌ ChatScreen._parseMessages: $e');
    }
    return result;
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    _messages.removeWhere((m) => m.id == message.id);
    try {
      const getDoc =
          r"""query GetChatMessage($id: ID!) { getChatMessage(id: $id) { id _version _deleted } }""";
      final getResponse =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': message.id},
                ),
              )
              .response;

      int version = 1;
      if (getResponse.errors.isEmpty && getResponse.data != null) {
        final decoded = jsonDecode(getResponse.data!) as Map<String, dynamic>;
        final obj =
            ((decoded['data'] as Map<String, dynamic>?) ??
                    decoded)['getChatMessage']
                as Map<String, dynamic>?;
        if (obj == null || obj['_deleted'] == true) {
          return;
        }
        final v = obj['_version'];
        if (v != null) version = (v as num).toInt();
      }

      const mutationDoc =
          r"""mutation DeleteChatMessage($input: DeleteChatMessageInput!) { deleteChatMessage(input: $input) { id _version } }""";
      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {'id': message.id, '_version': version},
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        final isConflict = response.errors.any(
          (e) =>
              e.extensions?['errorType']?.toString().contains('Conflict') ==
              true,
        );
        if (isConflict) {
          await _fetchMessagesFromAppSync();
          final fresh = _messages.firstWhereOrNull((m) => m.id == message.id);
          if (fresh != null) await _deleteMessage(fresh);
          return;
        }
        _messages.add(message);
        _messages.sort(
          (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now())
              .compareTo(b.createdAt?.getDateTimeInUtc() ?? DateTime.now()),
        );
      } else {
        final chatMessages = controller.sessionMessages[widget.sessionId] ?? [];
        controller.sessionMessages[widget.sessionId] =
            chatMessages.where((m) => m.id != message.id).toList();
        controller.sessionMessages.refresh();
      }
    } catch (e) {
      print('❌ ChatScreen._deleteMessage: $e');
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        _messages.sort(
          (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now())
              .compareTo(b.createdAt?.getDateTimeInUtc() ?? DateTime.now()),
        );
      }
    }
  }

  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete message?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'This message will be permanently deleted.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteMessage(message);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _initAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    await _recorder!.openRecorder();
    await _player!.openPlayer();
    // Fire onProgress events every 100 ms so the waveform and duration
    // label update smoothly and duration is available almost immediately
    await _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
    await _player!.setVolume(1.0);

    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );
    } catch (e) {
      print('⚠️ _initAudio: audio session config error: $e');
    }

    if (mounted) {
      setState(() => _audioReady = true);
    }
    print('✅ ChatScreen: audio ready');
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _currentUserId == null) {
      return;
    }
    _textController.clear();
    await controller.sendMessage(widget.sessionId, text);
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
      setState(() {
        _isRecording = true;
      });
    } else {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      if (path != null && _currentUserId != null) {
        await controller.sendVoiceMessage(widget.sessionId, File(path));
      } else {
        print('⚠️ _toggleRecording: path or userId null, skipping voice send');
      }
    }
  }

  // Silently downloads all voice messages and reads their duration so the
  // label shows the correct length before the user taps play.
  // Runs concurrently with a cap of 3 simultaneous downloads to avoid
  // saturating the network on long chat histories.
  Future<void> _prefetchVoiceDurations(List<ChatMessage> messages) async {
    final voiceMessages =
        messages
            .where(
              (m) =>
                  m.isVoice == true &&
                  m.audioUrl != null &&
                  !_audioDurations.containsKey(m.id),
            )
            .toList();

    if (voiceMessages.isEmpty) return;

    // Process in batches of 3
    for (int i = 0; i < voiceMessages.length; i += 3) {
      final batch = voiceMessages.skip(i).take(3).toList();
      await Future.wait(batch.map((m) => _fetchDurationFor(m)));
    }
  }

  // Downloads the file (or uses cache) and reads duration by opening a silent
  // probe player, waiting for the first onProgress event, then stopping.
  // This avoids FlutterSoundHelper.duration() which requires FFmpeg (LITE flavor).
  Future<void> _fetchDurationFor(ChatMessage message) async {
    try {
      final localPath = await _fetchAndCacheAudio(message);
      if (localPath == null) return;

      final probe = FlutterSoundPlayer();
      await probe.openPlayer();
      await probe.setSubscriptionDuration(const Duration(milliseconds: 50));

      final completer = Completer<double>();
      StreamSubscription? sub;

      await probe.startPlayer(
        fromURI: localPath,
        codec: Codec.aacADTS,
        whenFinished: () {
          if (!completer.isCompleted) completer.complete(0.0);
        },
      );

      sub = probe.onProgress!.listen((event) {
        final ms = event.duration.inMilliseconds;
        if (ms > 0 && !completer.isCompleted) {
          completer.complete(ms / 1000.0);
        }
      });

      final secs = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => 0.0,
      );

      sub.cancel();
      await probe.stopPlayer();
      await probe.closePlayer();

      if (secs > 0 && mounted) {
        setState(() {
          _audioDurations[message.id] = secs;
        });
        print(
          '✅ prefetch duration for ${message.id}: ${secs.toStringAsFixed(1)}s',
        );
      }
    } catch (e) {
      print('⚠️ _fetchDurationFor ${message.id}: $e');
    }
  }

  // Extracts the S3 storage key from a full pre-signed URL.
  // e.g. "https://bucket.s3.region.amazonaws.com/chat/sessionId/file.aac?X-Amz-..."
  // → "chat/sessionId/file.aac"
  String? _s3KeyFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Path starts with '/' — strip leading slash
      final rawPath =
          uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      if (rawPath.isEmpty) return null;
      return rawPath;
    } catch (_) {
      return null;
    }
  }

  // Gets a fresh pre-signed URL from Amplify Storage for the given S3 key,
  // then downloads the file to a local temp path.
  // On second play the cached file is returned instantly (no re-download).
  Future<String?> _fetchAndCacheAudio(ChatMessage message) async {
    // Already cached locally — return immediately
    if (_localAudioCache.containsKey(message.id)) {
      return _localAudioCache[message.id];
    }

    final storedUrl = message.audioUrl;
    if (storedUrl == null) return null;

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/voice_${message.id}.aac';
      final file = File(filePath);

      // If the file already exists on disk (e.g. app restart) skip download
      if (await file.exists()) {
        _localAudioCache[message.id] = filePath;
        print('✅ _fetchAndCacheAudio: using cached file for ${message.id}');
        return filePath;
      }

      // Re-fetch a fresh pre-signed URL — the stored URL may have expired (403)
      final s3Key = _s3KeyFromUrl(storedUrl);
      if (s3Key == null) {
        print('❌ _fetchAndCacheAudio: could not parse S3 key from $storedUrl');
        return null;
      }

      print('🔄 _fetchAndCacheAudio: refreshing URL for key $s3Key');
      final urlResult =
          await Amplify.Storage.getUrl(
            path: StoragePath.fromString(s3Key),
          ).result;
      final freshUrl = urlResult.url.toString();

      // Download using Dart HttpClient
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(freshUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        await response.pipe(file.openWrite());
        _localAudioCache[message.id] = filePath;
        print('✅ _fetchAndCacheAudio: downloaded ${message.id} to $filePath');
        return filePath;
      } else {
        print(
          '❌ _fetchAndCacheAudio: HTTP ${response.statusCode} for ${message.id}',
        );
        return null;
      }
    } catch (e) {
      print('❌ _fetchAndCacheAudio error: $e');
      return null;
    }
  }

  Future<void> _playVoice(ChatMessage message) async {
    if (!_audioReady || message.audioUrl == null) {
      return;
    }

    // Tap the currently playing message → stop it
    if (_currentlyPlayingId == message.id) {
      await _player!.stopPlayer();
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
      return;
    }

    // Stop whatever was playing
    if (_player!.isPlaying) {
      await _player!.stopPlayer();
    }

    // Cancel previous subscription before starting new player session
    _playerSubscription?.cancel();
    _playerSubscription = null;

    // Refresh the S3 URL and download to a local file.
    // Pre-signed S3 URLs expire — re-fetching avoids 403 errors on older messages.
    final localPath = await _fetchAndCacheAudio(message);
    if (localPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load voice message. Try again.'),
          ),
        );
      }
      return;
    }

    // Set playing state BEFORE startPlayer so the waveform animates immediately
    if (mounted) {
      setState(() {
        _currentlyPlayingId = message.id;
      });
    }

    await _player!.startPlayer(
      fromURI: localPath,
      codec: Codec.aacADTS,
      whenFinished: () {
        if (mounted) {
          setState(() {
            _currentlyPlayingId = null;
            _playbackProgress[message.id] = 0.0;
          });
        }
      },
    );

    // Drive playhead progress and capture real duration.
    // setSubscriptionDuration(100ms) in _initAudio ensures this fires within
    // 100ms of playback starting, so '--:--' is visible for at most one tick.
    _playerSubscription = _player!.onProgress!.listen((event) {
      final durationMs = event.duration.inMilliseconds;
      final positionMs = event.position.inMilliseconds;
      if (mounted && durationMs > 0) {
        setState(() {
          _playbackProgress[message.id] = positionMs / durationMs;
          _audioDurations[message.id] = durationMs / 1000.0;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isDifferentDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTextEmpty = _textController.text.trim().isEmpty;
    final initials =
        widget.otherUserName.isNotEmpty
            ? widget.otherUserName
                .trim()
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: TColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    widget.sessionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.refresh,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: _fetchMessagesFromAppSync,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(
              Iconsax.call,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Iconsax.more,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _loadingMessages
                    ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TColors.primary,
                      ),
                    )
                    : Obx(() {
                      final messages = _messages;
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(),
                      );

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.message_add,
                                size: 40,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Say hello 👋',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.25,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length,
                        itemBuilder: (_, index) {
                          final message = messages[index];
                          final isMe = message.senderId == _currentUserId;
                          // FIX: isPlaying derived from _currentlyPlayingId which is
                          // set BEFORE startPlayer, so bubble shows active immediately
                          final isPlaying = _currentlyPlayingId == message.id;

                          final showDate =
                              index == 0 ||
                              _isDifferentDay(
                                messages[index - 1].createdAt
                                    ?.getDateTimeInUtc(),
                                message.createdAt?.getDateTimeInUtc(),
                              );

                          return Column(
                            children: [
                              if (showDate)
                                _DateSeparator(
                                  time: message.createdAt?.getDateTimeInUtc(),
                                ),
                              GestureDetector(
                                onLongPress:
                                    isMe
                                        ? () => _showDeleteDialog(message)
                                        : null,
                                child: Align(
                                  alignment:
                                      isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: 6,
                                      left: isMe ? 48 : 0,
                                      right: isMe ? 0 : 48,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isMe
                                              ? TColors.primary
                                              : colorScheme.surface,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(
                                          isMe ? 16 : 4,
                                        ),
                                        bottomRight: Radius.circular(
                                          isMe ? 4 : 16,
                                        ),
                                      ),
                                      border:
                                          isMe
                                              ? null
                                              : Border.all(
                                                color: colorScheme.outline
                                                    .withValues(alpha: 0.1),
                                                width: 0.5,
                                              ),
                                    ),
                                    child:
                                        (message.isVoice ?? false)
                                            // FIX: pass _waveAnimValue from the parent ticker
                                            // so animation is driven externally — no per-bubble
                                            // AnimationController needed
                                            ? VoiceBubble(
                                              message: message,
                                              isMe: isMe,
                                              isPlaying: isPlaying,
                                              progress:
                                                  _playbackProgress[message
                                                      .id] ??
                                                  0.0,
                                              animValue:
                                                  isPlaying
                                                      ? _waveAnimValue
                                                      : 0.0,
                                              onTap: () => _playVoice(message),
                                              realDurationSecs:
                                                  _audioDurations[message.id],
                                            )
                                            : Text(
                                              message.text ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    isMe
                                                        ? Colors.white
                                                        : colorScheme.onSurface,
                                                height: 1.4,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }),
          ),

          // Recording indicator
          if (_isRecording)
            Container(
              color: Colors.red.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recording — tap stop when done',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.35,
                            ),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isTextEmpty) {
                        _toggleRecording();
                      } else {
                        _sendTextMessage();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : TColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTextEmpty
                            ? (_isRecording ? Iconsax.stop : Iconsax.microphone)
                            : Iconsax.send_1,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime? time;
  const _DateSeparator({this.time});

  @override
  Widget build(BuildContext context) {
    if (time == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    String label;
    if (now.day == time!.day &&
        now.month == time!.month &&
        now.year == time!.year) {
      label = 'Today';
    } else if (now.subtract(const Duration(days: 1)).day == time!.day) {
      label = 'Yesterday';
    } else {
      label = '${time!.day}/${time!.month}/${time!.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colorScheme.outline.withValues(alpha: 0.1),
              thickness: 0.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colorScheme.outline.withValues(alpha: 0.1),
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
