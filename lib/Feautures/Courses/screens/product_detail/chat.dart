// ignore_for_file: public_member_api_docs, avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../models/ModelProvider.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../Feautures/Courses/controllers/tutoring_controller.dart';

// ─────────────────────────────────────────────
// ARCHITECTURE NOTES
//
// One-to-many model:
//   • A TutoringSession IS the conversation.
//   • Students send messages into a session by sessionId.
//   • The tutor's InboxScreen lists all sessions that have
//     at least one message, showing the session title and
//     the last sender's name — no client-side grouping hacks.
//   • TutoringController exposes:
//       - activeSessions      : RxList<TutoringSession>
//       - sessionMessages     : RxMap<String, List<ChatMessage>>
//       - observeChat(id)     : subscribe to AppSync for a session
//       - sendMessage(id, text)
//       - sendVoiceMessage(id, file)
//       - markSessionRead(id)
//       - authUserId          : Future<String?>
//
//  ChatMessage model fields expected:
//       id, sessionId, senderId, senderName,
//       text, isVoice, audioUrl, createdAt
//
//  TutoringSession model fields used:
//       id, title, tutor (nested Tutor object)
//  Student name is sourced from ChatMessage.senderName
// ─────────────────────────────────────────────

/// ==========================
/// Inbox Screen  (Tutor view)
/// ==========================
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

  /// Fetches the tutor's sessions, then queries all ChatMessages whose
  /// sessionId starts with each session's base id (format: sessionId_userId).
  /// This discovers every unique student thread and subscribes to each one.
  Future<void> _load() async {
    await controller.fetchTutorSessions();
    await controller.fetchAllStudentThreads();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Obx(() {
                // sessionMessages keys are scoped chatIds: "baseSessionId_userId"
                // Each student gets their own private thread with the tutor.
                final sessionMap = controller.sessionMessages;
                final baseSessions = controller.activeSessions;
                final baseIds = baseSessions.map((s) => s.id).toSet();

                // Collect all chatIds that belong to this tutor's sessions.
                final chatIds =
                    sessionMap.keys
                        .where(
                          (chatId) =>
                              baseIds.any((id) => chatId.startsWith(id)),
                        )
                        .where((chatId) => sessionMap[chatId]!.isNotEmpty)
                        .toList();

                if (chatIds.isEmpty) {
                  return const Center(child: Text("No conversations yet"));
                }

                // Sort by most recent message first.
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

                return ListView.separated(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  itemCount: chatIds.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: TSizes.spaceBtwItems),
                  itemBuilder: (context, index) {
                    final chatId = chatIds[index];
                    final messages = sessionMap[chatId] ?? [];
                    final lastMessage = messages.last;
                    final lastTime = lastMessage.createdAt?.getDateTimeInUtc();
                    final unreadCount = controller.unreadCount(chatId);
                    final lastText =
                        (lastMessage.isVoice == true)
                            ? "🎤 Voice message"
                            : (lastMessage.text ?? '');
                    final studentName = lastMessage.senderName ?? 'Student';

                    // Match back to the base session for the title.
                    final baseSession = baseSessions.firstWhereOrNull(
                      (s) => chatId.startsWith(s.id),
                    );
                    final sessionTitle = baseSession?.title ?? chatId;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: TColors.primary,
                        child: Text(
                          studentName.isNotEmpty
                              ? studentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: TColors.textDarkPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      title: Text(
                        sessionTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "$studentName · $lastText",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (lastTime != null)
                            Text(
                              _formatTime(lastTime),
                              style: const TextStyle(fontSize: 12),
                            ),
                          const SizedBox(height: 5),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        controller.markSessionRead(chatId);
                        Get.to(
                          () => ChatScreen(
                            sessionId: chatId,
                            sessionTitle: sessionTitle,
                            otherUserName: studentName,
                          ),
                        );
                      },
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
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.day}/${time.month}";
  }
}

/// ==========================
/// Chat Screen
/// ==========================
///
/// Used by BOTH student and tutor.
///   - Student opens it from their session/booking screen.
///   - Tutor opens it from InboxScreen above.
///
/// Required: sessionId — the single source of truth for
/// which AppSync subscription / DynamoDB partition to use.
class ChatScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final String
  otherUserName; // Tutor name (for student) or Student name (for tutor)

  const ChatScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TutoringController controller = Get.find();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription? _playerSubscription;

  bool _isRecording = false;
  String? _currentUserId;
  String? _currentlyPlayingId;
  final Map<String, double> _playbackProgress = {};

  @override
  void initState() {
    super.initState();
    _initAudio();
    _fetchCurrentUser();
    // Subscribe to real-time updates for this session only.
    controller.observeChat(widget.sessionId);
    _textController.addListener(() => setState(() {}));
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (!mounted) return;
      setState(() => _currentUserId = user.userId);
    } catch (_) {
      if (mounted) setState(() => _currentUserId = null);
    }
  }

  Future<void> _initAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;
    await controller.sendMessage(widget.sessionId, text);
    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
      setState(() => _isRecording = true);
    } else {
      final path = await _recorder!.stopRecorder();
      setState(() => _isRecording = false);

      if (path != null && _currentUserId != null) {
        await controller.sendVoiceMessage(widget.sessionId, File(path));
      }
    }
  }

  Future<void> _playVoice(ChatMessage message) async {
    if (message.audioUrl == null) return;

    if (_currentlyPlayingId == message.id) {
      await _player!.stopPlayer();
      setState(() => _currentlyPlayingId = null);
      return;
    }

    await _player!.startPlayer(
      fromURI: message.audioUrl,
      whenFinished: () {
        if (mounted) setState(() => _currentlyPlayingId = null);
      },
    );

    _playerSubscription?.cancel();
    _playerSubscription = _player!.onProgress!.listen((event) {
      final duration = event.duration.inMilliseconds;
      final position = event.position.inMilliseconds;
      if (mounted) {
        setState(() {
          _currentlyPlayingId = message.id;
          _playbackProgress[message.id] =
              duration == 0 ? 0.0 : position / duration;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTextEmpty = _textController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: TColors.primary,
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: TColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
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
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.sessionTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message list ──────────────────────────────
          Expanded(
            child: Obx(() {
              final messages =
                  controller.sessionMessages[widget.sessionId] ??
                  <ChatMessage>[];

              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );

              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    "No messages yet.\nSay hello! 👋",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                itemCount: messages.length,
                itemBuilder: (_, index) {
                  final message = messages[index];
                  final isMe = message.senderId == _currentUserId;
                  final isPlaying = _currentlyPlayingId == message.id;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(TSizes.sm),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? TColors.primary : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child:
                          (message.isVoice ?? false)
                              ? _voiceBubble(message, isMe, isPlaying)
                              : Text(
                                message.text ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                    ),
                  );
                },
              );
            }),
          ),

          // ── Input bar ─────────────────────────────────
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
              vertical: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: TColors.dashboardAppbarBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isTextEmpty ? _toggleRecording : _sendTextMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    minimumSize: Size.zero,
                  ),
                  child: Icon(
                    isTextEmpty
                        ? (_isRecording ? Icons.stop : Icons.mic)
                        : Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // ── Recording indicator ───────────────────────
          if (_isRecording)
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Recording... tap stop when done",
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _voiceBubble(ChatMessage msg, bool isMe, bool isPlaying) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _playVoice(msg),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isMe ? Colors.white24 : Colors.black12,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 18,
              color: isMe ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: _playbackProgress[msg.id] ?? 0,
            minHeight: 4,
            backgroundColor: isMe ? Colors.white24 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(
              isMe ? Colors.white : TColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// REQUIRED CONTROLLER ADDITIONS  (add to TutoringController)
// ─────────────────────────────────────────────────────────────────
//
// 1. Expose activeSessions so InboxScreen can list them:
//
//    final RxList<TutoringSession> activeSessions = <TutoringSession>[].obs;
//
//    // Call this in your controller's onInit / after fetching sessions:
//    Future<void> fetchTutorSessions() async {
//      final userId = await authUserId;
//      // Query your TutoringSession model filtered by tutorId == userId
//      // Populate activeSessions and call observeChat for each session
//      // so the inbox message map is pre-warmed.
//    }
//
// 2. Add unreadCount helper:
//
//    final Map<String, int> _unreadCounts = {};
//
//    int unreadCount(String sessionId) => _unreadCounts[sessionId] ?? 0;
//
//    @override
//    void markSessionRead(String sessionId) {
//      _unreadCounts[sessionId] = 0;
//      // Optionally persist to backend / local storage
//    }
//
//    // Increment in your subscription listener when a new message
//    // arrives and the session is not currently open:
//    void _onNewMessage(ChatMessage msg) {
//      sessionMessages[msg.sessionId] ??= [];
//      sessionMessages[msg.sessionId]!.add(msg);
//      if (_currentOpenSessionId != msg.sessionId) {
//        _unreadCounts[msg.sessionId] =
//            (_unreadCounts[msg.sessionId] ?? 0) + 1;
//      }
//    }
//
// 3. Student entry point — no inbox needed for students:
//
//    // From student's booking/session detail screen:
//    Get.to(() => ChatScreen(
//      sessionId: session.id,
//      sessionTitle: session.title ?? 'Your session',
//      otherUserName: session.tutorName ?? 'Tutor',
//    ));
//
// ─────────────────────────────────────────────────────────────────
