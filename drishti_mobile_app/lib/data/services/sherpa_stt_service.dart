/// Sherpa-ONNX Speech-to-Text Service
///
/// High-accuracy on-device speech recognition using OpenAI Whisper
/// and Silero VAD (Voice Activity Detection). Replaces the unreliable
/// platform STT (speech_to_text plugin) with a robust, offline-capable,
/// noise-resistant solution.
///
/// Architecture:
///   [Microphone] → PCM 16kHz → [Silero VAD] → speech segments → [Whisper] → text
///
/// Models:
///   - Whisper small.en (int8 quantized) — ~150MB, best accuracy/size for mobile
///   - Silero VAD v4 — ~2MB, detects speech vs silence/noise
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:record/record.dart';

/// Model file URLs — hosted on HuggingFace / GitHub (sherpa-onnx official releases)
class _ModelUrls {
  static const String _whisperBase =
      'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small.en/resolve/main';
  static const String whisperEncoder =
      '$_whisperBase/small.en-encoder.int8.onnx';
  static const String whisperDecoder =
      '$_whisperBase/small.en-decoder.int8.onnx';
  static const String whisperTokens = '$_whisperBase/small.en-tokens.txt';
  static const String sileroVad =
      'https://raw.githubusercontent.com/snakers4/silero-vad/v4.0/files/silero_vad.onnx';
}

/// Model file info for download tracking
class _ModelFile {
  final String url;
  final String filename;
  final int approximateSizeBytes;

  const _ModelFile(this.url, this.filename, this.approximateSizeBytes);
}

/// Speech recognition result with metadata
class SttResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final Duration audioDuration;

  const SttResult({
    required this.text,
    this.isFinal = true,
    this.confidence = 1.0,
    this.audioDuration = Duration.zero,
  });

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => text.trim().isNotEmpty;
}

/// Sherpa-ONNX based Speech-to-Text service
///
/// Provides high-accuracy, noise-robust, fully on-device speech recognition.
/// Uses Whisper small.en for transcription and Silero VAD for speech detection.
class SherpaSTTService {
  // Singleton
  static final SherpaSTTService _instance = SherpaSTTService._internal();
  factory SherpaSTTService() => _instance;
  SherpaSTTService._internal();

  // === State ===
  bool _isInitialized = false;
  bool _isModelsReady = false;
  bool _isListening = false;
  bool _isDownloading = false;

  // === Models ===
  sherpa.OfflineRecognizer? _recognizer;
  sherpa.VoiceActivityDetector? _vad;

  // === Audio Recording ===
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSubscription;

  // === Model paths ===
  String? _modelDir;
  String? _encoderPath;
  String? _decoderPath;
  String? _tokensPath;
  String? _vadModelPath;

  // === Audio buffer for VAD + recognition ===
  final List<double> _speechBuffer = [];
  bool _speechDetected = false;
  int _silenceFrames = 0;
  DateTime? _speechStartTime;

  // === Configuration ===
  static const int sampleRate = 16000;
  static const int _vadWindowSize = 512; // Silero VAD window
  static const int _maxSilenceFrames = 24; // ~750ms silence to end utterance
  static const int _minSpeechFrames = 3; // ~100ms minimum speech
  static const double _vadThreshold = 0.35; // Lower = more sensitive to speech
  static const int _maxRecordingSeconds = 30;

  // === Streams ===
  final _audioLevelController = StreamController<double>.broadcast();
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  // === Download progress ===
  final _downloadProgressController = StreamController<double>.broadcast();
  Stream<double> get downloadProgressStream =>
      _downloadProgressController.stream;

  // === Public getters ===
  bool get isInitialized => _isInitialized;
  bool get isModelsReady => _isModelsReady;
  bool get isListening => _isListening;
  bool get isDownloading => _isDownloading;

