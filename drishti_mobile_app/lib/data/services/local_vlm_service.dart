/// Local Vision Language Model (VLM) Service
///
/// This service provides on-device image understanding using LLaVA Phi-3
/// powered by llama.cpp through Dart FFI bindings.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';

/// A chat message in the VLM conversation
class VLMChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool hasImage;
  final File? imageFile;
  final Duration? inferenceTime;

  VLMChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.hasImage = false,
    this.imageFile,
    this.inferenceTime,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// Configuration for the local VLM
class VLMConfig {
  /// Path to the main model file (GGUF format)
  final String modelPath;

  /// Path to the multimodal projector file (mmproj GGUF)
  final String mmProjPath;

  /// Number of threads to use for inference
  final int nThreads;

  /// Context window size
  final int contextSize;

  /// Temperature for sampling
  final double temperature;

  /// Top-p sampling
  final double topP;

  /// Max tokens to generate
  final int maxTokens;

  const VLMConfig({
    required this.modelPath,
    required this.mmProjPath,
    this.nThreads = 4,
    this.contextSize = 2048,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.maxTokens = 512,
  });
}

/// Response from the VLM
class VLMResponse {
  final String text;
  final int promptTokens;
  final int completionTokens;
  final Duration inferenceTime;

  const VLMResponse({
    required this.text,
    required this.promptTokens,
    required this.completionTokens,
    required this.inferenceTime,
  });

  double get tokensPerSecond =>
      completionTokens / (inferenceTime.inMilliseconds / 1000);
}

/// Status of model loading
enum VLMStatus { uninitialized, downloading, loading, ready, error }

/// Progress callback for model operations
typedef VLMProgressCallback = void Function(double progress, String message);

/// Local Vision Language Model Service
///
/// This service manages the lifecycle of a local VLM for image understanding.
/// It uses LLaVA Phi-3 (quantized) for efficient on-device inference.
class LocalVLMService extends ChangeNotifier {
  VLMStatus _status = VLMStatus.uninitialized;
  String? _errorMessage;
  double _loadProgress = 0.0;

  // llama_cpp_dart components
  LlamaParent? _llama;
  bool _isModelLoaded = false;

  // Chat history for multi-turn conversations
  final List<VLMChatMessage> _chatHistory = [];
  File? _currentImage;
  LlamaImage? _cachedLlamaImage;
  bool _isGenerating = false;

  // Stream controller for real-time token streaming
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  /// Stream of tokens as they are generated
  Stream<String> get tokenStream => _tokenController.stream;

  /// Current chat history
  List<VLMChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  /// Whether the model is currently generating
  bool get isGenerating => _isGenerating;

  /// Current image being discussed
  File? get currentImage => _currentImage;

  // Model file names - using INT4 quantized for mobile efficiency
  static const String _modelFileName = 'llava-phi-3-mini-int4.gguf';
  static const String _mmProjFileName = 'llava-phi-3-mini-mmproj-f16.gguf';

  // Hugging Face URLs for model download
  static const String _modelUrl =
      'https://huggingface.co/xtuner/llava-phi-3-mini-gguf/resolve/main/llava-phi-3-mini-int4.gguf';
  static const String _mmProjUrl =
      'https://huggingface.co/xtuner/llava-phi-3-mini-gguf/resolve/main/llava-phi-3-mini-mmproj-f16.gguf';

  // Approximate file sizes for progress calculation
  // Fallback expected sizes (used if server doesn't send Content-Length)
  static const int _modelSizeBytes = 2500000000; // ~2.5GB for INT4
  static const int _mmProjSizeBytes = 600000000; // ~600MB for mmproj

  VLMStatus get status => _status;
  String? get errorMessage => _errorMessage;
  double get loadProgress => _loadProgress;
  bool get isReady => _status == VLMStatus.ready;

  /// Directory where models are stored
  Future<Directory> get _modelsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Check if models are already downloaded
  Future<bool> areModelsDownloaded() async {
    final dir = await _modelsDir;
    final modelFile = File('${dir.path}/$_modelFileName');
    final mmProjFile = File('${dir.path}/$_mmProjFileName');
    return await modelFile.exists() && await mmProjFile.exists();
  }

  /// Get the size of downloaded models
  Future<int> getDownloadedModelSize() async {
    final dir = await _modelsDir;
    final modelFile = File('${dir.path}/$_modelFileName');
    final mmProjFile = File('${dir.path}/$_mmProjFileName');

    int size = 0;
    if (await modelFile.exists()) {
      size += await modelFile.length();
    }
    if (await mmProjFile.exists()) {
      size += await mmProjFile.length();
    }
    return size;
  }

