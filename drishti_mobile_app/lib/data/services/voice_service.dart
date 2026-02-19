/// Drishti App - Voice Service
///
/// Text-to-speech and speech-to-text for accessibility.
/// STT powered by on-device Whisper (via sherpa-onnx) with Silero VAD
/// for noise-robust, accurate speech recognition.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'sherpa_stt_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final SherpaSTTService _sherpa = SherpaSTTService();

  bool _ttsInitialized = false;
  bool _sttInitialized = false;
  bool _isListening = false;
  bool _isHotwordListening = false;
  bool _hotwordDetected = false;
  bool _isContinuousListening = false;
  bool _isSpeaking = false;
  Completer<void>? _ttsCompleter;

  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _currentLanguage = 'en-IN';

  // Hotword configuration
  static const String hotword = 'hey vision';
  static const List<String> hotwordVariants = [
    'hey vision',
    'a vision',
    'hey vishon',
    'hey vission',
    'hey vishun',
    'he vision',
    'hay vision',
    'hey vison',
    'vision',
  ];
  Function()? _onHotwordDetected;
  Function(String text)? _onContinuousSpeech;

  // Audio Level Stream — from sherpa STT
  Stream<double> get audioLevelStream => _sherpa.audioLevelStream;

  // Model download progress
  Stream<double> get downloadProgressStream => _sherpa.downloadProgressStream;
  bool get isModelsReady => _sherpa.isModelsReady;
  bool get isDownloading => _sherpa.isDownloading;
  String get modelSizeString => _sherpa.modelSizeString;

  /// Initialize TTS engine
  Future<void> initTts() async {
    if (_ttsInitialized) return;

    if (kIsWeb) {
      _ttsInitialized = true;
      return;
    }

    try {
      await _tts.setLanguage(_currentLanguage);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      _tts.setCompletionHandler(() {
        debugPrint('[VoiceService] TTS completed');
        _isSpeaking = false;
        _ttsCompleter?.complete();
        _ttsCompleter = null;
      });

      _tts.setStartHandler(() {
        debugPrint('[VoiceService] TTS started');
        _isSpeaking = true;
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[VoiceService] TTS error: $msg');
        _isSpeaking = false;
        _ttsCompleter?.complete();
        _ttsCompleter = null;
      });

      _ttsInitialized = true;
    } catch (e) {
      debugPrint('[VoiceService] TTS init error: $e');
    }
  }

  /// Set TTS language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    if (_ttsInitialized && !kIsWeb) {
      await _tts.setLanguage(languageCode);
    }
  }

  /// Get current language code (e.g. 'hi-IN')
  String get currentLanguage => _currentLanguage;

  /// Two-letter language code extracted from [currentLanguage] (e.g. 'hi')
  String get currentLanguageCode => _currentLanguage.split('-').first;

  /// Speak in the currently active language, falling back to [en] if no
  /// translation is provided for the current language.
  ///
  /// Example:
  /// ```dart
  /// await voiceService.speakLocalized(
  ///   en: 'Hello',
  ///   hi: '\u0928\u092e\u0938\u094d\u0924\u0947',
  ///   ta: '\u0bb5\u0ba3\u0b95\u0bcd\u0b95\u0bae\u0bcd',
  /// );
  /// ```
  Future<void> speakLocalized({
    required String en,
    String? hi,
    String? ta,
    String? te,
    String? bn,
  }) async {
    final text =
        {'hi': hi, 'ta': ta, 'te': te, 'bn': bn}[currentLanguageCode] ?? en;
    await speak(text);
  }

  /// Initialize STT engine (sherpa-onnx Whisper + Silero VAD)
  Future<bool> initStt() async {
    if (_sttInitialized) return true;
    if (kIsWeb) return false;

    try {
      debugPrint('[VoiceService] Initializing Sherpa-ONNX STT...');
      final modelsReady = await _sherpa.initialize();

      if (modelsReady) {
        _sttInitialized = true;
        debugPrint(
          '[VoiceService] ✅ Sherpa-ONNX STT ready (Whisper + Silero VAD)',
        );
        return true;
      } else {
        debugPrint('[VoiceService] ⚠️ Models not downloaded yet');
        _sttInitialized = true;
        return false;
      }
    } catch (e) {
      debugPrint('[VoiceService] STT init error: $e');
      return false;
    }
  }

  /// Download STT models (call this on first launch or from settings)
  Future<bool> downloadModels({
    Function(double progress, String status)? onProgress,
  }) async {
    return await _sherpa.downloadModels(onProgress: onProgress);
  }

  // === Text-to-Speech ===

  /// Speak text and wait for completion
  Future<void> speak(String text) async {
    if (!_ttsInitialized) await initTts();
    if (kIsWeb) return;

    // Stop any current speech
    await _tts.stop();
    _isSpeaking = false;
    _ttsCompleter?.complete();
    _ttsCompleter = null;

    // Stop listening while speaking to prevent self-voice pickup
    final wasListening = _isListening;
    if (wasListening) {
      debugPrint('[VoiceService] 🔇 Stopping microphone for TTS');
      await _sherpa.stopListening();
      _isListening = false;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Create new completer for this speech
    _ttsCompleter = Completer<void>();
    _isSpeaking = true;

    // Speak new text
    await _tts.speak(text);

    // Wait for TTS to complete
    try {
      await _ttsCompleter!.future.timeout(
        Duration(seconds: text.length ~/ 10 + 5), // Estimate max duration
        onTimeout: () {
          debugPrint('[VoiceService] TTS timeout, assuming complete');
          _isSpeaking = false;
        },
      );
    } catch (e) {
      debugPrint('[VoiceService] TTS wait error: $e');
      _isSpeaking = false;
    }

    // Add small buffer after TTS completes
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint('[VoiceService] 🔊 TTS finished, microphone can resume');
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (kIsWeb) return;
    await _tts.stop();
    _isSpeaking = false;
    _ttsCompleter?.complete();
    _ttsCompleter = null;
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (kIsWeb) return;
    await _tts.setSpeechRate(_speechRate);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (kIsWeb) return;
    await _tts.setPitch(_pitch);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (kIsWeb) return;
    await _tts.setVolume(_volume);
  }

  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  // === Speech-to-Text (Sherpa-ONNX Whisper) ===

  /// Check if listening
  bool get isListening => _isListening;

  /// Check if STT is available
  bool get isSttAvailable => _sttInitialized && _sherpa.isModelsReady;

  /// Start listening for speech — powered by Whisper + Silero VAD
  ///
  /// Unlike the old platform STT, this:
  /// - Works reliably with background noise (Silero VAD filters it)
  /// - Runs fully on-device (no internet needed)
  /// - Doesn't give up after 3 retries — keeps listening until timeout
  /// - Uses Whisper for high-accuracy transcription
  Future<void> startListening({
    required Function(String text) onResult,
    Function(String error)? onError,
    Duration? listenFor,
    int maxRetries = 3, // kept for API compatibility, not used internally
    /// When false, the auto-resume of hotword listening after this call is
    /// suppressed. Pass false for every call inside a multi-step voice flow
    /// so that only the explicit resumeHotwordListening() at the end of the
    /// flow restarts the hotword cycle — avoiding race conditions.
    bool autoResumeHotword = true,
  }) async {
    debugPrint('[VoiceService] startListening called (Sherpa-ONNX)');

    // Pause hotword listening
    final wasHotwordListening = _isHotwordListening;
    if (_isHotwordListening) {
      debugPrint('[VoiceService] Pausing hotword listening for voice command');
      _isContinuousListening = false;
      await _sherpa.stopListening();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!_sherpa.isModelsReady) {
      onError?.call(
        'Speech models not downloaded. Please download from Settings.',
      );
      return;
    }

    // Wait for any ongoing TTS to complete
    if (_isSpeaking) {
      debugPrint(
        '[VoiceService] Waiting for TTS to complete before listening...',
      );
      int waitCount = 0;
      while (_isSpeaking && waitCount < 15) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      // Extra buffer after TTS
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _isListening = true;

    try {
      debugPrint('[VoiceService] 🎤 Starting Whisper recognition...');

      final result = await _sherpa.recognizeSpeech(
        timeout: listenFor ?? const Duration(seconds: 15),
        initialSilenceTimeout: const Duration(seconds: 8),
        onSpeechStatus: (detected) {
          if (detected) {
            debugPrint('[VoiceService] 🗣️ Speech detected by VAD');
          } else {
            debugPrint('[VoiceService] 🤫 Speech ended (VAD)');
          }
        },
      );

      _isListening = false;

      if (result.isNotEmpty) {
        debugPrint('[VoiceService] ✅ Whisper result: "${result.text}"');
        onResult(result.text);
      } else {
        debugPrint('[VoiceService] ℹ️ No speech detected');
        onError?.call('No speech detected. Please try again.');
      }

      // Auto-resume hotword listening (suppressed for multi-step flows)
      if (autoResumeHotword && wasHotwordListening) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!_isContinuousListening && _onHotwordDetected != null) {
            debugPrint('[VoiceService] Auto-resuming hotword listening');
            resumeHotwordListening();
          }
        });
      }
    } catch (e) {
      debugPrint('[VoiceService] ❌ Recognition error: $e');
      _isListening = false;
      onError?.call('Speech recognition error. Please try again.');

      if (autoResumeHotword && wasHotwordListening) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!_isContinuousListening && _onHotwordDetected != null) {
            resumeHotwordListening();
          }
        });
      }
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    if (kIsWeb) return;
    await _sherpa.stopListening();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    _isListening = false;
    if (kIsWeb) return;
    await _sherpa.stopListening();
  }

  // === Accessibility Helpers ===

  /// Announce for screen readers
  Future<void> announce(String message) async {
    await speak(message);
  }

  /// Read alert with appropriate urgency
  Future<void> readAlert(String description, String severity) async {
    String prefix;
    switch (severity.toLowerCase()) {
      case 'critical':
        prefix = 'Critical alert! ';
        break;
      case 'high':
        prefix = 'Warning! ';
        break;
      case 'medium':
        prefix = 'Attention. ';
        break;
      default:
        prefix = '';
    }
    await speak('$prefix$description');
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (!kIsWeb) {
      await _tts.stop();
      await _sherpa.stopListening();
    }
    _isContinuousListening = false;
    _isSpeaking = false;
    _ttsCompleter?.complete();
    _ttsCompleter = null;
    await _sherpa.dispose();
  }

  // === Continuous Listening with Hotword Detection ===
  // Now powered by Whisper + VAD — vastly more reliable than platform STT

  /// Start listening for hotword with continuous mode
  ///
  /// Uses Sherpa-ONNX continuous recognition with VAD to detect speech,
  /// then Whisper to transcribe and check for the hotword.
  /// Unlike the old approach (running platform STT 24/7), this:
  /// - Only runs Whisper when VAD detects actual speech
  /// - Handles background noise gracefully
  /// - Doesn't have the constant restart/retry loops
  /// - Much lower battery usage
  Future<void> startHotwordListening({
    required Function() onHotwordDetected,
    Function(String text)? onContinuousSpeech,
  }) async {
    debugPrint(
      '[VoiceService] 🎧 Starting continuous hotword listening (Sherpa-ONNX)',
    );

    if (!_sherpa.isModelsReady) {
      debugPrint(
        '[VoiceService] ❌ Models not ready, cannot start hotword listening',
      );
      return;
    }

    _onHotwordDetected = onHotwordDetected;
    _onContinuousSpeech = onContinuousSpeech;
    _isHotwordListening = true;
    _isContinuousListening = true;
    _hotwordDetected = false;

    await _startContinuousListenCycle();
  }

  /// Start the continuous listen cycle using Sherpa-ONNX
  Future<void> _startContinuousListenCycle() async {
    if (!_isContinuousListening || kIsWeb) return;

    if (!_sherpa.isModelsReady) {
      debugPrint('[VoiceService] Models not ready for continuous listening');
      return;
    }

    debugPrint('[VoiceService] 🎧 Starting Sherpa continuous listen cycle...');

    await _sherpa.startContinuousRecognition(
      onResult: (String text) {
        _handleContinuousSpeechResult(text);
      },
      onSpeechStatus: (bool detected) {
        if (detected) {
          debugPrint('[VoiceService] [Hotword] Speech detected');
        }
      },
    );
  }

  /// Handle speech results in continuous mode (check for hotword)
  void _handleContinuousSpeechResult(String text) {
    final normalized = text.toLowerCase().trim();

    if (normalized.isEmpty) return;

    debugPrint('[VoiceService] 🎤 Heard: "$normalized"');

    // Notify about continuous speech
    _onContinuousSpeech?.call(normalized);

    // Check for hotword
    bool hotwordFound = false;
    for (final variant in hotwordVariants) {
      if (normalized.contains(variant)) {
        hotwordFound = true;
        break;
      }
    }

    // Also check with fuzzy matching (Whisper handles most variation, but just in case)
    if (!hotwordFound) {
      hotwordFound = _fuzzyHotwordMatch(normalized);
    }

    if (hotwordFound && !_hotwordDetected) {
      debugPrint('[VoiceService] ✅ HOTWORD DETECTED in: "$normalized"');
      _hotwordDetected = true;

      // Stop continuous listening for command processing
      _isContinuousListening = false;
      _sherpa.stopListening();
      _isListening = false;

      // Notify — the callback handles command capture
      Future.delayed(const Duration(milliseconds: 100), () {
        _onHotwordDetected?.call();
      });
    }
  }

  /// Fuzzy hotword matching — handles Whisper transcription variations
  bool _fuzzyHotwordMatch(String text) {
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i] == 'vision' && i > 0) {
        final prev = words[i - 1];
        if (['hey', 'he', 'hay', 'a', 'hey,', 'the'].contains(prev)) {
          return true;
        }
      }
      if (i < words.length - 1) {
        final pair = '${words[i]} ${words[i + 1]}';
        if (_levenshteinDistance(pair, 'hey vision') <= 2) {
          return true;
        }
      }
    }
    return false;
  }

  /// Simple Levenshtein distance for fuzzy matching
  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List.generate(b.length + 1, (i) => i);
    List<int> curr = List.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[b.length];
  }

  /// Stop hotword listening
  Future<void> stopHotwordListening() async {
    debugPrint('[VoiceService] Stopping continuous hotword listening');
    _isHotwordListening = false;
    _isContinuousListening = false;
    _hotwordDetected = false;
    await _sherpa.stopListening();
    _isListening = false;
  }

  /// Resume hotword listening after voice command processing.
  ///
  /// Always force-resets listening state so this works correctly after
  /// completing a relative flow or any other nested STT session where
  /// [_isContinuousListening] may still be `true`.
  Future<void> resumeHotwordListening() async {
    if (_onHotwordDetected == null) return;

    debugPrint('[VoiceService] 🔄 Force-resuming continuous hotword listening');

    // Force-reset all listening flags so we always restart cleanly,
    // regardless of what happened during nested startListening() calls.
    _isContinuousListening = false;
    _isHotwordListening = false;
    _hotwordDetected = false;
    try {
      await _sherpa.stopListening();
    } catch (_) {}
    _isListening = false;

    // Wait for any TTS to finish
    if (_isSpeaking) {
      debugPrint('[VoiceService] Waiting for TTS to finish before resuming...');
      int waitCount = 0;
      while (_isSpeaking && waitCount < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
    }

    // Buffer to ensure TTS audio has cleared the mic
    await Future.delayed(const Duration(milliseconds: 500));

    _isHotwordListening = true;
    _isContinuousListening = true;
    await _startContinuousListenCycle();
  }

  /// Check if hotword listening is active
  bool get isHotwordListening => _isHotwordListening;

  /// Check if continuous listening is active
  bool get isContinuousListening => _isContinuousListening;

  /// Check if STT is currently listening
  bool get isSttListening => _sherpa.isListening;
}