  // === Model files ===
  static const List<_ModelFile> _modelFiles = [
    _ModelFile(
      _ModelUrls.whisperEncoder,
      'small.en-encoder.int8.onnx',
      95000000,
    ),
    _ModelFile(
      _ModelUrls.whisperDecoder,
      'small.en-decoder.int8.onnx',
      55000000,
    ),
    _ModelFile(_ModelUrls.whisperTokens, 'small.en-tokens.txt', 200000),
    _ModelFile(_ModelUrls.sileroVad, 'silero_vad.onnx', 2000000),
  ];

  /// Initialize the service — checks for models, sets up paths
  Future<bool> initialize() async {
    if (_isInitialized) return _isModelsReady;

    try {
      debugPrint('[SherpaSTT] Initializing...');

      // REQUIRED: load the native sherpa-onnx shared library before any usage
      sherpa.initBindings();
      debugPrint('[SherpaSTT] Native bindings initialized');

      // Set up model directory
      final appDir = await getApplicationDocumentsDirectory();
      _modelDir = '${appDir.path}/sherpa_onnx_models';
      await Directory(_modelDir!).create(recursive: true);

      _encoderPath = '$_modelDir/small.en-encoder.int8.onnx';
      _decoderPath = '$_modelDir/small.en-decoder.int8.onnx';
      _tokensPath = '$_modelDir/small.en-tokens.txt';
      _vadModelPath = '$_modelDir/silero_vad.onnx';

      // Check if models exist
      _isModelsReady = await _checkModelsExist();
      if (_isModelsReady) {
        debugPrint('[SherpaSTT] Models found, initializing recognizer...');
        await _initRecognizer();
      } else {
        debugPrint('[SherpaSTT] Models not found, download required');
      }

      _isInitialized = true;
      debugPrint('[SherpaSTT] Initialized (models ready: $_isModelsReady)');
      return _isModelsReady;
    } catch (e) {
      debugPrint('[SherpaSTT] Initialization error: $e');
      return false;
    }
  }

  /// Check if all model files exist and have reasonable size
  Future<bool> _checkModelsExist() async {
    for (final model in _modelFiles) {
      final file = File('$_modelDir/${model.filename}');
      if (!await file.exists()) {
        debugPrint('[SherpaSTT] Missing model: ${model.filename}');
        return false;
      }
      final size = await file.length();
      // Check that file is at least 50% of expected size (sanity check)
      if (size < model.approximateSizeBytes * 0.5) {
        debugPrint(
          '[SherpaSTT] Model ${model.filename} seems corrupted (size: $size)',
        );
        await file.delete();
        return false;
      }
    }
    return true;
  }

  /// Download all required models with progress tracking
  Future<bool> downloadModels({
    Function(double progress, String status)? onProgress,
  }) async {
    if (_isModelsReady) return true;
    if (_isDownloading) return false;
    if (_modelDir == null) await initialize();

    _isDownloading = true;
    final dio = Dio();

    try {
      int totalBytes = 0;
      int downloadedBytes = 0;

      // Calculate total size
      for (final model in _modelFiles) {
        totalBytes += model.approximateSizeBytes;
      }

      for (int i = 0; i < _modelFiles.length; i++) {
        final model = _modelFiles[i];
        final filePath = '$_modelDir/${model.filename}';
        final file = File(filePath);

        // Skip if already downloaded
        if (await file.exists() &&
            await file.length() > model.approximateSizeBytes * 0.5) {
          downloadedBytes += model.approximateSizeBytes;
          final progress = downloadedBytes / totalBytes;
          onProgress?.call(
            progress,
            'Skipping ${model.filename} (already exists)',
          );
          _downloadProgressController.add(progress);
          continue;
        }

        debugPrint('[SherpaSTT] Downloading ${model.filename}...');
        onProgress?.call(
          downloadedBytes / totalBytes,
          'Downloading ${model.filename}...',
        );

        try {
          await dio.download(
            model.url,
            filePath,
            options: Options(followRedirects: true, maxRedirects: 5),
            onReceiveProgress: (received, total) {
              if (total > 0) {
                final fileProgress = received / total;
                final overallProgress =
                    (downloadedBytes +
                        (model.approximateSizeBytes * fileProgress)) /
                    totalBytes;
                _downloadProgressController.add(overallProgress);
                onProgress?.call(
                  overallProgress,
                  'Downloading ${model.filename}... ${(fileProgress * 100).toStringAsFixed(0)}%',
                );
              }
            },
          );
          downloadedBytes += model.approximateSizeBytes;
        } catch (e) {
          debugPrint('[SherpaSTT] Failed to download ${model.filename}: $e');
          // Clean up partial download
          if (await file.exists()) await file.delete();
          onProgress?.call(-1, 'Failed to download ${model.filename}');
          _isDownloading = false;
          return false;
        }
      }

      onProgress?.call(1.0, 'Initializing speech engine...');
      _isModelsReady = await _checkModelsExist();

      if (_isModelsReady) {
        await _initRecognizer();
        onProgress?.call(1.0, 'Ready');
        debugPrint('[SherpaSTT] All models downloaded and initialized');
      }

      _isDownloading = false;
      return _isModelsReady;
    } catch (e) {
      debugPrint('[SherpaSTT] Model download error: $e');
      _isDownloading = false;
      return false;
    } finally {
      dio.close();
    }
  }

