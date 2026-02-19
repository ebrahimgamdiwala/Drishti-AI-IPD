/// Audio Feedback Engine
///
/// Generates and manages audio responses for voice navigation.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../voice_service.dart';

/// Priority level for audio messages
enum AudioPriority {
  /// Can be skipped if needed
  low,

  /// Standard queue processing
  normal,

  /// Jump to front of queue
  high,

  /// Interrupt everything immediately
  emergency,
}

/// An audio message to be spoken
class AudioMessage {
  final String text;
  final AudioPriority priority;
  final DateTime timestamp;

  const AudioMessage({
    required this.text,
    required this.priority,
    required this.timestamp,
  });
}

/// Engine for generating and managing audio feedback
///
/// This engine manages a priority queue of audio messages and ensures
/// that responses are formatted according to accessibility guidelines.
///
/// Priority levels (highest to lowest):
/// - Emergency: Interrupts all current operations immediately
/// - High: Jumps to front of queue
/// - Normal: Standard queue processing
/// - Low: Can be skipped if needed
class AudioFeedbackEngine {
  final VoiceService _voiceService;
  final List<AudioMessage> _messageQueue = [];
  bool _isProcessing = false;

  AudioFeedbackEngine({required VoiceService voiceService})
    : _voiceService = voiceService;

  /// Current two-letter language code of the TTS engine (e.g. 'hi', 'en').
  String get currentLanguageCode => _voiceService.currentLanguageCode;

  /// Speak a message (queued based on priority)
  ///
  /// Messages are queued and processed according to their priority level.
  /// Emergency priority messages are spoken immediately via [speakImmediate].
  Future<void> speak(
    String message, {
    AudioPriority priority = AudioPriority.normal,
  }) async {
    if (message.isEmpty) return;

    // Emergency messages bypass the queue
    if (priority == AudioPriority.emergency) {
      await speakImmediate(message);
      return;
    }

    final audioMessage = AudioMessage(
      text: message,
      priority: priority,
      timestamp: DateTime.now(),
    );

    // Add to queue in priority order
    _addToQueue(audioMessage);

    // Start processing if not already processing
    if (!_isProcessing) {
      // Don't await - let it run in background
      unawaited(_processQueue());
    }
  }

  /// Speak immediately, interrupting current speech
  ///
  /// This method stops any current speech and speaks the message immediately.
  /// Used for emergency messages and safety warnings.
  Future<void> speakImmediate(String message) async {
    if (message.isEmpty) return;

    try {
      // Stop current speech
      await _voiceService.stopSpeaking();

      // Clear low priority messages from queue
      _messageQueue.removeWhere((msg) => msg.priority == AudioPriority.low);

      // Speak immediately - VoiceService.speak() now waits for completion
      await _voiceService.speak(message);
    } catch (e) {
      debugPrint('[AudioFeedback] Error in speakImmediate: $e');
    }
  }

  /// Announce a screen with available actions
  ///
  /// Formats: "[Screen name] screen. Available actions: [action1], [action2]"
  Future<void> announceScreen(String screenName, List<String> actions) async {
    final actionsText = actions.isEmpty
        ? ''
        : ' Available actions: ${actions.join(', ')}.';
    await speak('$screenName screen.$actionsText');
  }

  /// Confirm an action was completed
  ///
  /// Formats: "[Action] completed"
  Future<void> confirmAction(String action) async {
    await speak('$action completed');
  }

  /// Report an error in user-friendly language
  ///
  /// Errors are spoken with high priority to ensure users are aware of issues.
  Future<void> reportError(String error) async {
    await speak(error, priority: AudioPriority.high);
  }

