/// Voice-Guided Relative Addition Flow
///
/// Handles hands-free relative addition with smooth STT conversation flow.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../voice_service.dart';
import '../../repositories/relatives_repository.dart';
import '../../models/relative_model.dart';
import '../../../generated/l10n/app_localizations.dart';

/// All TTS strings used in the voice flow — build from [AppLocalizations]
/// via [VoiceRelativeFlowStrings.fromL10n] for language-aware speech.
class VoiceRelativeFlowStrings {
  final String welcome;
  final String askName;
  final String Function(String name) gotName;
  final String askRelationship;
  final String Function(String relationship) gotRelationship;
  final String askPhoto;
  final String askNotes;
  final String noNotes;
  final String gotNotes;
  final String photoTaken;
  final String skipPhoto;
  final String Function(String name, String relationship) confirmPrompt;
  final String saving;
  final String Function(String name, String relationship) saved;
  final String cancelled;
  final String cameraInstruction;
  final String photoRequired;

  VoiceRelativeFlowStrings({
    required this.welcome,
    required this.askName,
    required this.gotName,
    required this.askRelationship,
    required this.gotRelationship,
    required this.askPhoto,
    required this.askNotes,
    required this.noNotes,
    required this.gotNotes,
    required this.photoTaken,
    required this.skipPhoto,
    required this.confirmPrompt,
    required this.saving,
    required this.saved,
    required this.cancelled,
    required this.cameraInstruction,
    required this.photoRequired,
  });

  /// Build from [AppLocalizations] — automatically uses the current app language.
  factory VoiceRelativeFlowStrings.fromL10n(AppLocalizations l10n) {
    return VoiceRelativeFlowStrings(
      welcome: l10n.addRelativePrompt,
      askName: l10n.speakName,
      gotName: (name) => l10n.nameCaptured(name),
      askRelationship: l10n.speakRelationship,
      gotRelationship: (rel) => l10n.relationshipCaptured(rel),
      askPhoto: l10n.takePhotoPrompt,
      askNotes: l10n.speakNotes,
      noNotes: l10n.noNotesAdded,
      gotNotes: l10n.notesAdded,
      photoTaken: l10n.photoTaken,
      skipPhoto: l10n.skippingPhoto,
      confirmPrompt: (name, rel) => l10n.confirmSave(name, rel),
      saving: l10n.savingRelative,
      saved: (name, rel) => l10n.relativeSaved(name, rel),
      cancelled: l10n.cancelled,
      cameraInstruction: l10n.cameraReady,
      photoRequired: l10n.photoRequired,
    );
  }
}

/// Steps in the voice-guided relative addition flow
enum VoiceRelativeStep {
  welcome,
  name,
  relationship,
  photo,
  notes,
  confirm,
  saving,
  complete,
}

/// Result of the voice-guided flow
class VoiceRelativeFlowResult {
  final RelativeModel? relative;
  final bool cancelled;
  final String? error;

  const VoiceRelativeFlowResult({
    this.relative,
    this.cancelled = false,
    this.error,
  });

  bool get isSuccess => relative != null && !cancelled && error == null;
}

/// Voice-guided relative addition flow controller
class VoiceRelativeFlow {
  final VoiceService _voiceService;
  final RelativesRepository _repository;

  /// Optional localized strings — defaults to English if null
  final VoiceRelativeFlowStrings? _strings;

  /// Callback to open a voice-controlled camera; returns the captured [File].
  /// If null, falls back to a simple error message (no image_picker).
  final Future<File?> Function()? onOpenCamera;

  // Flow state
  VoiceRelativeStep _currentStep = VoiceRelativeStep.welcome;
  String? _name;
  String? _relationship;
  File? _photo;
  String? _notes;
  bool _isListening = false;
  bool _isCancelled = false;

  // Callbacks
  final void Function(VoiceRelativeStep step)? onStepChanged;
  final void Function(bool isListening)? onListeningChanged;
  final void Function(
    String name,
    String relationship,
    File? photo,
    String? notes,
  )?
  onDataChanged;

