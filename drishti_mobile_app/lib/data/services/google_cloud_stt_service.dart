/// Online Google Cloud Speech-to-Text for command capture.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:record/record.dart';

import 'ai_runtime_config.dart';
import 'network_status_service.dart';

class GoogleCloudSttResult {
  final String text;
  final double confidence;
  final Duration audioDuration;

  const GoogleCloudSttResult({
    required this.text,
    required this.confidence,
    required this.audioDuration,
  });

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => text.trim().isNotEmpty;
}

class GoogleCloudSttService {
  static final GoogleCloudSttService _instance =
      GoogleCloudSttService._internal();

  factory GoogleCloudSttService() => _instance;

  GoogleCloudSttService._internal();

  static const int sampleRate = 16000;
  static const int _maxSilenceFrames = 18;
  static const int _maxPreSpeechChunks = 12;
  static const double _speechThreshold = 0.018;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 40),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  AudioRecorder? _activeRecorder;
  StreamSubscription<Uint8List>? _activeSubscription;
  bool _isListening = false;

  bool get isConfigured => AIRuntimeConfig.hasGoogleCloudSttAccessToken;

  bool get isListening => _isListening;

  Future<GoogleCloudSttResult> recognizeSpeech({
    required String languageCode,
    Duration timeout = const Duration(seconds: 15),
    Duration initialSilenceTimeout = const Duration(seconds: 8),
  }) async {
    if (!isConfigured) {
      throw Exception('Google Cloud Speech token not configured.');
    }

    if (!await NetworkStatusService().hasInternetConnection()) {
      throw Exception(
        'No internet connection for Google Cloud Speech-to-Text.',
      );
    }

    if (_isListening) {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    final recorder = AudioRecorder();
    if (!await recorder.hasPermission()) {
      return const GoogleCloudSttResult(
        text: '',
        confidence: 0,
        audioDuration: Duration.zero,
      );
    }

    _isListening = true;
    _activeRecorder = recorder;

    final audioStream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        bitRate: sampleRate * 16,
      ),
    );

    final completer = Completer<Uint8List>();
    final preSpeechChunks = ListQueue<Uint8List>();
    final collectedChunks = <Uint8List>[];
    var speechDetected = false;
    var silenceFrames = 0;
    var isFinalized = false;

    Future<void> finalize() async {
      if (isFinalized) {
        return;
      }
      isFinalized = true;

      await _activeSubscription?.cancel();
      _activeSubscription = null;
      try {
        await recorder.stop();
      } catch (_) {}
      _activeRecorder = null;
      _isListening = false;

      final byteBuilder = BytesBuilder(copy: false);
      for (final chunk in collectedChunks) {
        byteBuilder.add(chunk);
      }
      completer.complete(byteBuilder.takeBytes());
    }

    final timeoutTimer = Timer(timeout, finalize);
    final initialSilenceTimer = Timer(initialSilenceTimeout, finalize);

    _activeSubscription = audioStream.listen(
      (chunk) {
        if (isFinalized) {
          return;
        }

        final level = _calculateAudioLevel(chunk);
        final isSpeechFrame = level >= _speechThreshold;

        if (!speechDetected) {
          preSpeechChunks.add(chunk);
          while (preSpeechChunks.length > _maxPreSpeechChunks) {
            preSpeechChunks.removeFirst();
          }
        }

        if (isSpeechFrame) {
          if (!speechDetected) {
            speechDetected = true;
            initialSilenceTimer.cancel();
            collectedChunks.addAll(preSpeechChunks);
            preSpeechChunks.clear();
          }

          collectedChunks.add(chunk);
          silenceFrames = 0;
          return;
        }

        if (speechDetected) {
          collectedChunks.add(chunk);
          silenceFrames += 1;
          if (silenceFrames >= _maxSilenceFrames) {
            unawaited(finalize());
          }
        }
      },
      onError: (_) {
        unawaited(finalize());
      },
      cancelOnError: true,
    );

    final audioBytes = await completer.future;
    timeoutTimer.cancel();
    initialSilenceTimer.cancel();

    if (audioBytes.isEmpty) {
      return const GoogleCloudSttResult(
        text: '',
        confidence: 0,
        audioDuration: Duration.zero,
      );
    }

    return _transcribeAudio(audioBytes: audioBytes, languageCode: languageCode);
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _activeSubscription?.cancel();
    _activeSubscription = null;
    try {
      await _activeRecorder?.stop();
    } catch (_) {}
    _activeRecorder = null;
  }

  Future<GoogleCloudSttResult> _transcribeAudio({
    required Uint8List audioBytes,
    required String languageCode,
  }) async {
    final response = await _dio.post(
      'https://speech.googleapis.com/v1/speech:recognize',
      data: {
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': sampleRate,
          'languageCode': languageCode,
          'maxAlternatives': 1,
          'enableAutomaticPunctuation': true,
        },
        'audio': {'content': base64Encode(audioBytes)},
      },
      options: Options(
        headers: {
          'Authorization':
              'Bearer ${AIRuntimeConfig.googleCloudSttAccessToken}',
          if (AIRuntimeConfig.googleCloudSttProjectId.trim().isNotEmpty)
            'x-goog-user-project': AIRuntimeConfig.googleCloudSttProjectId,
        },
      ),
    );

    final data = response.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) {
      return GoogleCloudSttResult(
        text: '',
        confidence: 0,
        audioDuration: _durationFor(audioBytes),
      );
    }

    final buffer = StringBuffer();
    var bestConfidence = 0.0;
    for (final result in results) {
      final alternatives =
          (result as Map<String, dynamic>)['alternatives'] as List<dynamic>? ??
          const [];
      if (alternatives.isEmpty) {
        continue;
      }
      final best = alternatives.first as Map<String, dynamic>;
      final transcript = (best['transcript'] as String? ?? '').trim();
      if (transcript.isNotEmpty) {
        if (buffer.isNotEmpty) {
          buffer.write(' ');
        }
        buffer.write(transcript);
      }
      bestConfidence =
          (best['confidence'] as num?)?.toDouble() ?? bestConfidence;
    }

    return GoogleCloudSttResult(
      text: buffer.toString().trim(),
      confidence: bestConfidence,
      audioDuration: _durationFor(audioBytes),
    );
  }

  double _calculateAudioLevel(Uint8List chunk) {
    if (chunk.length < 2) {
      return 0;
    }

    var sumSquares = 0.0;
    var samples = 0;
    for (var index = 0; index < chunk.length - 1; index += 2) {
      final sample = chunk[index] | (chunk[index + 1] << 8);
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      final normalized = signedSample / 32768.0;
      sumSquares += normalized * normalized;
      samples += 1;
    }

    if (samples == 0) {
      return 0;
    }

    return math.sqrt(sumSquares / samples);
  }

  Duration _durationFor(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    final milliseconds = (sampleCount / sampleRate * 1000).round();
    return Duration(milliseconds: milliseconds);
  }
}