  /// Announce navigation to a destination in the current TTS language.
  ///
  /// Uses [VoiceService.currentLanguageCode] to pick the correct phrase.
  Future<void> announceNavigation(String destination) async {
    final lang = _voiceService.currentLanguageCode;
    // Localized screen names
    const screenNames = <String, Map<String, String>>{
      'home': {'hi': 'होम', 'ta': 'முகப்பு', 'te': 'హోమ్', 'bn': 'হোম'},
      'settings': {
        'hi': 'सेटिंग्स',
        'ta': 'அமைப்புகள்',
        'te': 'సెట్టింగ్లు',
        'bn': 'সেটিংস',
      },
      'relatives': {
        'hi': 'परिचित',
        'ta': 'உறவினர்கள்',
        'te': 'బంధువులు',
        'bn': 'স্বজন',
      },
      'dashboard': {
        'hi': 'डैशबोर्ड',
        'ta': 'டாஷ்போர்ட்',
        'te': 'డాష్బోర్డ్',
        'bn': 'ড্যাশবোর্ড',
      },
      'profile': {
        'hi': 'प्रोफ़ाइल',
        'ta': 'சுயவிவரம்',
        'te': 'ప్రొఫైల్',
        'bn': 'প্রোফাইল',
      },
      'vision': {
        'hi': 'दृष्टि',
        'ta': 'பார்வை',
        'te': 'దృష్టి',
        'bn': 'দৃষ্টি',
      },
      'activity': {
        'hi': 'गतिविधि',
        'ta': 'செயல்பாடு',
        'te': 'కార్యకలాపం',
        'bn': 'কার্যকলাপ',
      },
      'emergency contacts': {
        'hi': 'आपातकालीन संपर्क',
        'ta': 'அவசர தொடர்புகள்',
        'te': 'అత్యవసర పరిచయాలు',
        'bn': 'জরুরি যোগাযোগ',
      },
    };
    final key = destination.toLowerCase();
    final localizedName = screenNames[key]?[lang] ?? destination;
    const phrases = <String, String>{
      'hi': '{name} खुल रहा है',
      'ta': '{name} திரை திறக்கிறது',
      'te': '{name} స్క్రీన్ తెరుచుకుంటోంది',
      'bn': '{name} স্ক্রিন খুলছে',
    };
    final template = phrases[lang];
    final text = template != null
        ? template.replaceAll('{name}', localizedName)
        : 'Navigating to $destination';
    await speak(text);
  }

  /// Format a vision response according to guidelines
  ///
  /// - Limit to 2 sentences maximum
  /// - Remove filler phrases
  /// - Use clock directions for locations
  /// - Prioritize safety information
  String formatVisionResponse(String rawResponse) {
    if (rawResponse.isEmpty) return rawResponse;

    // Step 1: Remove filler phrases
    String formatted = _removeFillerPhrases(rawResponse);

    // Step 2: Split into sentences
    List<String> sentences = _splitIntoSentences(formatted);

    // Step 3: Prioritize safety information (hazards first)
    sentences = _prioritizeSafetyInformation(sentences);

    // Step 4: Limit to 2 sentences
    if (sentences.length > 2) {
      sentences = sentences.sublist(0, 2);
    }

    // Step 5: Join sentences and ensure proper formatting
    String result = sentences.join(' ').trim();

    // Ensure it ends with a period
    if (result.isNotEmpty && !result.endsWith('.')) {
      result += '.';
    }

    return result;
  }

  /// Remove filler phrases from the response
  ///
  /// Removes phrases like "I see", "The image shows", "It appears", etc.
  String _removeFillerPhrases(String text) {
    // List of filler phrases to remove (case-insensitive)
    final fillerPhrases = [
      r'I see\s+',
      r'The image shows\s+',
      r'It appears\s+',
      r'It looks like\s+',
      r'I can see\s+',
      r'There is\s+',
      r'There are\s+',
      r'In the image,?\s+',
      r'In this image,?\s+',
      r'The picture shows\s+',
      r'This shows\s+',
      r'I observe\s+',
      r'I notice\s+',
    ];

    String result = text;

    for (final phrase in fillerPhrases) {
      // Remove at the beginning of the text
      result = result.replaceAll(RegExp('^$phrase', caseSensitive: false), '');

      // Remove after sentence boundaries
      result = result.replaceAll(
        RegExp(r'\.\s+' + phrase, caseSensitive: false),
        '. ',
      );
    }

    // Capitalize first letter after removal
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    return result.trim();
  }