  VoiceRelativeFlow({
    required VoiceService voiceService,
    required RelativesRepository repository,
    VoiceRelativeFlowStrings? strings,
    this.onOpenCamera,
    this.onStepChanged,
    this.onListeningChanged,
    this.onDataChanged,
  }) : _voiceService = voiceService,
       _repository = repository,
       _strings = strings;

  // Convenience getter — falls back to English defaults
  VoiceRelativeFlowStrings get _s => _strings ?? _englishDefaults;

  static final _englishDefaults = VoiceRelativeFlowStrings(
    welcome: "Let's add a new relative. Say cancel to stop at any time.",
    askName: "What is the person's name?",
    gotName: (name) => 'Got it. Name is $name.',
    askRelationship:
        'What is their relationship to you? For example, mother, father, friend.',
    gotRelationship: (rel) => 'Relationship set to $rel.',
    askPhoto:
        'Now let\'s take a photo. Say take photo to open the camera, or skip.',
    askNotes:
        'Would you like to add any notes? Say notes, or say skip to continue.',
    noNotes: 'No notes added.',
    gotNotes: 'Notes added.',
    photoTaken: 'Photo captured successfully.',
    skipPhoto: 'Skipping photo. You can add it later.',
    confirmPrompt: (name, rel) =>
        'Ready to add. Name: $name, Relationship: $rel. Say done or yes to confirm, or cancel to discard.',
    saving: 'Saving relative information.',
    saved: (name, rel) => '$name has been added successfully as your $rel.',
    cancelled: 'Cancelled.',
    cameraInstruction:
        'Camera ready. Say take photo to capture, switch camera to flip, or skip.',
    photoRequired: 'A photo is required. Please take a photo.',
  );

  /// Start the voice-guided flow
  Future<VoiceRelativeFlowResult> start() async {
    try {
      _currentStep = VoiceRelativeStep.welcome;
      _isCancelled = false;
      _notifyStepChanged();

      // Welcome message
      await _voiceService.speak(_s.welcome);

      // Start the flow
      await _promptForName();

      if (_isCancelled) {
        return const VoiceRelativeFlowResult(cancelled: true);
      }

      await _promptForRelationship();

      if (_isCancelled) {
        return const VoiceRelativeFlowResult(cancelled: true);
      }

      await _promptForPhoto();

      if (_isCancelled) {
        return const VoiceRelativeFlowResult(cancelled: true);
      }

      await _promptForNotes();

      if (_isCancelled) {
        return const VoiceRelativeFlowResult(cancelled: true);
      }

      await _promptForConfirmation();

      if (_isCancelled) {
        return const VoiceRelativeFlowResult(cancelled: true);
      }

      // Save the relative
      final relative = await _saveRelative();

      if (relative != null) {
        _currentStep = VoiceRelativeStep.complete;
        _notifyStepChanged();
        await _voiceService.speak(_s.saved(_name!, _relationship!));
        return VoiceRelativeFlowResult(relative: relative);
      } else {
        return const VoiceRelativeFlowResult(error: 'Failed to save relative');
      }
    } catch (e) {
      debugPrint('[VoiceRelativeFlow] Error: $e');
      return VoiceRelativeFlowResult(error: e.toString());
    }
  }

  /// Prompt for name
  Future<void> _promptForName() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.name;
    _notifyStepChanged();

    await _voiceService.speak(_s.askName);

    final result = await _listenForInput(
      validator: (text) => text.isNotEmpty,
      errorMessage: _s.askName,
    );

