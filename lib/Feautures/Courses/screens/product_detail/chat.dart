// ignore_for_file: public_member_api_docs, avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
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
import '../../../../Feautures/Courses/controllers/tutoring_controller.dart';

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
    if (mounted) setState(() => _loading = false);
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

                // ✅ FIX: Subscribe to unreadCounts directly so the list
                // rebuilds whenever any count changes — not just when a new
                // message arrives and sessionMessages.refresh() happens.
                // ignore: unnecessary_statement
                controller.unreadCounts.entries;

                final chatIds =
                    sessionMap.keys
                        .where(
                          (chatId) =>
                              baseIds.any((id) => chatId.startsWith(id)),
                        )
                        .where((chatId) => sessionMap[chatId]!.isNotEmpty)
                        .toList();

                if (chatIds.isEmpty) {
                  return _EmptyInbox();
                }

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

                    // ✅ Read directly from unreadCounts RxMap — reactive,
                    // no manual refresh needed.
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
                            // Avatar
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

                            // Content
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

// ── Empty inbox state ─────────────────────────────────────────────────────────
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
    controller.observeChat(widget.sessionId);
    _textController.addListener(() => setState(() {}));

    // ✅ Defer markSessionRead to after the first frame.
    // Calling it directly in initState triggers Obx widgets (the inbox
    // badge, the inbox list) to setState() while the widget tree is still
    // being built — causing "setState called during build" errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.markSessionRead(widget.sessionId);
    });
  }

  @override
  void dispose() {
    // ✅ Clear the open chat so future messages count as unread again.
    controller.clearCurrentOpenSession();
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
            child: Obx(() {
              final messages =
                  controller.sessionMessages[widget.sessionId] ??
                  <ChatMessage>[];

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
                        color: colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Say hello 👋',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.25),
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
                  final isPlaying = _currentlyPlayingId == message.id;

                  final showDate =
                      index == 0 ||
                      _isDifferentDay(
                        messages[index - 1].createdAt?.getDateTimeInUtc(),
                        message.createdAt?.getDateTimeInUtc(),
                      );

                  return Column(
                    children: [
                      if (showDate)
                        _DateSeparator(
                          time: message.createdAt?.getDateTimeInUtc(),
                        ),
                      Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                            color: isMe ? TColors.primary : colorScheme.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            border:
                                isMe
                                    ? null
                                    : Border.all(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.1,
                                      ),
                                      width: 0.5,
                                    ),
                          ),
                          child:
                              (message.isVoice ?? false)
                                  ? _voiceBubble(message, isMe, isPlaying)
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
                    ],
                  );
                },
              );
            }),
          ),

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

  bool _isDifferentDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  Widget _voiceBubble(ChatMessage msg, bool isMe, bool isPlaying) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _playVoice(msg),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : TColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: isMe ? Colors.white : TColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _playbackProgress[msg.id] ?? 0,
                  minHeight: 3,
                  backgroundColor:
                      isMe
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMe ? Colors.white : TColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Voice message',
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isMe
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ],
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
