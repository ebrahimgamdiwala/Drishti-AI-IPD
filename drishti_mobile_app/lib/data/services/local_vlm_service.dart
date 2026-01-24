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

  // Model file names - using INT4 quantized for mobile efficiency
  static const String _modelFileName = 'llava-phi-3-mini-int4.gguf';
  static const String _mmProjFileName = 'llava-phi-3-mini-mmproj-f16.gguf';

  // Hugging Face URLs for model download
  static const String _modelUrl =
      'https://huggingface.co/xtuner/llava-phi-3-mini-gguf/resolve/main/llava-phi-3-mini-int4.gguf';
  static const String _mmProjUrl =
      'https://huggingface.co/xtuner/llava-phi-3-mini-gguf/resolve/main/llava-phi-3-mini-mmproj-f16.gguf';

  // Approximate file sizes for progress calculation
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

      // Download main model
      onProgress?.call(0.0, 'Downloading LLaVA Phi-3 model...');
      await _downloadFile(_modelUrl, modelPath, _modelSizeBytes, (progress) {
        _loadProgress = progress * 0.7; // Model is 70% of total
        onProgress?.call(
          _loadProgress,
          'Downloading model: ${(progress * 100).toStringAsFixed(1)}%',
        );
        notifyListeners();
      });

      // Download multimodal projector
      onProgress?.call(0.7, 'Downloading vision projector...');
      await _downloadFile(_mmProjUrl, mmProjPath, _mmProjSizeBytes, (progress) {
        _loadProgress = 0.7 + (progress * 0.3); // mmproj is 30% of total
        onProgress?.call(
          _loadProgress,
          'Downloading projector: ${(progress * 100).toStringAsFixed(1)}%',
        );
        notifyListeners();
      });

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
  Future<void> _downloadFile(
    String url,
    String savePath,
    int expectedSize,
    void Function(double progress) onProgress,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final file = File(savePath);
      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        downloaded += chunk.length;
        onProgress(downloaded / expectedSize);
      }

      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Initialize the VLM engine
  ///
  /// This loads the model into memory. Should be called after models are downloaded.
  Future<void> initialize({VLMProgressCallback? onProgress}) async {
    if (_status == VLMStatus.ready) return;

    _status = VLMStatus.loading;
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

      onProgress?.call(0.1, 'Initializing model parameters...');
      _loadProgress = 0.1;
      notifyListeners();

      // Configure model parameters for mobile efficiency
      final modelParams = ModelParams()
        ..nGpuLayers =
            0 // CPU only for mobile compatibility
        ..useMemorymap = true
        ..useMemoryLock = false;

      // Configure context parameters
      final contextParams = ContextParams()
        ..nCtx =
            2048 // Context window size
        ..nBatch = 512
        ..nThreads =
            Platform.numberOfProcessors ~/
            2 // Use half of available cores
        ..nThreadsBatch = Platform.numberOfProcessors ~/ 2;

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
        verbose: kDebugMode,
      );

      // Create LlamaParent for isolate-based inference (non-blocking)
      // LlamaParent requires the loadCommand as constructor argument
      _llama = LlamaParent(loadCommand);

      onProgress?.call(0.5, 'Loading vision projector...');
      _loadProgress = 0.5;
      notifyListeners();

      // Initialize the isolate and load the model
      await _llama!.init();
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
      // LLaVA uses a special format: <image>\nUSER: {prompt}\nASSISTANT:
      final formattedPrompt = '<image>\nUSER: $prompt\nASSISTANT:';

      // Use sendPromptWithImages for multimodal inference
      // This returns a Future<String> with the complete response
      final responseText = await _llama!.sendPromptWithImages(formattedPrompt, [
        image,
      ]);

      stopwatch.stop();

      // Clean up the response text
      final cleanedResponse = responseText
          .replaceAll('</s>', '')
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

      // Build the prompt with image
      final formattedPrompt = '<image>\nUSER: $prompt\nASSISTANT:';

      // Use sendPromptWithImages for multimodal inference
      final responseText = await _llama!.sendPromptWithImages(formattedPrompt, [
        image,
      ]);

      stopwatch.stop();

      // Clean up the response text
      final cleanedResponse = responseText
          .replaceAll('</s>', '')
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
    await _llama?.stop();
  }

  /// Clear the context/conversation history
  void clearContext() {
    // Clear messages if using chat history
    _llama?.messages.clear();
  }

  /// Release model resources
  @override
  void dispose() {
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