  /// Download models from Hugging Face
  Future<void> downloadModels({VLMProgressCallback? onProgress}) async {
    _status = VLMStatus.downloading;
    _loadProgress = 0.0;
    notifyListeners();

    try {
      final dir = await _modelsDir;
      final modelPath = '${dir.path}/$_modelFileName';
      final mmProjPath = '${dir.path}/$_mmProjFileName';

      // Track combined progress using real Content-Length when available
      int modelTotal = _modelSizeBytes;
      int projTotal = _mmProjSizeBytes;
      int downloadedSoFar = 0;

      // Download main model
      onProgress?.call(0.0, 'Downloading LLaVA Phi-3 model...');
      final modelDownloaded = await _downloadFile(_modelUrl, modelPath, (
        downloaded,
        total,
      ) {
        modelTotal = total ?? modelTotal;
        final totalBytes = modelTotal + projTotal;
        final overallDownloaded = downloadedSoFar + downloaded;
        _loadProgress = overallDownloaded / totalBytes;
        onProgress?.call(
          _loadProgress,
          'Model: ${(_loadProgress * 100).toStringAsFixed(1)}% '
          '(${_humanBytes(overallDownloaded)}/${_humanBytes(totalBytes)})',
        );
        notifyListeners();
      });

      downloadedSoFar += modelDownloaded;

      // Download multimodal projector
      onProgress?.call(_loadProgress, 'Downloading vision projector...');
      final projDownloaded = await _downloadFile(_mmProjUrl, mmProjPath, (
        downloaded,
        total,
      ) {
        projTotal = total ?? projTotal;
        final totalBytes = modelTotal + projTotal;
        final overallDownloaded = downloadedSoFar + downloaded;
        _loadProgress = overallDownloaded / totalBytes;
        onProgress?.call(
          _loadProgress,
          'Projector: ${(_loadProgress * 100).toStringAsFixed(1)}% '
          '(${_humanBytes(overallDownloaded)}/${_humanBytes(totalBytes)})',
        );
        notifyListeners();
      });

      downloadedSoFar += projDownloaded;

      _loadProgress = 1.0;
      onProgress?.call(1.0, 'Download complete!');
      notifyListeners();
    } catch (e) {
      _status = VLMStatus.error;
      _errorMessage = 'Failed to download models: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Download a file with progress tracking
  /// Download a file and report raw byte progress. Returns bytes downloaded.
  Future<int> _downloadFile(
    String url,
    String savePath,
    void Function(int downloaded, int? totalBytes) onProgress,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength != -1
          ? response.contentLength
          : null;

      final file = File(savePath);
      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        downloaded += chunk.length;
        onProgress(downloaded, contentLength);
      }

      await sink.close();
      return downloaded;
    } finally {
      client.close();
    }
  }

