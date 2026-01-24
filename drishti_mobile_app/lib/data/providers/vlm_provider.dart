/// VLM (Vision Language Model) Provider
///
/// Manages the state and lifecycle of the local vision language model.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/local_vlm_service.dart';

/// Provider for managing the local Vision Language Model
class VLMProvider extends ChangeNotifier {
  final LocalVLMService _vlmService = LocalVLMService();

  /// Current status of the VLM
  VLMStatus get status => _vlmService.status;

  /// Download/loading progress (0.0 to 1.0)
  double get progress => _vlmService.loadProgress;

  /// Error message if any
  String? get error => _vlmService.errorMessage;

  /// Whether the model is ready for inference
  bool get isReady => _vlmService.isReady;

  /// Whether models have been downloaded
  Future<bool> get areModelsDownloaded => _vlmService.areModelsDownloaded();

  /// Get the total size of downloaded models
  Future<int> get downloadedModelSize => _vlmService.getDownloadedModelSize();

  /// Download models if not already present
  ///
  /// Shows progress during download (~3GB total)
  Future<void> downloadModelsIfNeeded() async {
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
    if (!isReady) {
      throw Exception('VLM not ready. Call ensureReady() first.');
    }

    return await _vlmService.analyzeImage(
      imageBytes: imageBytes,
      prompt: prompt ?? 'Describe what you see in this image in detail.',
    );
  }

  /// Analyze an image from a file (more efficient for large images)
  ///
  /// [imageFile] - The image file
  /// [prompt] - Custom prompt for analysis (optional)
  Future<VLMResponse> analyzeImageFromFile({
    required File imageFile,
    String? prompt,
  }) async {
    if (!isReady) {
      throw Exception('VLM not ready. Call ensureReady() first.');
    }

    return await _vlmService.analyzeImageFromFile(
      imageFile: imageFile,
      prompt: prompt ?? 'Describe what you see in this image in detail.',
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
  List<VLMChatMessage> get chatHistory => _vlmService.chatHistory;

  /// Whether the model is currently generating a response
  bool get isGenerating => _vlmService.isGenerating;

  /// Current image being discussed in chat
  File? get currentChatImage => _vlmService.currentImage;

  /// Stream of tokens as they are generated
  Stream<String> get tokenStream => _vlmService.tokenStream;

  /// Start a new chat session with an image
  Future<void> startNewChat(File imageFile) async {
    if (!isReady) {
      throw Exception('VLM not ready. Call ensureReady() first.');
    }
    await _vlmService.startNewChat(imageFile);
    notifyListeners();
  }

  /// Send a message in the chat
  Future<VLMChatMessage> sendChatMessage(String message) async {
    if (!isReady) {
      throw Exception('VLM not ready. Call ensureReady() first.');
    }
    final response = await _vlmService.sendChatMessage(message);
    notifyListeners();
    return response;
  }

  /// Clear the chat and start fresh
  void clearChat() {
    _vlmService.clearChat();
    notifyListeners();
  }

  @override
  void dispose() {
    _vlmService.dispose();
    super.dispose();
  }
}
