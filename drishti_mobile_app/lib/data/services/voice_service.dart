/// Drishti App - Voice Service
///
/// Text-to-speech and speech-to-text for accessibility.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _ttsInitialized = false;
  bool _sttInitialized = false;
  bool _isListening = false;

  double _speechRate = 0.5; // 0.0 to 1.0
  double _pitch = 1.0; // 0.5 to 2.0
  double _volume = 1.0; // 0.0 to 1.0

  /// Initialize TTS engine
  Future<void> initTts() async {
    if (_ttsInitialized) return;

    if (kIsWeb) {
      _ttsInitialized = true; // No-op on web (plugin not available)
      return;
    }

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Set completion handler
      _tts.setCompletionHandler(() {
        // Speech completed
      });

      _ttsInitialized = true;
    } catch (e) {
      // TTS initialization failed
    }
  }

  // Audio Level Stream
  final _audioLevelController = StreamController<double>.broadcast();
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  /// Initialize STT engine
  Future<bool> initStt() async {
    if (_sttInitialized) return true;

    if (kIsWeb) {
      _sttInitialized = false;
      return false; // Speech to text not supported on web by this plugin
    }

    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) {
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _sttInitialized;
    } catch (e) {
      return false;
    }
  }

  // === Text-to-Speech ===

  /// Speak text
  Future<void> speak(String text) async {
    if (!_ttsInitialized) await initTts();
    if (kIsWeb) return;

    // Stop any current speech
    await _tts.stop();

    // Speak new text
    await _tts.speak(text);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (kIsWeb) return;
    await _tts.stop();
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

  // === Speech-to-Text ===

  /// Check if listening
  bool get isListening => _isListening;

  /// Check if STT is available
  bool get isSttAvailable => _sttInitialized && _stt.isAvailable;

  /// Start listening for speech
  Future<void> startListening({
    required Function(String text) onResult,
    Function(String error)? onError,
    Duration? listenFor,
  }) async {
    if (!_sttInitialized) {
      final initialized = await initStt();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;

    try {
      if (kIsWeb) {
        onError?.call('Speech recognition not available on web');
        _isListening = false;
        return;
      }
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening = false;
          }
        },
        onSoundLevelChange: (level) {
          _audioLevelController.add(level);
        },
        listenFor: listenFor ?? const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      onError?.call('Failed to start listening');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    if (kIsWeb) return;
    await _stt.stop();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    _isListening = false;
    if (kIsWeb) return;
    await _stt.cancel();
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
      await _stt.stop();
    }
    _audioLevelController.close();
  }
}
