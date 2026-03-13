/// VLM (Vision Language Model) Provider
///
/// Manages the state and lifecycle of the local vision language model.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../services/activity_log_service.dart';
import '../services/gemini_vision_service.dart';
import '../services/local_vlm_service.dart';

/// Provider for managing the local Vision Language Model
class VLMProvider extends ChangeNotifier {
  final LocalVLMService _vlmService = LocalVLMService();
  final GeminiVisionService _geminiVisionService = GeminiVisionService();
  final ActivityLogService _activityLogService = ActivityLogService();

  // Lightweight cloud-chat state so AI Vision chat works when Gemini is configured
  // even if local models are not initialized.
  final List<VLMChatMessage> _cloudChatHistory = [];
  final StreamController<String> _cloudTokenController =
      StreamController<String>.broadcast();
  File? _cloudCurrentImage;
  bool _cloudIsGenerating = false;

  bool get _hasLocalFallback => _vlmService.isReady;

  /// Current status of the VLM
  VLMStatus get status => _vlmService.status;

  /// Download/loading progress (0.0 to 1.0)
  double get progress => _vlmService.loadProgress;

  /// Error message if any
  String? get error => _vlmService.errorMessage;

  /// Whether the model is ready for inference
  bool get isReady => _vlmService.isReady;

  /// Whether backend-managed cloud vision is available for online-first inference.
  bool get hasCloudVisionConfigured => _geminiVisionService.isConfigured;

  /// Whether either Gemini or the local model can satisfy one-shot vision tasks.
  bool get isVisionAvailable => hasCloudVisionConfigured || _vlmService.isReady;

  /// Whether models have been downloaded
  Future<bool> get areModelsDownloaded => _vlmService.areModelsDownloaded();

  /// Get the total size of downloaded models
  Future<int> get downloadedModelSize => _vlmService.getDownloadedModelSize();

  /// Download models if not already present
  ///
  /// Shows progress during download (~3GB total)
  Future<void> downloadModelsIfNeeded() async {
    if (hasCloudVisionConfigured) {
      debugPrint(
        'VLM: Cloud vision backend available, skipping forced local download',
      );
      return;
    }

    if (await _vlmService.areModelsDownloaded()) {
      debugPrint('VLM: Models already downloaded');
      return;
    }

    debugPrint('VLM: Starting model download...');
    await _vlmService.downloadModels(
      onProgress: (progress, message) {
        debugPrint('VLM Download: $message');
        notifyListeners();
      },
    );
  }

  /// Initialize the VLM for inference
  ///
  /// Must be called after models are downloaded
  Future<void> initialize() async {
    if (hasCloudVisionConfigured && !_vlmService.isReady) {
      debugPrint('VLM: Cloud vision backend available, local init is optional');
      return;
    }

    if (_vlmService.isReady) {
      debugPrint('VLM: Already initialized');
      return;
    }

    debugPrint('VLM: Initializing model...');
    await _vlmService.initialize(
      onProgress: (progress, message) {
        debugPrint('VLM Init: $message');
        notifyListeners();
      },
    );
  }

  /// Ensure the model is ready for inference
  ///
  /// Downloads if needed, then initializes
  Future<void> ensureReady() async {
    await downloadModelsIfNeeded();
    await initialize();
  }

  /// Analyze an image and return a description
  ///
  /// [imageBytes] - The raw image bytes
  /// [prompt] - Custom prompt for analysis (optional)
  Future<VLMResponse> analyzeImage({
    required Uint8List imageBytes,
    String? prompt,
  }) async {
    final effectivePrompt =
        prompt ?? 'Describe what you see in this image in detail.';

    if (hasCloudVisionConfigured) {
      try {
        final result = await _geminiVisionService.analyzeImage(
          imageBytes: imageBytes,
          prompt: effectivePrompt,
        );

        final response = VLMResponse(
          text: result.description,
          promptTokens: result.promptTokens,
          completionTokens: result.completionTokens,
          inferenceTime: result.inferenceTime,
        );
        await _logScanEvent(
          description: response.text,
          prompt: effectivePrompt,
          source: 'cloud',
        );
        return response;
      } catch (e) {
        debugPrint(
          'VLM: Cloud vision request failed, trying local fallback: $e',
        );
      }
    }

    if (!isReady) {
      throw Exception(
        'Vision is unavailable. Configure Gemini for online use or initialize the local model.',
      );
    }

    final response = await _vlmService.analyzeImage(
      imageBytes: imageBytes,
      prompt: effectivePrompt,
    );
    await _logScanEvent(
      description: response.text,
      prompt: effectivePrompt,
      source: 'local',
    );
    return response;
  }

