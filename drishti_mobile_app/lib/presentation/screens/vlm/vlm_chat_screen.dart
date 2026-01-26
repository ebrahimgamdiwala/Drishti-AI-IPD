/// VLM Chat Screen
///
/// A chat-style interface for multi-turn conversations about images.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/vlm_provider.dart';
import '../../../data/services/local_vlm_service.dart';
import '../../../data/services/voice_service.dart';

class VLMChatScreen extends StatefulWidget {
  const VLMChatScreen({super.key});

  @override
  State<VLMChatScreen> createState() => _VLMChatScreenState();
}

class _VLMChatScreenState extends State<VLMChatScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final VoiceService _voiceService = VoiceService();

  // Streaming response
  String _streamingText = '';
  StreamSubscription<String>? _tokenSubscription;
  bool _isSpeaking = false;
  String? _speakingMessageId;

  // Typing animation
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _voiceService.initTts();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingController.dispose();
    _voiceService.stopSpeaking();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startStreamingTokens(VLMProvider vlm) {
    _streamingText = '';
    _tokenSubscription?.cancel();
    _tokenSubscription = vlm.tokenStream.listen((token) {
      if (!mounted) return;
      setState(() {
        // Stream now emits cumulative text; replace instead of append
        _streamingText = token;
      });
      _scrollToBottom();
    });
  }

  void _stopStreamingTokens() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<void> _speakText(String text, String messageId) async {
    if (_isSpeaking && _speakingMessageId == messageId) {
      await _voiceService.stopSpeaking();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageId = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _speakingMessageId = messageId;
        });
      }
      await _voiceService.speak(text);
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('AI Vision Chat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<VLMProvider>(
            builder: (context, vlm, _) => vlm.currentChatImage != null
                ? IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'New Chat',
                    onPressed: () {
                      vlm.clearChat();
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<VLMProvider>(
        builder: (context, vlm, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          if (!vlm.isReady) {
            return _buildNotReadyState(vlm, isDark);
          }
          return _buildChatInterface(vlm, isDark);
        },
      ),
    );
  }

  Widget _buildNotReadyState(VLMProvider vlm, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final bgColor = isDark ? Colors.white24 : Colors.black12;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_rounded,
              size: 80,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              vlm.status == VLMStatus.downloading
                  ? 'Downloading AI Model...'
                  : vlm.status == VLMStatus.loading
                  ? 'Loading AI Model...'
                  : 'AI Model Not Ready',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            if (vlm.status == VLMStatus.downloading ||
                vlm.status == VLMStatus.loading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: vlm.progress,
                    backgroundColor: bgColor,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(vlm.progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => vlm.ensureReady(),
                icon: const Icon(Icons.download),
                label: const Text('Download Model (~3GB)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            if (vlm.error != null) ...[
              const SizedBox(height: 16),
              Text(
                vlm.error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface(VLMProvider vlm, bool isDark) {
    // If no image selected yet, show image picker prompt
    if (vlm.currentChatImage == null) {
      return _buildImagePickerPrompt(vlm, isDark);
    }

    // Calculate item count: image header + messages + streaming bubble if generating
    final itemCount = 1 + vlm.chatHistory.length + (vlm.isGenerating ? 1 : 0);

    return Column(
      children: [
        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildImageHeader(vlm.currentChatImage!, isDark);
              }

              final messageIndex = index - 1;

              // If generating, show streaming bubble at the end
              if (vlm.isGenerating && messageIndex == vlm.chatHistory.length) {
                return _buildStreamingBubble(isDark);
              }

              if (messageIndex < vlm.chatHistory.length) {
                final message = vlm.chatHistory[messageIndex];
                return _buildChatBubble(message, isDark);
              }

              return const SizedBox.shrink();
            },
          ),
        ),

        // Message input
        _buildMessageInput(vlm, isDark),
      ],
    );
  }

  Widget _buildStreamingBubble(bool isDark) {
    final bubbleBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark
        ? AppColors.primaryBlue.withValues(alpha: 0.3)
        : AppColors.primaryBlue.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_streamingText.isEmpty)
                    _buildTypingIndicator()
                  else
                    Text(
                      _streamingText,
                      style: TextStyle(
                        color: textColor.withValues(alpha: isDark ? 0.9 : 0.8),
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _streamingText.isEmpty
                            ? 'Processing image...'
                            : 'Generating...',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final value = ((_typingController.value + delay) % 1.0);
            final bounce = (value < 0.5) ? value * 2 : (1 - value) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -6 * bounce),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(
                      alpha: 0.4 + 0.6 * bounce,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildImagePickerPrompt(VLMProvider vlm, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 100,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Start a Conversation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select an image to begin chatting with AI.\nAsk questions about the image and get detailed answers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera, vlm),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, vlm),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlueLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(File imageFile, bool isDark) {
    final borderColor = isDark
        ? AppColors.primaryBlue.withValues(alpha: 0.3)
        : AppColors.primaryBlue.withValues(alpha: 0.2);
    final infoBgColor = isDark
        ? AppColors.primaryBlue.withValues(alpha: 0.1)
        : AppColors.primaryBlue.withValues(alpha: 0.05);
    final infoTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.file(imageFile, height: 200, fit: BoxFit.cover),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: infoBgColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ask me anything about this image!',
                    style: TextStyle(color: infoTextColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(VLMChatMessage message, bool isDark) {
    final isUser = message.isUser;
    final isCurrentlySpeaking = _isSpeaking && _speakingMessageId == message.id;
    final userBubbleColor = AppColors.primaryBlue;
    final aiBubbleColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.4);
    final listenButtonColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (message.inferenceTime != null)
                        Text(
                          '${(message.inferenceTime!.inMilliseconds / 1000).toStringAsFixed(1)}s',
                          style: TextStyle(
                            fontSize: 11,
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.6)
                                : secondaryTextColor,
                          ),
                        ),
                      // Listen button for AI messages
                      if (!isUser)
                        InkWell(
                          onTap: () => _speakText(message.content, message.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentlySpeaking
                                  ? AppColors.primaryBlue.withValues(alpha: 0.3)
                                  : listenButtonColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCurrentlySpeaking
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  size: 14,
                                  color: isCurrentlySpeaking
                                      ? AppColors.primaryBlue
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.6,
                                              )),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCurrentlySpeaking ? 'Stop' : 'Listen',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isCurrentlySpeaking
                                        ? AppColors.primaryBlue
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.6,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.6,
                                                )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(VLMProvider vlm, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final inputBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final inputBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final containerBgColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.1);
    final containerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerBgColor,
        border: Border(top: BorderSide(color: containerBorderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                enabled: !vlm.isGenerating,
                decoration: InputDecoration(
                  hintText: 'Ask about the image...',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: textColor),
                textInputAction: TextInputAction.send,
                onSubmitted: vlm.isGenerating ? null : (_) => _sendMessage(vlm),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: vlm.isGenerating ? Colors.grey : AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: vlm.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                color: Colors.white,
                onPressed: vlm.isGenerating ? null : () => _sendMessage(vlm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, VLMProvider vlm) async {
    // Compress at capture time to speed up upload/inference
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      await vlm.startNewChat(File(image.path));
    }
  }

  Future<void> _sendMessage(VLMProvider vlm) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    // Clear previous streaming text and start listening
    setState(() {
      _streamingText = '';
    });
    _startStreamingTokens(vlm);
    _scrollToBottom();

    try {
      final aiMessage = await vlm.sendChatMessage(message);

      // Stop streaming and finalize
      _stopStreamingTokens();
      setState(() {
        _streamingText = '';
      });

      _scrollToBottom();

      // Auto-speak the response
      if (aiMessage.content.isNotEmpty) {
        _speakText(aiMessage.content, aiMessage.id);
      }
    } catch (e) {
      _stopStreamingTokens();
      setState(() {
        _streamingText = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
