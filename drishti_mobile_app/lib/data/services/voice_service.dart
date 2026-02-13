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
  bool _isHotwordListening = false;
  bool _hotwordDetected = false;
  bool _isContinuousListening = false;
  bool _isRestarting = false; // Prevent overlapping restarts
  bool _isSpeaking = false; // Track if TTS is currently speaking
  Timer? _hotwordTimer;
  Timer? _continuousRestartTimer;
  DateTime? _lastRestartTime; // Track last restart to prevent rapid restarts
  Completer<void>? _ttsCompleter; // Track TTS completion

  // Track restart attempts to implement exponential backoff
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 10; // Cap maximum attempts
  static const int _minRestartDelayMs = 1500; // Minimum delay between restarts

  double _speechRate = 0.5; // 0.0 to 1.0
  double _pitch = 1.0; // 0.5 to 2.0
  double _volume = 1.0; // 0.0 to 1.0
  String _currentLanguage = 'en-IN'; // Current TTS language

  // Hotword configuration
  static const String hotword = 'hey vision';
  static const List<String> hotwordVariants = [
    'hey vision',
    'a vision',
    'hey vishon',
    'hey vission',
    'hey vishun',
    'vision',
  ];
  Function()? _onHotwordDetected;
  Function(String text)? _onContinuousSpeech;

  /// Initialize TTS engine
  Future<void> initTts() async {
    if (_ttsInitialized) return;

    if (kIsWeb) {
      _ttsInitialized = true; // No-op on web (plugin not available)
      return;
    }

    try {
      await _tts.setLanguage(_currentLanguage);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Set completion handler
      _tts.setCompletionHandler(() {
        debugPrint('[VoiceService] TTS completed');
        _isSpeaking = false;
        _ttsCompleter?.complete();
        _ttsCompleter = null;
      });

      // Set start handler
      _tts.setStartHandler(() {
        debugPrint('[VoiceService] TTS started');
        _isSpeaking = true;
      });

      // Set error handler
      _tts.setErrorHandler((msg) {
        debugPrint('[VoiceService] TTS error: $msg');
        _isSpeaking = false;
        _ttsCompleter?.complete();
        _ttsCompleter = null;
      });

      _ttsInitialized = true;
    } catch (e) {
      // TTS initialization failed
    }
  }

  /// Set TTS language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    if (_ttsInitialized && !kIsWeb) {
      await _tts.setLanguage(languageCode);
    }
  }

  /// Get current language
  String get currentLanguage => _currentLanguage;

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
          debugPrint('[VoiceService] STT Error: ${error.errorMsg}');
          _isListening = false;

          // Handle specific errors
          if (error.errorMsg == 'error_busy') {
            // STT is busy, wait longer before restart
            debugPrint('[VoiceService] ⚠️ STT busy, increasing backoff...');
            _restartAttempts = (_restartAttempts + 2).clamp(
              0,
              _maxRestartAttempts,
            );
          } else if (error.errorMsg == 'error_no_match') {
            // No speech detected - this is normal, just continue
            debugPrint('[VoiceService] ℹ️ No speech detected (normal)');
          } else if (error.errorMsg == 'error_speech_timeout') {
            // Speech timeout - normal when no one is talking
            debugPrint('[VoiceService] ℹ️ Speech timeout (normal)');
          }

          // Don't trigger restart here - let status handler manage it
        },
        onStatus: (status) {
          debugPrint('[VoiceService] STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            // If we're in continuous mode and not processing a hotword, restart
            if (_isContinuousListening && !_hotwordDetected && !_isRestarting) {
              _scheduleContinuousRestart();
            }
          } else if (status == 'listening') {
            _isListening = true;
            _restartAttempts = 0; // Reset on successful listen
          }
        },
      );
      return _sttInitialized;
    } catch (e) {
      debugPrint('[VoiceService] STT init error: $e');
      return false;
    }
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
    final wasListening = _stt.isListening;
    if (wasListening) {
      debugPrint('[VoiceService] 🔇 Stopping microphone for TTS');
      await _stt.stop();
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
    debugPrint('[VoiceService] startListening called');

    // Store hotword state to resume later
    final wasHotwordListening = _isHotwordListening;

    // Temporarily pause hotword listening when starting regular listening
    if (_isHotwordListening) {
      debugPrint('[VoiceService] Pausing hotword listening for voice command');
      _isContinuousListening = false;
      _continuousRestartTimer?.cancel();
      if (_stt.isListening) {
        await _stt.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    if (!_sttInitialized) {
      final initialized = await initStt();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    // Wait for any ongoing TTS to complete
    if (_isSpeaking) {
      debugPrint('[VoiceService] Waiting for TTS to complete before listening...');
      await Future.delayed(const Duration(milliseconds: 500));
      int waitCount = 0;
      while (_isSpeaking && waitCount < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
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
            
            // Resume hotword listening if it was active before
            if (wasHotwordListening) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!_isContinuousListening && _onHotwordDetected != null) {
                  debugPrint('[VoiceService] Auto-resuming hotword listening');
                  resumeHotwordListening();
                }
              });
            }
          }
        },
        onSoundLevelChange: (level) {
          _audioLevelController.add(level);
        },
        listenFor: listenFor ?? const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      onError?.call('Failed to start listening');
      
      // Resume hotword listening even on error
      if (wasHotwordListening) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isContinuousListening && _onHotwordDetected != null) {
            debugPrint('[VoiceService] Auto-resuming hotword listening after error');
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
    _hotwordTimer?.cancel();
    _continuousRestartTimer?.cancel();
    _isContinuousListening = false;
    _isSpeaking = false;
    _ttsCompleter?.complete();
    _ttsCompleter = null;
    _audioLevelController.close();
  }

  // === Continuous Listening with Hotword Detection ===

  /// Schedule a restart for continuous listening with exponential backoff
  void _scheduleContinuousRestart() {
    // Cancel any existing restart timer
    _continuousRestartTimer?.cancel();

    if (!_isContinuousListening || _hotwordDetected || _isRestarting) {
      return;
    }

    // Check if we're restarting too quickly
    final now = DateTime.now();
    if (_lastRestartTime != null) {
      final timeSinceLastRestart = now
          .difference(_lastRestartTime!)
          .inMilliseconds;
      if (timeSinceLastRestart < _minRestartDelayMs) {
        // We're restarting too quickly, add extra delay
        debugPrint('[VoiceService] ⚠️ Restart too quick, adding delay...');
      }
    }

    // Cap restart attempts to prevent infinite loops, but keep it running
    if (_restartAttempts >= _maxRestartAttempts) {
      debugPrint(
        '[VoiceService] ⚠️ Max restart attempts reached, resetting counter...',
      );
      _restartAttempts = 0; // Reset to keep continuous listening going
    }

    _restartAttempts++;

    // Use shorter delays for more responsive continuous listening (like Google Assistant)
    // 800ms, 1s, 1.2s, 1.5s, 2s (capped) - much faster than before
    final baseDelay = 800; // Start with 800ms instead of 1500ms
    final multiplier = 1 + (_restartAttempts * 0.2).clamp(0.0, 1.5);
    final delayMs = (baseDelay * multiplier).clamp(800, 2000).toInt();
    final delay = Duration(milliseconds: delayMs);

    debugPrint(
      '[VoiceService] 🔄 Scheduling restart in ${delay.inMilliseconds}ms (attempt $_restartAttempts)',
    );

    _continuousRestartTimer = Timer(delay, () async {
      if (_isContinuousListening && !_hotwordDetected && !_isRestarting) {
        _isRestarting = true;
        _lastRestartTime = DateTime.now();

        // Ensure STT is fully stopped before restarting
        if (_stt.isListening) {
          await _stt.stop();
          await Future.delayed(const Duration(milliseconds: 200));
        }

        await _startContinuousListenCycle();
        _isRestarting = false;
      }
    });
  }

  /// Start listening for hotword with continuous mode
  /// This keeps listening indefinitely and processes commands when hotword is detected
  Future<void> startHotwordListening({
    required Function() onHotwordDetected,
    Function(String text)? onContinuousSpeech,
  }) async {
    debugPrint(
      '[VoiceService] 🎧 Starting continuous hotword listening for "$hotword"',
    );

    if (!_sttInitialized) {
      debugPrint('[VoiceService] Initializing STT...');
      final initialized = await initStt();
      if (!initialized) {
        debugPrint('[VoiceService] ❌ STT initialization failed');
        return;
      }
      debugPrint('[VoiceService] ✅ STT initialized');
    }

    _onHotwordDetected = onHotwordDetected;
    _onContinuousSpeech = onContinuousSpeech;
    _isHotwordListening = true;
    _isContinuousListening = true;
    _hotwordDetected = false;
    _restartAttempts = 0;

    await _startContinuousListenCycle();
  }

  /// Start a continuous listen cycle
  Future<void> _startContinuousListenCycle() async {
    if (!_isContinuousListening || kIsWeb) {
      debugPrint('[VoiceService] Continuous listening stopped or on web');
      return;
    }

    // Don't start if regular command listening is active
    if (_isListening && !_isHotwordListening) {
      debugPrint('[VoiceService] Regular listening active, waiting...');
      _scheduleContinuousRestart();
      return;
    }

    // Check if STT is available
    if (!_stt.isAvailable) {
      debugPrint('[VoiceService] ❌ STT not available, scheduling retry...');
      _scheduleContinuousRestart();
      return;
    }

    // If already listening, don't restart
    if (_stt.isListening) {
      debugPrint('[VoiceService] Already listening, skipping restart');
      return;
    }

    // Additional guard: wait if we just stopped
    if (_lastRestartTime != null) {
      final timeSince = DateTime.now()
          .difference(_lastRestartTime!)
          .inMilliseconds;
      if (timeSince < 500) {
        debugPrint('[VoiceService] Too soon after last restart, waiting...');
        await Future.delayed(Duration(milliseconds: 500 - timeSince));
      }
    }

    debugPrint('[VoiceService] 🎧 Starting continuous listen cycle...');
    _hotwordDetected = false;

    try {
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) {
          _handleContinuousSpeechResult(result);
        },
        onSoundLevelChange: (level) {
          _audioLevelController.add(level);
        },
        // Infinite listening - no timeout (like Google Assistant)
        listenFor: const Duration(hours: 24),
        // Very long pause detection - won't stop on brief silences
        pauseFor: const Duration(seconds: 30),
        listenOptions: SpeechListenOptions(
          partialResults: true, // Essential for continuous hotword detection
          cancelOnError: false, // Don't cancel on minor errors
          listenMode: ListenMode.dictation, // Best for continuous listening
          autoPunctuation: false, // Reduce processing overhead
          enableHapticFeedback: false, // Reduce battery usage
        ),
      );

      _isListening = true;
      debugPrint('[VoiceService] ✅ Continuous listening started successfully');
    } catch (e) {
      debugPrint('[VoiceService] ❌ Error starting continuous listen: $e');
      _isListening = false;
      _scheduleContinuousRestart();
    }
  }

  /// Handle speech results in continuous mode
  void _handleContinuousSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase().trim();

    if (text.isEmpty) return;

    debugPrint(
      '[VoiceService] 🎤 Heard: "$text" (final: ${result.finalResult})',
    );

    // Notify about continuous speech if callback provided
    _onContinuousSpeech?.call(text);

    // Check for hotword in the recognized text
    bool hotwordFound = false;
    for (final variant in hotwordVariants) {
      if (text.contains(variant)) {
        hotwordFound = true;
        break;
      }
    }

    if (hotwordFound && !_hotwordDetected) {
      debugPrint('[VoiceService] ✅ HOTWORD DETECTED in: "$text"');
      _hotwordDetected = true;

      // Extract command after hotword (if any)
      String commandAfterHotword = '';
      for (final variant in hotwordVariants) {
        final index = text.indexOf(variant);
        if (index != -1) {
          commandAfterHotword = text.substring(index + variant.length).trim();
          break;
        }
      }

      debugPrint(
        '[VoiceService] Command after hotword: "$commandAfterHotword"',
      );

      // Temporarily pause continuous listening for command processing
      _isContinuousListening = false;
      _continuousRestartTimer?.cancel();

      // Stop current listening session
      _stt.stop();
      _isListening = false;

      // Notify hotword detected - the callback will handle command capture
      Future.delayed(const Duration(milliseconds: 100), () {
        _onHotwordDetected?.call();
      });
    }
  }

  /// Stop hotword listening
  Future<void> stopHotwordListening() async {
    debugPrint('[VoiceService] Stopping continuous hotword listening');
    _isHotwordListening = false;
    _isContinuousListening = false;
    _hotwordDetected = false;
    _hotwordTimer?.cancel();
    _continuousRestartTimer?.cancel();
    _restartAttempts = 0;
    if (_stt.isListening) {
      await _stt.stop();
    }
    _isListening = false;
  }

  /// Resume hotword listening after voice command processing
  Future<void> resumeHotwordListening() async {
    if (_onHotwordDetected != null && !_isContinuousListening) {
      debugPrint('[VoiceService] 🔄 Resuming continuous hotword listening');
      
      // Cancel any pending restart timers to prevent overlaps
      _continuousRestartTimer?.cancel();
      
      _isHotwordListening = true;
      _isContinuousListening = true;
      _hotwordDetected = false;
      _restartAttempts = 0;

      // Wait for any TTS to complete before resuming
      if (_isSpeaking) {
        debugPrint('[VoiceService] Waiting for TTS to finish before resuming...');
        int waitCount = 0;
        while (_isSpeaking && waitCount < 30) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitCount++;
        }
      }

      // Additional buffer to ensure TTS audio has cleared
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isContinuousListening) {
        await _startContinuousListenCycle();
      }
    }
  }

  /// Check if hotword listening is active
  bool get isHotwordListening => _isHotwordListening;

  /// Check if continuous listening is active
  bool get isContinuousListening => _isContinuousListening;

  /// Check if STT is currently listening (for debugging)
  bool get isSttListening => _stt.isListening;
}