  /// Analyze an image from a file (more efficient for large images)
  ///
  /// [imageFile] - The image file
  /// [prompt] - Custom prompt for analysis (optional)
  Future<VLMResponse> analyzeImageFromFile({
    required File imageFile,
    String? prompt,
  }) async {
    final effectivePrompt =
        prompt ?? 'Describe what you see in this image in detail.';

    if (hasCloudVisionConfigured) {
      try {
        final result = await _geminiVisionService.analyzeImageFile(
          imageFile: imageFile,
          prompt: effectivePrompt,
        );

        final response = VLMResponse(
          text: result.description,
          promptTokens: result.promptTokens,
          completionTokens: result.completionTokens,
          inferenceTime: result.inferenceTime,
        );
        await _logScanEvent(
          description: response.text,
          prompt: effectivePrompt,
          source: 'cloud',
        );
        return response;
      } catch (e) {
        debugPrint(
          'VLM: Cloud vision request failed, trying local fallback: $e',
        );
      }
    }

    if (!isReady) {
      throw Exception(
        'Vision is unavailable. Configure Gemini for online use or initialize the local model.',
      );
    }

    final response = await _vlmService.analyzeImageFromFile(
      imageFile: imageFile,
      prompt: effectivePrompt,
    );
    await _logScanEvent(
      description: response.text,
      prompt: effectivePrompt,
      source: 'local',
    );
    return response;
  }

  Future<void> _logScanEvent({
    required String description,
    required String prompt,
    required String source,
  }) async {
    final summary = description.trim();
    if (summary.isEmpty) return;

    final compactSummary = summary.length > 220
        ? '${summary.substring(0, 220)}...'
        : summary;

    await _activityLogService.addLog(
      type: ActivityType.scan,
      title: 'Image described',
      description: compactSummary,
      metadata: {'source': source, 'prompt': prompt},
      isImportant: false,
    );
  }

  /// Stop any ongoing inference
  Future<void> stopInference() async {
    await _vlmService.stopInference();
  }

  /// Clear conversation context
  void clearContext() {
    _vlmService.clearContext();
  }

  /// Delete downloaded models to free storage
  Future<void> deleteModels() async {
    await _vlmService.deleteModels();
    notifyListeners();
  }

  /// Analyze an image for accessibility purposes
  ///
  /// Provides a description optimized for visually impaired users
  Future<String> describeForAccessibility(Uint8List imageBytes) async {
    final response = await analyzeImage(
      imageBytes: imageBytes,
      prompt: '''Describe this image for a visually impaired person. 
Include:
1. The main subject or scene
2. Any people present (approximate number, actions)
3. Important objects
4. Colors and lighting
5. Any text visible in the image
Be concise but thorough.''',
    );
    return response.text;
  }

  /// Identify objects in the image
  Future<String> identifyObjects(Uint8List imageBytes) async {
    final response = await analyzeImage(
      imageBytes: imageBytes,
      prompt: 'List all objects you can identify in this image. Be specific.',
    );
    return response.text;
  }

  /// Read any text visible in the image
  Future<String> readText(Uint8List imageBytes) async {
    final response = await analyzeImage(
      imageBytes: imageBytes,
      prompt:
          'Read and transcribe any text visible in this image. If no text is visible, say "No text found."',
    );
    return response.text;
  }

  /// Describe a scene for navigation assistance
  Future<String> describeForNavigation(Uint8List imageBytes) async {
    final response = await analyzeImage(
      imageBytes: imageBytes,
      prompt:
          '''Describe this scene for someone who needs navigation assistance.
Focus on:
1. Obstacles or hazards
2. Pathways or walkable areas
3. Doors, stairs, or elevation changes
4. People or moving objects
5. Signs or landmarks
Be direct and safety-focused.''',
    );
    return response.text;
  }

  // ==================== Chat API ====================