  /// Initialize the Whisper recognizer and Silero VAD
  Future<void> _initRecognizer() async {
    try {
      // Free existing instances
      _recognizer?.free();
      _vad?.free();

      // Initialize Whisper offline recognizer
      final recognizerConfig = sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: _encoderPath!,
            decoder: _decoderPath!,
          ),
          tokens: _tokensPath!,
          numThreads: 2,
          provider: 'cpu',
          debug: false,
        ),
      );
      _recognizer = sherpa.OfflineRecognizer(recognizerConfig);
      debugPrint('[SherpaSTT] Whisper recognizer initialized');

      // Initialize Silero VAD
      final vadConfig = sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: _vadModelPath!,
          threshold: _vadThreshold,
          minSilenceDuration: 0.6, // 600ms silence = end of speech
          minSpeechDuration: 0.15, // 150ms minimum speech
          windowSize: _vadWindowSize,
        ),
        sampleRate: sampleRate,
        numThreads: 1,
        debug: false,
      );
      _vad = sherpa.VoiceActivityDetector(
        config: vadConfig,
        bufferSizeInSeconds: _maxRecordingSeconds.toDouble() + 5,
      );
      debugPrint('[SherpaSTT] Silero VAD initialized');
    } catch (e) {
      debugPrint('[SherpaSTT] Failed to initialize recognizer: $e');
      _recognizer = null;
      _vad = null;
      _isModelsReady = false;
      rethrow;
    }
  }

  /// Recognize speech from microphone — one-shot mode
  ///
  /// Listens for speech, waits for silence (end of utterance), then
  /// returns the transcription. Uses VAD to handle background noise.
  ///
  /// Returns the recognized text, or empty string if nothing detected.
  Future<SttResult> recognizeSpeech({
    Duration timeout = const Duration(seconds: 15),
    Duration initialSilenceTimeout = const Duration(seconds: 8),
    Function(String partialText)? onPartialResult,
    Function(bool isSpeechDetected)? onSpeechStatus,
  }) async {
    if (!_isModelsReady || _recognizer == null || _vad == null) {
      debugPrint('[SherpaSTT] Not ready for recognition');
      return const SttResult(text: '', confidence: 0);
    }

    if (_isListening) {
      debugPrint('[SherpaSTT] Already listening, stopping first');
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _isListening = true;
    _speechBuffer.clear();
    _speechDetected = false;
    _silenceFrames = 0;
    _speechStartTime = null;

    // Reset VAD state
    _vad!.clear();

    final completer = Completer<SttResult>();
    Timer? timeoutTimer;
    Timer? initialSilenceTimer;

    try {
      _recorder = AudioRecorder();
      final hasPermission = await _recorder!.hasPermission();
      if (!hasPermission) {
        _isListening = false;
        return const SttResult(text: '', confidence: 0);
      }

      debugPrint('[SherpaSTT] Starting audio recording...');

      // Start audio stream
      final audioStream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          bitRate: sampleRate * 16, // 16-bit mono
        ),
      );

      // Set up timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          debugPrint('[SherpaSTT] Recording timeout reached');
          _finalizeAndComplete(completer);
        }
      });

      // Set up initial silence timeout (give up if no speech at all)
      initialSilenceTimer = Timer(initialSilenceTimeout, () {
        if (!_speechDetected && !completer.isCompleted) {
          debugPrint('[SherpaSTT] No speech detected within initial timeout');
          if (!completer.isCompleted) {
            completer.complete(const SttResult(text: '', confidence: 0));
          }
          stopListening();
        }
      });

      _audioSubscription = audioStream.listen(
        (Uint8List data) {
          if (!_isListening || completer.isCompleted) return;
          _processAudioChunk(data, completer, onSpeechStatus);
        },
        onError: (error) {
          debugPrint('[SherpaSTT] Audio stream error: $error');
          if (!completer.isCompleted) {
            completer.complete(const SttResult(text: '', confidence: 0));
          }
        },
        onDone: () {
          debugPrint('[SherpaSTT] Audio stream ended');
          if (!completer.isCompleted) {
            _finalizeAndComplete(completer);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('[SherpaSTT] Recognition error: $e');
      return const SttResult(text: '', confidence: 0);
    } finally {
      timeoutTimer?.cancel();
      initialSilenceTimer?.cancel();
      await stopListening();
    }
  }

  /// Process a chunk of PCM audio data
  void _processAudioChunk(
    Uint8List data,
    Completer<SttResult> completer,
    Function(bool)? onSpeechStatus,
  ) {
    if (completer.isCompleted) return;

    // Convert PCM16 bytes to Float32 samples [-1.0, 1.0]
    final samples = _pcm16ToFloat32(data);
    if (samples.isEmpty) return;

    // Compute audio level for UI feedback
    double maxLevel = 0;
    for (final s in samples) {
      final abs = s.abs();
      if (abs > maxLevel) maxLevel = abs;
    }
    // Convert to dB-like scale (0-100)
    final level = (maxLevel * 100).clamp(0, 100).toDouble();
    _audioLevelController.add(level);

    // Feed to VAD in windows
    _vad!.acceptWaveform(Float32List.fromList(samples));

    // Check VAD result
    if (_vad!.isDetected()) {
      if (!_speechDetected) {
        debugPrint('[SherpaSTT] Speech detected!');
        _speechDetected = true;
        _speechStartTime = DateTime.now();
        onSpeechStatus?.call(true);
      }
      _silenceFrames = 0;
    } else if (_speechDetected) {
      _silenceFrames++;
    }

    // Collect speech segments from VAD
    while (!_vad!.isEmpty()) {
      final segment = _vad!.front();
      _speechBuffer.addAll(segment.samples);
      _vad!.pop();
    }

    // Check if speech has ended (sufficient silence after speech)
    if (_speechDetected && _silenceFrames >= _maxSilenceFrames) {
      debugPrint(
        '[SherpaSTT] End of speech detected (silence frames: $_silenceFrames)',
      );
      onSpeechStatus?.call(false);
      _finalizeAndComplete(completer);
    }
  }

  /// Finalize recognition and complete the future
  void _finalizeAndComplete(Completer<SttResult> completer) {
    if (completer.isCompleted) return;

    if (_speechBuffer.isEmpty) {
      debugPrint('[SherpaSTT] No speech audio collected');
      completer.complete(const SttResult(text: '', confidence: 0));
      return;
    }

    debugPrint(
      '[SherpaSTT] Running Whisper on ${_speechBuffer.length} samples '
      '(${(_speechBuffer.length / sampleRate).toStringAsFixed(1)}s audio)',
    );

    try {
      final audioDuration = Duration(
        milliseconds: (_speechBuffer.length / sampleRate * 1000).round(),
      );

      // Run Whisper inference
      final stream = _recognizer!.createStream();
      stream.acceptWaveform(
        samples: Float32List.fromList(_speechBuffer),
        sampleRate: sampleRate,
      );
      _recognizer!.decode(stream);
      final result = _recognizer!.getResult(stream);
      stream.free();

      final text = result.text.trim();
      debugPrint('[SherpaSTT] Whisper result: "$text"');

      completer.complete(
        SttResult(
          text: text,
          isFinal: true,
          confidence: text.isNotEmpty ? 0.95 : 0.0,
          audioDuration: audioDuration,
        ),
      );
    } catch (e) {
      debugPrint('[SherpaSTT] Whisper inference error: $e');
      completer.complete(const SttResult(text: '', confidence: 0));
    }
  }

  /// Start continuous recognition — for hotword detection
  ///
  /// Continuously listens, runs VAD, and when speech is detected,
  /// transcribes it and calls the callback. Keeps running until stopped.
  Future<void> startContinuousRecognition({
    required Function(String text) onResult,
    Function(bool isSpeechDetected)? onSpeechStatus,
    Function(double level)? onAudioLevel,
  }) async {
    if (!_isModelsReady || _recognizer == null || _vad == null) {
      debugPrint('[SherpaSTT] Not ready for continuous recognition');
      return;
    }

    if (_isListening) {
      debugPrint('[SherpaSTT] Already listening, stopping first');
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _isListening = true;
    _speechBuffer.clear();
    _speechDetected = false;
    _silenceFrames = 0;
    _speechStartTime = null;
    _vad!.clear();

    try {
      _recorder = AudioRecorder();
      final hasPermission = await _recorder!.hasPermission();
      if (!hasPermission) {
        debugPrint(
          '[SherpaSTT] No audio permission for continuous recognition',
        );
        _isListening = false;
        return;
      }

      debugPrint('[SherpaSTT] Starting continuous recognition...');

      final audioStream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          bitRate: sampleRate * 16,
        ),
      );

      _audioSubscription = audioStream.listen(
        (Uint8List data) {
          if (!_isListening) return;
          _processContinuousAudioChunk(
            data,
            onResult,
            onSpeechStatus,
            onAudioLevel,
          );
        },
        onError: (error) {
          debugPrint('[SherpaSTT] Continuous audio error: $error');
          // Try to restart after error
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isListening) {
              startContinuousRecognition(
                onResult: onResult,
                onSpeechStatus: onSpeechStatus,
                onAudioLevel: onAudioLevel,
              );
            }
          });
        },
      );
    } catch (e) {
      debugPrint('[SherpaSTT] Failed to start continuous recognition: $e');
      _isListening = false;
    }
  }

  /// Process audio in continuous mode
  void _processContinuousAudioChunk(
    Uint8List data,
    Function(String text) onResult,
    Function(bool)? onSpeechStatus,
    Function(double)? onAudioLevel,
  ) {
    final samples = _pcm16ToFloat32(data);
    if (samples.isEmpty) return;

    // Audio level
    double maxLevel = 0;
    for (final s in samples) {
      final abs = s.abs();
      if (abs > maxLevel) maxLevel = abs;
    }
    final level = (maxLevel * 100).clamp(0, 100).toDouble();
    _audioLevelController.add(level);
    onAudioLevel?.call(level);

    // Feed to VAD
    _vad!.acceptWaveform(Float32List.fromList(samples));

    if (_vad!.isDetected()) {
      if (!_speechDetected) {
        debugPrint('[SherpaSTT] [Continuous] Speech detected');
        _speechDetected = true;
        _speechStartTime = DateTime.now();
        onSpeechStatus?.call(true);
      }
      _silenceFrames = 0;
    } else if (_speechDetected) {
      _silenceFrames++;
    }

    // Collect speech segments
    while (!_vad!.isEmpty()) {
      final segment = _vad!.front();
      _speechBuffer.addAll(segment.samples);
      _vad!.pop();
    }

    // Check for end of utterance
    if (_speechDetected && _silenceFrames >= _maxSilenceFrames) {
      debugPrint('[SherpaSTT] [Continuous] End of utterance');
      onSpeechStatus?.call(false);

      if (_speechBuffer.isNotEmpty) {
        // Transcribe the speech segment
        try {
          final stream = _recognizer!.createStream();
          stream.acceptWaveform(
            samples: Float32List.fromList(_speechBuffer),
            sampleRate: sampleRate,
          );
          _recognizer!.decode(stream);
          final result = _recognizer!.getResult(stream);
          stream.free();

          final text = result.text.trim();
          if (text.isNotEmpty) {
            debugPrint('[SherpaSTT] [Continuous] Transcription: "$text"');
            onResult(text);
          }
        } catch (e) {
          debugPrint('[SherpaSTT] [Continuous] Transcription error: $e');
        }
      }

      // Reset for next utterance
      _speechBuffer.clear();
      _speechDetected = false;
      _silenceFrames = 0;
      _speechStartTime = null;
    }

    // Safety: limit buffer size (prevent memory issues from very long speech)
    if (_speechBuffer.length > sampleRate * _maxRecordingSeconds) {
      debugPrint('[SherpaSTT] [Continuous] Buffer overflow, transcribing...');
      _silenceFrames = _maxSilenceFrames; // Force end of utterance
    }
  }

  /// Stop listening and clean up audio recording
  Future<void> stopListening() async {
    _isListening = false;
    _speechDetected = false;
    _silenceFrames = 0;

    try {
      await _audioSubscription?.cancel();
      _audioSubscription = null;
    } catch (e) {
      debugPrint('[SherpaSTT] Error cancelling audio subscription: $e');
    }

    try {
      if (_recorder != null) {
        await _recorder!.stop();
        await _recorder!.dispose();
        _recorder = null;
      }
    } catch (e) {
      debugPrint('[SherpaSTT] Error stopping recorder: $e');
    }
  }

  /// Convert PCM16 bytes (little-endian) to Float32 samples [-1.0, 1.0]
  List<double> _pcm16ToFloat32(Uint8List bytes) {
    if (bytes.isEmpty) return [];

    // PCM16: 2 bytes per sample. Drop trailing odd byte if present.
    final evenLength = bytes.length & ~1; // round down to even
    if (evenLength == 0) return [];

    // Copy into a fresh Uint8List to guarantee 0 offset alignment,
    // then view as Int16List (avoids RangeError on odd offsetInBytes).
    final aligned = Uint8List(evenLength)..setRange(0, evenLength, bytes);
    final int16Data = aligned.buffer.asInt16List();

    final numSamples = int16Data.length;
    final result = List<double>.filled(numSamples, 0);
    for (int i = 0; i < numSamples; i++) {
      result[i] = int16Data[i] / 32768.0;
    }
    return result;
  }

  /// Get total model download size in bytes
  int get totalModelSize {
    int total = 0;
    for (final model in _modelFiles) {
      total += model.approximateSizeBytes;
    }
    return total;
  }

  /// Get human-readable model size string
  String get modelSizeString {
    final mb = totalModelSize / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  /// Delete all downloaded models (for cache management)
  Future<void> deleteModels() async {
    await stopListening();
    _recognizer?.free();
    _vad?.free();
    _recognizer = null;
    _vad = null;
    _isModelsReady = false;

    if (_modelDir != null) {
      final dir = Directory(_modelDir!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    debugPrint('[SherpaSTT] Models deleted');
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await stopListening();
    _recognizer?.free();
    _vad?.free();
    _recognizer = null;
    _vad = null;
    _audioLevelController.close();
    _downloadProgressController.close();
    debugPrint('[SherpaSTT] Service disposed');
  }
}
