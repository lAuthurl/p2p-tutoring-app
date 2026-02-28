// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../models/ModelProvider.dart';
import '../../controllers/tutoring_controller.dart';

class ChatScreen extends StatefulWidget {
  final Tutor tutor;
  final String sessionId;

  const ChatScreen({super.key, required this.tutor, required this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TutoringController controller = Get.find<TutoringController>();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  StreamSubscription? _playerSub;

  bool _isRecording = false;
  String? _currentlyPlayingId;
  double _playbackProgress = 0.0;
  String? _currentUserId;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _initAudio();
    _fetchCurrentUser();
    controller.observeChat(widget.sessionId);

    _textController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (!mounted) return;
      setState(() => _currentUserId = user.userId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentUserId = null);
    }
  }

  Future<void> _initAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    await _recorder?.openRecorder();
    await _player?.openPlayer();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _playerSub?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // TEXT MESSAGE
  // =========================================================

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    await controller.sendMessage(widget.sessionId, text);

    _textController.clear();
    _scrollToBottom();
  }

  // =========================================================
  // VOICE RECORDING
  // =========================================================

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) return;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder?.startRecorder(toFile: path, codec: Codec.aacADTS);

      setState(() => _isRecording = true);
    } else {
      final path = await _recorder?.stopRecorder();
      setState(() => _isRecording = false);

      if (path != null && _currentUserId != null) {
        await controller.sendVoiceMessage(widget.sessionId, File(path));
      }
    }
  }

  // =========================================================
  // VOICE PLAYBACK
  // =========================================================

  Future<void> _playVoice(ChatMessage msg) async {
    if (msg.audioUrl == null) return;

    // Stop if same message tapped
    if (_currentlyPlayingId == msg.id) {
      await _player?.stopPlayer();
      setState(() => _currentlyPlayingId = null);
      return;
    }

    await _player?.startPlayer(
      fromURI: msg.audioUrl,
      whenFinished: () {
        if (!mounted) return;
        setState(() => _currentlyPlayingId = null);
      },
    );

    _playerSub?.cancel();
    _playerSub = _player?.onProgress?.listen((event) {
      if (!mounted) return;

      final duration = event.duration.inMilliseconds;
      final position = event.position.inMilliseconds;

      setState(() {
        _currentlyPlayingId = msg.id;
        _playbackProgress = duration == 0 ? 0 : position / duration;
      });
    });
  }

  // =========================================================
  // SCROLL
  // =========================================================

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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final isTextEmpty = _textController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.tutor.name)),
      body: Column(
        children: [
          // =======================
          // MESSAGES
          // =======================
          Expanded(
            child: Obx(() {
              final messages =
                  controller.sessionMessages[widget.sessionId] ??
                  <ChatMessage>[];

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                itemCount: messages.length,
                itemBuilder: (_, index) {
                  final msg = messages[index];

                  final isMe =
                      _currentUserId != null && msg.senderId == _currentUserId;

                  final isPlaying = _currentlyPlayingId == msg.id;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(TSizes.sm),
                      decoration: BoxDecoration(
                        color: isMe ? TColors.primary : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          (msg.isVoice ?? false)
                              ? _buildVoiceBubble(msg, isMe, isPlaying)
                              : Text(
                                msg.text ?? '',
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

          // =======================
          // INPUT BAR
          // =======================
          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isTextEmpty ? _toggleRecording : _sendText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(
                    isTextEmpty
                        ? (_isRecording ? Icons.stop : Icons.mic)
                        : Icons.send,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // VOICE BUBBLE WIDGET
  // =========================================================

  Widget _buildVoiceBubble(ChatMessage msg, bool isMe, bool isPlaying) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _playVoice(msg),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: isMe ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: isPlaying ? _playbackProgress : 0,
            backgroundColor: isMe ? Colors.white24 : Colors.black12,
          ),
        ),
      ],
    );
  }
}