  /// Chat history for multi-turn conversations
  List<VLMChatMessage> get chatHistory => hasCloudVisionConfigured
      ? List.unmodifiable(_cloudChatHistory)
      : _vlmService.chatHistory;

  /// Whether the model is currently generating a response
  bool get isGenerating =>
      hasCloudVisionConfigured ? _cloudIsGenerating : _vlmService.isGenerating;

  /// Current image being discussed in chat
  File? get currentChatImage =>
      hasCloudVisionConfigured ? _cloudCurrentImage : _vlmService.currentImage;

  /// Stream of tokens as they are generated
  Stream<String> get tokenStream => hasCloudVisionConfigured
      ? _cloudTokenController.stream
      : _vlmService.tokenStream;

  /// Start a new chat session with an image
  Future<void> startNewChat(File imageFile) async {
    if (hasCloudVisionConfigured) {
      _cloudChatHistory.clear();
      _cloudCurrentImage = imageFile;
      _cloudIsGenerating = false;
      notifyListeners();
      return;
    }

    if (!isReady) {
      throw Exception('VLM not ready. Call ensureReady() first.');
    }
    await _vlmService.startNewChat(imageFile);
    notifyListeners();
  }

  /// Send a message in the chat
  Future<VLMChatMessage> sendChatMessage(String message) async {
    if (hasCloudVisionConfigured) {
      if (_cloudCurrentImage == null) {
        throw Exception('No image selected. Start a new chat first.');
      }

      final userMessage = VLMChatMessage(role: 'user', content: message);
      _cloudChatHistory.add(userMessage);
      _cloudIsGenerating = true;
      notifyListeners();

      try {
        final conversationContext = _cloudChatHistory
            .where((m) => m.content.trim().isNotEmpty)
            .take(8)
            .map((m) => '${m.role}: ${m.content}')
            .join('\n');

        final result = await _geminiVisionService.analyzeImageFile(
          imageFile: _cloudCurrentImage!,
          prompt:
              'You are in an image chat session. Answer the latest user question using only details visible in the image. '
              'Give a slightly fuller answer in 2 to 4 short sentences. '
              'If uncertain, say so briefly.\n\n'
              'Conversation so far:\n$conversationContext\n\n'
              'Latest user question: $message',
        );

        final assistantMessage = VLMChatMessage(
          role: 'assistant',
          content: result.description,
          inferenceTime: result.inferenceTime,
        );
        _cloudChatHistory.add(assistantMessage);

        // Keep streaming UI behavior by publishing the final text as one chunk.
        _cloudTokenController.add(assistantMessage.content);

        return assistantMessage;
      } catch (e) {
        if (_hasLocalFallback) {
          debugPrint(
            'VLM: Cloud vision chat failed, switching to local fallback: $e',
          );
          return await _sendLocalFallbackChatMessage(message);
        }
        rethrow;
      } finally {
        _cloudIsGenerating = false;
        notifyListeners();
      }
    }

    if (!isReady) {
      throw Exception('VLM not ready. Call ensureReady() first.');
    }
    final response = await _vlmService.sendChatMessage(message);
    notifyListeners();
    return response;
  }

  Future<VLMChatMessage> _sendLocalFallbackChatMessage(String message) async {
    final imageFile = _cloudCurrentImage;
    if (imageFile == null) {
      throw Exception('No image selected. Start a new chat first.');
    }

    final localImagePath = _vlmService.currentImage?.path;
    if (localImagePath != imageFile.path) {
      await _vlmService.startNewChat(imageFile);
    }

    final localResponse = await _vlmService.sendChatMessage(message);

    if (_cloudChatHistory.isNotEmpty &&
        _cloudChatHistory.last.isUser &&
        _cloudChatHistory.last.content == message) {
      _cloudChatHistory.add(localResponse);
    }

    _cloudTokenController.add(localResponse.content);
    return localResponse;
  }

  /// Clear the chat and start fresh
  void clearChat() {
    if (hasCloudVisionConfigured) {
      _cloudChatHistory.clear();
      _cloudCurrentImage = null;
      _cloudIsGenerating = false;
    } else {
      _vlmService.clearChat();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cloudTokenController.close();
    _vlmService.dispose();
    super.dispose();
  }
}