    if (result != null) {
      _name = _capitalizeWords(result);
      _notifyDataChanged();
      await _voiceService.speak(_s.gotName(_name!));
    }
  }

  /// Prompt for relationship
  Future<void> _promptForRelationship() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.relationship;
    _notifyStepChanged();

    await _voiceService.speak(_s.askRelationship);

    final result = await _listenForInput(
      validator: (text) => text.isNotEmpty,
      errorMessage: _s.askRelationship,
    );

    if (result != null) {
      _relationship = _capitalizeWords(result);
      _notifyDataChanged();
      await _voiceService.speak(_s.gotRelationship(_relationship!));
    }
  }

  /// Prompt for photo
  Future<void> _promptForPhoto() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.photo;
    _notifyStepChanged();

    await _voiceService.speak(_s.askPhoto);

    bool photoTaken = false;
    int attempts = 0;
    const maxAttempts = 3;

    while (!photoTaken && attempts < maxAttempts && !_isCancelled) {
      final result = await _listenForInput(
        validator: (text) {
          final normalized = text.toLowerCase().trim();
          return normalized.contains('take') ||
              normalized.contains('photo') ||
              normalized.contains('camera') ||
              normalized.contains('capture') ||
              normalized.contains('click') ||
              normalized.contains('snap') ||
              normalized.contains('skip');
        },
        errorMessage: _s.askPhoto,
      );

      if (result == null) break;

      final normalized = result.toLowerCase().trim();

      if (normalized.contains('skip')) {
        await _voiceService.speak(_s.skipPhoto);
        photoTaken = true;
      } else {
        // Open voice-controlled camera
        try {
          final File? captured = await onOpenCamera?.call();

          if (captured != null) {
            _photo = captured;
            _notifyDataChanged();
            await _voiceService.speak(_s.photoTaken);
            photoTaken = true;
          } else {
            attempts++;
            if (attempts < maxAttempts) {
              await _voiceService.speak(
                'No photo taken. Say take photo to try again, or skip.',
              );
            } else {
              await _voiceService.speak(_s.skipPhoto);
              photoTaken = true;
            }
          }
        } catch (e) {
          debugPrint('[VoiceRelativeFlow] Camera error: $e');
          attempts++;
          if (attempts < maxAttempts) {
            await _voiceService.speak(
              'Camera error. Say take photo to try again, or skip.',
            );
          } else {
            await _voiceService.speak(_s.skipPhoto);
            photoTaken = true;
          }
        }
      }
    }
  }

  /// Prompt for notes
  Future<void> _promptForNotes() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.notes;
    _notifyStepChanged();

    await _voiceService.speak(_s.askNotes);

    final result = await _listenForInput(
      validator: (text) => true, // Notes are optional
      errorMessage: _s.askNotes,
    );

    if (result != null) {
      final normalized = result.toLowerCase().trim();
      if (normalized.contains('skip') || normalized.contains('no')) {
        await _voiceService.speak(_s.noNotes);
      } else {
        _notes = result;
        _notifyDataChanged();
        await _voiceService.speak(_s.gotNotes);
      }
    }
  }

  /// Prompt for confirmation
  Future<void> _promptForConfirmation() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.confirm;
    _notifyStepChanged();

    await _voiceService.speak(_s.confirmPrompt(_name!, _relationship!));

    bool confirmed = false;
    int attempts = 0;
    const maxAttempts = 3;

    while (!confirmed && attempts < maxAttempts && !_isCancelled) {
      final result = await _listenForInput(
        validator: (text) {
          final normalized = text.toLowerCase().trim();
          // Accept any affirmative or negative word — validator is intentionally
          // wide so Whisper mis-transcriptions don't block the flow.
          return normalized.contains('done') ||
              normalized.contains('do') ||
              normalized.contains('don') ||
              normalized.contains('yes') ||
              normalized.contains('yeah') ||
              normalized.contains('yep') ||
              normalized.contains('ok') ||
              normalized.contains('okay') ||
              normalized.contains('confirm') ||
              normalized.contains('save') ||
              normalized.contains('cancel') ||
              normalized.contains('no');
        },
        errorMessage: 'Say done or yes to confirm, or cancel to discard.',
      );

      if (result == null) break;

      final normalized = result.toLowerCase().trim();

      // Accept a wide range of Whisper transcriptions for "done" / "yes"
      if (normalized.contains('done') ||
          normalized.contains('do') ||
          normalized.contains('don') ||
          normalized.contains('yes') ||
          normalized.contains('yeah') ||
          normalized.contains('yep') ||
          normalized.contains('yup') ||
          normalized.contains('ok') ||
          normalized.contains('okay') ||
          normalized.contains('confirm') ||
          normalized.contains('save') ||
          normalized.contains('siv') ||
          normalized.contains('sav') ||
          normalized.contains('safe') ||
          normalized == 's') {
        confirmed = true;
      } else if (normalized.contains('cancel') || normalized.contains('no')) {
        _isCancelled = true;
        await _voiceService.speak(_s.cancelled);
        return;
      } else {
        attempts++;
      }
    }

    if (!confirmed && !_isCancelled) {
      await _voiceService.speak(_s.cancelled);
      _isCancelled = true;
    }
  }

  /// Save the relative
  Future<RelativeModel?> _saveRelative() async {
    if (_isCancelled || _name == null || _relationship == null) {
      return null;
    }

    _currentStep = VoiceRelativeStep.saving;
    _notifyStepChanged();

    await _voiceService.speak(_s.saving);

    try {
      if (_photo == null) {
        await _voiceService.speak(_s.photoRequired);
        return null;
      }

      final relative = await _repository.addRelative(
        name: _name!,
        relationship: _relationship!,
        image: _photo!,
        notes: _notes,
      );

      return relative;
    } catch (e) {
      debugPrint('[VoiceRelativeFlow] Save error: $e');
      await _voiceService.speak('Failed to save. Please try again later.');
      return null;
    }
  }

  /// Listen for user input with validation
  Future<String?> _listenForInput({
    required bool Function(String) validator,
    required String errorMessage,
    int maxAttempts = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts && !_isCancelled) {
      final completer = Completer<String?>();

      _isListening = true;
      _notifyListeningChanged();

      // Brief pause so any TTS audio has cleared the mic before recording starts
      await Future.delayed(const Duration(milliseconds: 450));

      await _voiceService.startListening(
        // Never auto-resume hotword between flow steps — the explicit
        // resumeHotwordListening() call in relatives_screen handles restart.
        autoResumeHotword: false,
        onResult: (text) {
          _isListening = false;
          _notifyListeningChanged();

          if (text.isEmpty) {
            completer.complete(null);
            return;
          }

          // Check for cancel command
          final normalized = text.toLowerCase().trim();
          if (normalized.contains('cancel') ||
              (normalized.contains('stop') &&
                  normalized.contains('listening'))) {
            _isCancelled = true;
            completer.complete(null);
            return;
          }

          // Validate input
          if (validator(text)) {
            completer.complete(text);
          } else {
            completer.complete(null);
          }
        },
        onError: (error) {
          _isListening = false;
          _notifyListeningChanged();
          completer.complete(null);
        },
        listenFor: const Duration(seconds: 15),
      );

      final result = await completer.future;

      if (_isCancelled) {
        await _voiceService.speak(_s.cancelled);
        return null;
      }

      if (result != null) {
        return result;
      }

      attempts++;
      if (attempts < maxAttempts) {
        await _voiceService.speak(errorMessage);
      }
    }

    if (!_isCancelled) {
      await _voiceService.speak(_s.cancelled);
      _isCancelled = true;
    }

    return null;
  }

  /// Capitalize first letter of each word
  String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Notify step changed
  void _notifyStepChanged() {
    onStepChanged?.call(_currentStep);
  }

  /// Notify listening state changed
  void _notifyListeningChanged() {
    onListeningChanged?.call(_isListening);
  }

  /// Notify data changed
  void _notifyDataChanged() {
    onDataChanged?.call(_name ?? '', _relationship ?? '', _photo, _notes);
  }

  /// Cancel the flow
  void cancel() {
    _isCancelled = true;
    _voiceService.stopListening();
  }

  /// Get current step
  VoiceRelativeStep get currentStep => _currentStep;

  /// Check if listening
  bool get isListening => _isListening;

  /// Check if cancelled
  bool get isCancelled => _isCancelled;

  /// Get collected data
  Map<String, dynamic> get data => {
    'name': _name,
    'relationship': _relationship,
    'photo': _photo,
    'notes': _notes,
  };
}