  /// Split text into sentences
  ///
  /// Splits on periods, exclamation marks, and question marks.
  List<String> _splitIntoSentences(String text) {
    if (text.isEmpty) return [];

    // Split on sentence boundaries (., !, ?)
    final sentences = text.split(RegExp(r'[.!?]+\s*'));

    // Filter out empty sentences and trim
    return sentences.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  /// Prioritize safety information in sentences
  ///
  /// Moves sentences containing hazard/danger keywords to the front.
  List<String> _prioritizeSafetyInformation(List<String> sentences) {
    if (sentences.length <= 1) return sentences;

    // Keywords that indicate safety-critical information
    final safetyKeywords = [
      'danger',
      'hazard',
      'warning',
      'caution',
      'stop',
      'vehicle',
      'car',
      'truck',
      'bus',
      'motorcycle',
      'stairs',
      'staircase',
      'step',
      'hole',
      'pit',
      'gap',
      'fire',
      'flame',
      'water',
      'pool',
      'cliff',
      'edge',
      'drop',
      'approaching',
      'moving',
      'fast',
    ];

    // Separate safety-related sentences from others
    final safetySentences = <String>[];
    final normalSentences = <String>[];

    for (final sentence in sentences) {
      final lowerSentence = sentence.toLowerCase();
      final isSafety = safetyKeywords.any(
        (keyword) => lowerSentence.contains(keyword),
      );

      if (isSafety) {
        safetySentences.add(sentence);
      } else {
        normalSentences.add(sentence);
      }
    }

    // Return safety sentences first, then normal sentences
    return [...safetySentences, ...normalSentences];
  }

  /// Format an error message to be user-friendly
  ///
  /// Detects specific error types and provides user-friendly messages
  /// without technical jargon. Handles:
  /// - Camera errors
  /// - Network errors
  /// - Permission errors
  /// - Timeout errors
  /// - Unexpected errors
  ///
  /// Requirements: 1.4, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
  String formatErrorMessage(String technicalError) {
    if (technicalError.isEmpty) return technicalError;

    final lowerError = technicalError.toLowerCase();

    // Check in order of specificity (most specific first)

    // Low confidence / unclear command (Requirement 8.1)
    if (_isLowConfidenceError(lowerError)) {
      return 'I didn\'t understand. Please repeat.';
    }

    // Permission errors (Requirement 8.4) - check before camera/network
    if (_isPermissionError(lowerError)) {
      // Try to extract the specific permission type
      final permissionType = _extractPermissionType(lowerError);
      return '$permissionType access required. Please enable in settings.';
    }

    // Timeout errors - check before network errors
    if (_isTimeoutError(lowerError)) {
      return 'Taking longer than expected. Please wait.';
    }

    // Camera errors (Requirement 8.2)
    if (_isCameraError(lowerError)) {
      return 'Camera not available. Trying again.';
    }

    // Network errors (Requirement 8.3)
    if (_isNetworkError(lowerError)) {
      return 'Connection lost. Using offline mode.';
    }

    // For unexpected errors, remove technical jargon (Requirement 8.5, 8.6)
    return _removeJargon(technicalError);
  }

  /// Check if error is related to camera
  bool _isCameraError(String error) {
    final cameraKeywords = [
      'camera',
      'cameracont',
      'cameraexception',
      'capture',
      'frame',
      'vision',
      'image',
      'photo',
    ];

    return cameraKeywords.any((keyword) => error.contains(keyword)) &&
        (error.contains('unavailable') ||
            error.contains('not available') ||
            error.contains('failed') ||
            error.contains('error') ||
            error.contains('exception') ||
            error.contains('denied') ||
            error.contains('not found'));
  }

  /// Check if error is related to network
  bool _isNetworkError(String error) {
    final networkKeywords = [
      'network',
      'connection',
      'internet',
      'offline',
      'socket',
      'http',
      'api',
      'server',
      'timeout',
      'unreachable',
      'no connection',
      'lost connection',
      'disconnected',
      'connectivity',
    ];

    return networkKeywords.any((keyword) => error.contains(keyword));
  }

  /// Check if error is related to permissions
  bool _isPermissionError(String error) {
    return error.contains('permission') ||
        error.contains('denied') ||
        error.contains('not authorized') ||
        error.contains('unauthorized') ||
        error.contains('access denied');
  }

  /// Check if error is related to timeout
  bool _isTimeoutError(String error) {
    // Only treat as timeout if it's not a network/connection timeout
    final hasTimeout =
        error.contains('timeout') ||
        error.contains('timed out') ||
        error.contains('time out') ||
        error.contains('taking too long');

    // Exclude if it's clearly a network timeout
    final isNetworkTimeout =
        error.contains('connection') ||
        error.contains('network') ||
        error.contains('http') ||
        error.contains('api');

    return hasTimeout && !isNetworkTimeout;
  }

  /// Check if error is related to low confidence or unclear command
  bool _isLowConfidenceError(String error) {
    return error.contains('low confidence') ||
        error.contains('unclear') ||
        error.contains('not understood') ||
        error.contains('didn\'t understand') ||
        error.contains('unrecognized') ||
        error.contains('invalid command');
  }

  /// Extract permission type from error message
  String _extractPermissionType(String error) {
    if (error.contains('microphone') ||
        error.contains('audio') ||
        error.contains('record')) {
      return 'Microphone';
    } else if (error.contains('camera') ||
        error.contains('photo') ||
        error.contains('video')) {
      return 'Camera';
    } else if (error.contains('location') || error.contains('gps')) {
      return 'Location';
    } else if (error.contains('storage') || error.contains('file')) {
      return 'Storage';
    } else if (error.contains('contact')) {
      return 'Contacts';
    } else {
      return 'Permission';
    }
  }

  /// Remove technical jargon from error message
  ///
  /// Removes technical terms and provides user-friendly alternatives.
  /// Ensures no stack traces or technical codes are shown to users.
  String _removeJargon(String error) {
    String formatted = error;

    // Remove technical exception types
    formatted = formatted.replaceAll(
      RegExp(r'\b(exception|error|failure|fault)\b', caseSensitive: false),
      'issue',
    );

    // Remove technical terms
    formatted = formatted.replaceAll(
      RegExp(r'\bnull pointer\b', caseSensitive: false),
      'missing information',
    );

    formatted = formatted.replaceAll(
      RegExp(r'\bstack trace\b', caseSensitive: false),
      'details',
    );

    // Remove HTTP error codes
    formatted = formatted.replaceAll(
      RegExp(r'\bHTTP\s*\d+\b', caseSensitive: false),
      'connection issue',
    );

    // Remove error codes (e.g., ERR_001, ERROR-123)
    formatted = formatted.replaceAll(
      RegExp(r'\b(ERR|ERROR)[-_]?\d+\b', caseSensitive: false),
      '',
    );

    // Remove file paths and line numbers
    formatted = formatted.replaceAll(
      RegExp(r'at\s+[\w./\\]+:\d+', caseSensitive: false),
      '',
    );

    // Remove class/method references (e.g., ClassName.methodName)
    formatted = formatted.replaceAll(RegExp(r'\b[A-Z]\w+\.\w+\b'), '');

    // Clean up multiple spaces and trim
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If the message is now too technical or empty, provide a generic message
    if (formatted.isEmpty ||
        formatted.length < 5 ||
        _containsTooMuchJargon(formatted)) {
      return 'Something went wrong. Please try again.';
    }

    // Ensure first letter is capitalized
    if (formatted.isNotEmpty) {
      formatted = formatted[0].toUpperCase() + formatted.substring(1);
    }

    // Ensure it ends with a period
    if (formatted.isNotEmpty && !formatted.endsWith('.')) {
      formatted += '.';
    }

    return formatted;
  }

  /// Check if text still contains too much technical jargon
  bool _containsTooMuchJargon(String text) {
    final jargonTerms = [
      'null',
      'undefined',
      'void',
      'async',
      'await',
      'promise',
      'callback',
      'buffer',
      'pointer',
      'reference',
      'instance',
      'object',
      'class',
      'method',
      'function',
      'variable',
      'parameter',
      'argument',
      'return',
      'throw',
      'catch',
      'try',
      'finally',
    ];

    final lowerText = text.toLowerCase();
    int jargonCount = 0;

    for (final term in jargonTerms) {
      if (lowerText.contains(term)) {
        jargonCount++;
      }
    }

    // If more than 2 jargon terms, it's too technical
    return jargonCount > 2;
  }

  /// Clear the message queue
  ///
  /// Removes all pending messages from the queue.
  /// Does not stop currently speaking message.
  void clearQueue() {
    _messageQueue.clear();
  }

  /// Add a message to the queue in priority order
  ///
  /// Messages are inserted based on priority (higher priority = lower index value):
  /// - Emergency (index 3) goes first
  /// - High (index 2) goes after emergency
  /// - Normal (index 1) goes after high
  /// - Low (index 0) goes last
  /// Within the same priority, messages maintain FIFO order
  void _addToQueue(AudioMessage message) {
    if (_messageQueue.isEmpty) {
      _messageQueue.add(message);
      return;
    }

    // Find insertion point based on priority
    // Insert before the first message with LOWER priority
    int insertIndex = _messageQueue.length;
    for (int i = 0; i < _messageQueue.length; i++) {
      if (message.priority.index > _messageQueue[i].priority.index) {
        insertIndex = i;
        break;
      }
    }

    _messageQueue.insert(insertIndex, message);
  }

  /// Process the message queue
  ///
  /// Processes messages in priority order until the queue is empty.
  /// Only one queue processing loop runs at a time.
  Future<void> _processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      while (_messageQueue.isNotEmpty) {
        // Wait if currently speaking (check VoiceService state)
        while (_voiceService.isSpeaking) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Get next message (already in priority order)
        final message = _messageQueue.removeAt(0);

        // Speak the message - VoiceService.speak() now waits for completion
        try {
          await _voiceService.speak(message.text);
        } catch (e) {
          debugPrint('[AudioFeedback] Error speaking message: $e');
        }

        // Small delay between messages for clarity
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Check if currently speaking
  bool get isSpeaking => _voiceService.isSpeaking;

  /// Get the number of messages in the queue
  int get queueLength => _messageQueue.length;

  /// Stop speaking immediately
  Future<void> stopSpeaking() async {
    try {
      await _voiceService.stopSpeaking();
      _messageQueue.clear();
      debugPrint('[AudioFeedback] Speaking stopped');
    } catch (e) {
      debugPrint('[AudioFeedback] Error stopping speech: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _messageQueue.clear();
    _isProcessing = false;
    debugPrint('[AudioFeedback] Audio feedback engine disposed');
  }
}
