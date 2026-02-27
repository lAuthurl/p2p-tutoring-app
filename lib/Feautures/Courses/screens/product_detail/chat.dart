// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../models/ModelProvider.dart';

/// -----------------------------
/// Message Model
/// -----------------------------
class ChatMessage {
  final String id;
  final String? text;
  final bool isMe;
  final DateTime timestamp;
  final bool isVoice;
  final String? audioPath;

  ChatMessage({
    required this.id,
    this.text,
    required this.isMe,
    required this.timestamp,
    this.isVoice = false,
    this.audioPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isMe': isMe,
    'timestamp': timestamp.toIso8601String(),
    'isVoice': isVoice,
    'audioPath': audioPath,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    text: json['text'],
    isMe: json['isMe'],
    timestamp: DateTime.parse(json['timestamp']),
    isVoice: json['isVoice'] ?? false,
    audioPath: json['audioPath'],
  );
}

/// -----------------------------
/// Chat Screen (unique per session)
/// -----------------------------
class ChatScreen extends StatefulWidget {
  final Tutor tutor;
  final String sessionId; // unique per session

  const ChatScreen({super.key, required this.tutor, required this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  bool _isRecording = false;
  bool _isTextEmpty = true;
  String? _currentlyPlayingId;
  double _playbackProgress = 0.0;

  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initAudio();
    _loadSavedMessages();

    _controller.addListener(() {
      setState(() => _isTextEmpty = _controller.text.trim().isEmpty);
    });
  }

  /// Initialize recorder and player
  Future<void> _initAudio() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _controller.dispose();
    super.dispose();
  }

  /// Load messages from storage (unique per session)
  void _loadSavedMessages() {
    final stored = _storage.read<List>('chat_${widget.sessionId}') ?? [];
    _messages.addAll(
      stored.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))),
    );
    setState(() {});
    _scrollToBottom();
  }

  /// Save messages to storage
  void _saveMessages() {
    final toStore = _messages.map((e) => e.toJson()).toList();
    _storage.write('chat_${widget.sessionId}', toStore);
  }

  /// Send text message
  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final msg = ChatMessage(
      id: DateTime.now().toString(),
      text: _controller.text.trim(),
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() => _messages.add(msg));
    _controller.clear();
    _scrollToBottom();
    _saveMessages();
  }

  /// Toggle voice recording
  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
      setState(() => _isRecording = true);
    } else {
      final path = await _recorder!.stopRecorder();
      setState(() => _isRecording = false);

      if (path != null) {
        final msg = ChatMessage(
          id: DateTime.now().toString(),
          isMe: true,
          isVoice: true,
          audioPath: path,
          timestamp: DateTime.now(),
        );
        setState(() => _messages.add(msg));
        _scrollToBottom();
        _saveMessages();
      }
    }
  }

  /// Play recorded voice
  Future<void> _playVoice(ChatMessage msg) async {
    if (_currentlyPlayingId == msg.id) {
      await _player!.stopPlayer();
      setState(() => _currentlyPlayingId = null);
      return;
    }

    await _player!.startPlayer(
      fromURI: msg.audioPath,
      whenFinished: () => setState(() => _currentlyPlayingId = null),
    );

    _player!.onProgress!.listen((e) {
      setState(() {
        _currentlyPlayingId = msg.id;
        _playbackProgress =
            e.duration.inMilliseconds == 0
                ? 0
                : e.position.inMilliseconds / e.duration.inMilliseconds;
      });
    });
  }

  /// Scroll chat to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tutor.name)),
      body: Column(
        children: [
          /// Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isPlaying = _currentlyPlayingId == msg.id;

                return Align(
                  alignment:
                      msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: msg.isMe ? TColors.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        msg.isVoice
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => _playVoice(msg),
                                  child: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color:
                                        msg.isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    value: isPlaying ? _playbackProgress : 0,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              ],
                            )
                            : Text(
                              msg.text ?? '',
                              style: TextStyle(
                                color: msg.isMe ? Colors.white : Colors.black,
                              ),
                            ),
                  ),
                );
              },
            ),
          ),

          /// Input
          Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                /// Mic / Send Button
                GestureDetector(
                  onLongPress: _toggleRecording,
                  onLongPressUp: _toggleRecording,
                  child: ElevatedButton(
                    onPressed: _isTextEmpty ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Icon(
                      _isTextEmpty
                          ? (_isRecording ? Icons.stop : Icons.mic)
                          : Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