  String _humanBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unitIndex]}';
  }

  int _suggestThreads() {
    final cores = Platform.numberOfProcessors;
    // Use more threads when available (but keep a cap to avoid thermal issues)
    final suggested = cores - 1; // leave one core for UI
    if (suggested >= 6) return 6;
    if (suggested >= 4) return 4;
    if (suggested >= 3) return 3;
    return 2;
  }

  /// Initialize the VLM engine
  ///
  /// This loads the model into memory. Should be called after models are downloaded.
  Future<void> initialize({VLMProgressCallback? onProgress}) async {
    if (_status == VLMStatus.ready) return;

    _status = VLMStatus.loading;
    _errorMessage = null;
    _loadProgress = 0.0;
    notifyListeners();

    try {
      // Check if models exist
      if (!await areModelsDownloaded()) {
        throw Exception('Models not downloaded. Call downloadModels() first.');
      }

      final dir = await _modelsDir;
      final modelPath = '${dir.path}/$_modelFileName';
      final mmProjPath = '${dir.path}/$_mmProjFileName';

      // Debug: Verify files exist and show sizes
      final modelFile = File(modelPath);
      final projFile = File(mmProjPath);
      final modelSize = await modelFile.length();
      final projSize = await projFile.length();
      debugPrint('[VLM] Model path: $modelPath');
      debugPrint(
        '[VLM] Model size: ${_humanBytes(modelSize)} ($modelSize bytes)',
      );
      debugPrint('[VLM] Proj path: $mmProjPath');
      debugPrint('[VLM] Proj size: ${_humanBytes(projSize)} ($projSize bytes)');

      // Sanity check: model should be at least 500MB
      if (modelSize < 500000000) {
        throw Exception(
          'Model file appears incomplete (${_humanBytes(modelSize)}). Please redownload.',
        );
      }

      onProgress?.call(0.1, 'Initializing model parameters...');
      _loadProgress = 0.1;
      notifyListeners();

      // Configure model parameters for mobile efficiency
      final modelParams = ModelParams()
        ..nGpuLayers =
            0 // CPU only for mobile compatibility
        ..mainGpu =
            -1 // No GPU device (fixes "invalid value for main_gpu: 0" error)
        // mmap can fail on some devices/storage; disable to load directly
        ..useMemorymap = false
        ..useMemoryLock = false;

      // Configure context parameters (reduced to lower RAM/CPU load)
      final threads = _suggestThreads();
      final contextParams = ContextParams()
        ..nCtx =
            1024 // Smaller context to reduce memory
        ..nBatch = 256
        ..nThreads = threads
        ..nThreadsBatch = threads;

      // Configure sampler parameters for generation
      final samplerParams = SamplerParams()
        ..temp = 0.7
        ..topP = 0.9
        ..topK = 40
        ..penaltyRepeat = 1.1;

      onProgress?.call(0.3, 'Loading LLaVA model into memory...');
      _loadProgress = 0.3;
      notifyListeners();

      // Create the load command with multimodal projector
      final loadCommand = LlamaLoad(
        path: modelPath,
        modelParams: modelParams,
        contextParams: contextParams,
        samplingParams: samplerParams,
        mmprojPath: mmProjPath, // Vision projector for multimodal
        verbose: true, // Always enable for troubleshooting
      );

      // Create LlamaParent for isolate-based inference (non-blocking)
      // LlamaParent requires the loadCommand as constructor argument
      _llama = LlamaParent(loadCommand);

      onProgress?.call(0.5, 'Loading vision projector...');
      _loadProgress = 0.5;
      notifyListeners();

      // Initialize the isolate and load the model (can take ~30–120s)
      onProgress?.call(0.8, 'Initializing model (this can take a minute)...');
      _loadProgress = 0.8;
      notifyListeners();

      await _llama!.init().timeout(const Duration(seconds: 120));
      _isModelLoaded = true;

      onProgress?.call(1.0, 'Model ready!');
      _loadProgress = 1.0;
      _status = VLMStatus.ready;
      notifyListeners();
    } catch (e) {
      _status = VLMStatus.error;
      _errorMessage = 'Failed to initialize model: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Analyze an image and generate a description
  ///
  /// [imageBytes] - The image data as bytes
  /// [prompt] - The prompt to guide the analysis (e.g., "Describe this image")
  Future<VLMResponse> analyzeImage({
    required Uint8List imageBytes,
    String prompt = 'Describe what you see in this image in detail.',
  }) async {
    if (_status != VLMStatus.ready || _llama == null || !_isModelLoaded) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Create LlamaImage from bytes for multimodal input
      final image = LlamaImage.fromBytes(imageBytes);

      // Build the prompt with image
      // LLaVA Phi-3 uses a specific format
      final formattedPrompt =
          '<|user|>\n<image>\n$prompt<|end|>\n<|assistant|>';

      debugPrint('[VLM] Sending prompt with image...');

      // sendPromptWithImages returns a promptId, not the response text
      // We need to listen to the stream and wait for completion
      final StringBuffer responseBuffer = StringBuffer();

      // Subscribe to the token stream before sending prompt
      final subscription = _llama!.stream.listen((token) {
        responseBuffer.write(token);
        debugPrint('[VLM] Token: $token');
      });

      // Send the prompt with images - returns promptId
      final promptId = await _llama!.sendPromptWithImages(formattedPrompt, [
        image,
      ]);

      debugPrint(
        '[VLM] Prompt sent, waiting for completion (id: $promptId)...',
      );

      // Wait for generation to complete
      await _llama!.waitForCompletion(promptId);

      // Cancel the subscription
      await subscription.cancel();

      stopwatch.stop();

      final responseText = responseBuffer.toString();
      debugPrint('[VLM] Response: $responseText');

      // Clean up the response text
      final cleanedResponse = responseText
          .replaceAll('</s>', '')
          .replaceAll('<|end|>', '')
          .replaceAll('[/INST]', '')
          .trim();

      return VLMResponse(
        text: cleanedResponse.isEmpty
            ? 'Unable to analyze image.'
            : cleanedResponse,
        promptTokens: formattedPrompt.length ~/ 4, // Approximate token count
        completionTokens: cleanedResponse.split(' ').length,
        inferenceTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      throw Exception('Image analysis failed: $e');
    }
  }

  /// Analyze an image from a file path
  ///
  /// More efficient for isolate-based processing as it avoids copying bytes
  Future<VLMResponse> analyzeImageFromFile({
    required File imageFile,
    String prompt = 'Describe what you see in this image in detail.',
  }) async {
    if (_status != VLMStatus.ready || _llama == null || !_isModelLoaded) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Create LlamaImage from file (more efficient for isolates)
      final image = LlamaImage.fromFile(imageFile);

      // Build the prompt with image - LLaVA Phi-3 format
      final formattedPrompt =
          '<|user|>\n<image>\n$prompt<|end|>\n<|assistant|>';

      debugPrint('[VLM] Sending prompt with image file: ${imageFile.path}');

      // Collect tokens from stream
      final StringBuffer responseBuffer = StringBuffer();

      // Subscribe to the token stream before sending prompt
      final subscription = _llama!.stream.listen((token) {
        responseBuffer.write(token);
        debugPrint('[VLM] Token: $token');
      });

      // Send the prompt with images - returns promptId
      final promptId = await _llama!.sendPromptWithImages(formattedPrompt, [
        image,
      ]);

      debugPrint(
        '[VLM] Prompt sent, waiting for completion (id: $promptId)...',
      );

      // Wait for generation to complete
      await _llama!.waitForCompletion(promptId);

      // Cancel the subscription
      await subscription.cancel();

      stopwatch.stop();

      final responseText = responseBuffer.toString();
      debugPrint('[VLM] Response: $responseText');

      // Clean up the response text
      final cleanedResponse = responseText
          .replaceAll('</s>', '')
          .replaceAll('<|end|>', '')
          .replaceAll('[/INST]', '')
          .trim();

      return VLMResponse(
        text: cleanedResponse.isEmpty
            ? 'Unable to analyze image.'
            : cleanedResponse,
        promptTokens: formattedPrompt.length ~/ 4,
        completionTokens: cleanedResponse.split(' ').length,
        inferenceTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      throw Exception('Image analysis failed: $e');
    }
  }

  /// Stop any ongoing inference
  Future<void> stopInference() async {
    _isGenerating = false;
    await _llama?.stop();
    notifyListeners();
  }

  /// Clear the context/conversation history
  void clearContext() {
    // Clear messages if using chat history
    _llama?.messages.clear();
  }

  /// Start a new chat session with an image
  ///
  /// This sets the current image for the conversation and clears previous history
  Future<void> startNewChat(File imageFile) async {
    // Stop any ongoing generation
    if (_isGenerating) {
      await stopInference();
    }

    _chatHistory.clear();
    _currentImage = imageFile;
    // Create LlamaImage - will read file in isolate
    _cachedLlamaImage = LlamaImage.fromFile(imageFile);

    // Clear llama context for fresh conversation
    clearContext();
    // Reset streaming state for a clean first response
    _isGenerating = false;
    _tokenController.add('');

    debugPrint('[VLM] Started new chat with image: ${imageFile.path}');
    notifyListeners();
  }

  /// Send a message in the chat and get a response
  ///
  /// For the first message, include the image in the prompt.
  /// For follow-up messages, continue the conversation without re-sending image.
  Future<VLMChatMessage> sendChatMessage(String userMessage) async {
    if (_status != VLMStatus.ready || _llama == null || !_isModelLoaded) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    if (_currentImage == null || _cachedLlamaImage == null) {
      throw Exception('No image set. Call startNewChat() first.');
    }

    // Prevent sending while already generating
    if (_isGenerating) {
      debugPrint('[VLM Chat] Already generating, rejecting new message');
      throw Exception('Already generating a response. Please wait.');
    }

    _isGenerating = true;
    notifyListeners();

    // Count user messages BEFORE adding this one
    final existingUserMessages = _chatHistory.where((m) => m.isUser).length;
    final isFirstMessage = existingUserMessages == 0;

    // Add user message to history
    final userChatMessage = VLMChatMessage(
      role: 'user',
      content: userMessage,
      hasImage: isFirstMessage,
      imageFile: isFirstMessage ? _currentImage : null,
    );
    _chatHistory.add(userChatMessage);
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    StreamSubscription<String>? subscription;

    try {
      // Build the prompt based on whether this is the first message or follow-up
      String formattedPrompt;
      List<LlamaImage> images;

      if (isFirstMessage) {
        // First user message - include image
        formattedPrompt =
            '<|user|>\n<image>\n$userMessage<|end|>\n<|assistant|>';
        images = [_cachedLlamaImage!];
        debugPrint(
          '[VLM Chat] FIRST message with image: ${_currentImage!.path}',
        );
      } else {
        // Follow-up message - no image, continue conversation
        // For LLaVA Phi-3, we need to maintain context but not resend the image
        formattedPrompt = '<|user|>\n$userMessage<|end|>\n<|assistant|>';
        images = []; // Empty list for follow-ups
        debugPrint('[VLM Chat] FOLLOW-UP message #${existingUserMessages + 1}');
      }

      debugPrint('[VLM Chat] Formatted prompt: $formattedPrompt');
      debugPrint('[VLM Chat] Images to send: ${images.length}');

      // Collect tokens from stream (dedupe cumulative chunks)
      final StringBuffer responseBuffer = StringBuffer();
      int tokenCount = 0;

      // Subscribe to the token stream BEFORE sending prompt
      subscription = _llama!.stream.listen(
        (token) {
          if (token.isEmpty) return;

          tokenCount++;

          final current = responseBuffer.toString();

          // Some backends emit cumulative partials; replace instead of append
          if (token.startsWith(current)) {
            responseBuffer
              ..clear()
              ..write(token);
          } else {
            responseBuffer.write(token);
          }

          final streamText = responseBuffer.toString();
          debugPrint(
            '[VLM Chat] Token #$tokenCount => "$token" (len=${streamText.length})',
          );

          // Forward cumulative text to UI to avoid duplicated fragments
          _tokenController.add(streamText);
        },
        onError: (error) {
          debugPrint('[VLM Chat] Stream error: $error');
        },
        onDone: () {
          debugPrint('[VLM Chat] Stream done');
        },
      );

      debugPrint('[VLM Chat] Stream subscription set up, sending prompt...');

      // Send the prompt and get promptId
      final promptId = await _llama!.sendPromptWithImages(
        formattedPrompt,
        images,
      );

      debugPrint('[VLM Chat] Prompt sent with id: $promptId');
      debugPrint('[VLM Chat] Waiting for completion...');

      // Wait for generation to complete with a timeout
      await _llama!
          .waitForCompletion(promptId)
          .timeout(
            const Duration(minutes: 5),
            onTimeout: () {
              debugPrint('[VLM Chat] TIMEOUT after 5 minutes!');
              throw TimeoutException(
                'Response generation timed out after 5 minutes',
              );
            },
          );

      debugPrint('[VLM Chat] Completion received! Total tokens: $tokenCount');

      // Cancel the subscription
      await subscription.cancel();
      subscription = null;

      stopwatch.stop();

      final responseText = responseBuffer.toString();
      debugPrint(
        '[VLM Chat] Full response ($tokenCount tokens): $responseText',
      );

      // Clean up the response text
      final cleanedResponse = responseText
          .replaceAll('</s>', '')
          .replaceAll('<|end|>', '')
          .replaceAll('<|endoftext|>', '')
          .replaceAll('[/INST]', '')
          .trim();

      // Create assistant message
      final assistantMessage = VLMChatMessage(
        role: 'assistant',
        content: cleanedResponse.isEmpty
            ? 'I could not generate a response. Please try again.'
            : cleanedResponse,
        inferenceTime: stopwatch.elapsed,
      );

      _chatHistory.add(assistantMessage);
      _isGenerating = false;
      notifyListeners();

      return assistantMessage;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _isGenerating = false;
      debugPrint('[VLM Chat] ERROR: $e');
      debugPrint('[VLM Chat] Stack trace: $stackTrace');

      // Cancel subscription if active
      await subscription?.cancel();

      // Add error message to chat
      final errorMessage = VLMChatMessage(
        role: 'assistant',
        content: 'Error: $e',
      );
      _chatHistory.add(errorMessage);
      notifyListeners();

      rethrow;
    }
  }

  /// Clear chat history and start fresh
  void clearChat() {
    _chatHistory.clear();
    _currentImage = null;
    _cachedLlamaImage = null;
    clearContext();
    notifyListeners();
  }

  /// Release model resources
  @override
  void dispose() {
    _tokenController.close();
    // Dispose llama_cpp_dart resources
    if (_llama != null) {
      _llama!.dispose();
      _llama = null;
    }
    _isModelLoaded = false;
    _status = VLMStatus.uninitialized;
    super.dispose();
  }

  /// Delete downloaded models to free up storage
  Future<void> deleteModels() async {
    if (_status == VLMStatus.ready) {
      dispose();
    }

    final dir = await _modelsDir;
    final modelFile = File('${dir.path}/$_modelFileName');
    final mmProjFile = File('${dir.path}/$_mmProjFileName');

    if (await modelFile.exists()) {
      await modelFile.delete();
    }
    if (await mmProjFile.exists()) {
      await mmProjFile.delete();
    }

    _status = VLMStatus.uninitialized;
    notifyListeners();
  }
}
