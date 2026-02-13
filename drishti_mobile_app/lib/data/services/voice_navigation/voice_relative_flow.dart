/// Voice-Guided Relative Addition Flow
///
/// Handles hands-free relative addition with smooth STT conversation flow.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../voice_service.dart';
import '../../repositories/relatives_repository.dart';
import '../../models/relative_model.dart';

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
  final ImagePicker _picker = ImagePicker();

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
  final void Function(String name, String relationship, File? photo, String? notes)? onDataChanged;

  VoiceRelativeFlow({
    required VoiceService voiceService,
    required RelativesRepository repository,
    this.onStepChanged,
    this.onListeningChanged,
    this.onDataChanged,
  })  : _voiceService = voiceService,
        _repository = repository;

  /// Start the voice-guided flow
  Future<VoiceRelativeFlowResult> start() async {
    try {
      _currentStep = VoiceRelativeStep.welcome;
      _isCancelled = false;
      _notifyStepChanged();

      // Welcome message
      await _voiceService.speak(
        'Let\'s add a new relative. I\'ll guide you through each step. '
        'You can say "skip" to skip optional fields, or "cancel" to stop at any time.',
      );

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
        await _voiceService.speak(
          '$_name has been added successfully as your $_relationship.',
        );
        return VoiceRelativeFlowResult(relative: relative);
      } else {
        return const VoiceRelativeFlowResult(
          error: 'Failed to save relative',
        );
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

    await _voiceService.speak('What is the person\'s name?');

    final result = await _listenForInput(
      validator: (text) => text.isNotEmpty,
      errorMessage: 'I didn\'t catch the name. Please say the name again.',
    );

    if (result != null) {
      _name = _capitalizeWords(result);
      _notifyDataChanged();
      await _voiceService.speak('Got it. Name is $_name.');
    }
  }

  /// Prompt for relationship
  Future<void> _promptForRelationship() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.relationship;
    _notifyStepChanged();

    await _voiceService.speak(
      'What is their relationship to you? For example, mother, father, friend, or sibling.',
    );

    final result = await _listenForInput(
      validator: (text) => text.isNotEmpty,
      errorMessage: 'I didn\'t catch the relationship. Please say it again.',
    );

    if (result != null) {
      _relationship = _capitalizeWords(result);
      _notifyDataChanged();
      await _voiceService.speak('Relationship set to $_relationship.');
    }
  }

  /// Prompt for photo
  Future<void> _promptForPhoto() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.photo;
    _notifyStepChanged();

    await _voiceService.speak(
      'Now let\'s take a photo. Say "take photo" to open the camera, or "skip" if you want to add it later.',
    );

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
              normalized.contains('skip');
        },
        errorMessage: 'Please say "take photo" to capture an image, or "skip" to continue without a photo.',
      );

      if (result == null) break;

      final normalized = result.toLowerCase().trim();

      if (normalized.contains('skip')) {
        await _voiceService.speak('Skipping photo. You can add it later.');
        photoTaken = true;
      } else if (normalized.contains('take') ||
          normalized.contains('photo') ||
          normalized.contains('camera')) {
        await _voiceService.speak('Opening camera now.');
        
        try {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85,
          );

          if (image != null) {
            _photo = File(image.path);
            _notifyDataChanged();
            await _voiceService.speak('Photo captured successfully.');
            photoTaken = true;
          } else {
            attempts++;
            if (attempts < maxAttempts) {
              await _voiceService.speak(
                'No photo taken. Say "take photo" to try again, or "skip" to continue.',
              );
            } else {
              await _voiceService.speak('Skipping photo for now.');
              photoTaken = true;
            }
          }
        } catch (e) {
          debugPrint('[VoiceRelativeFlow] Camera error: $e');
          attempts++;
          if (attempts < maxAttempts) {
            await _voiceService.speak(
              'Camera error. Say "take photo" to try again, or "skip" to continue.',
            );
          } else {
            await _voiceService.speak('Skipping photo due to camera issues.');
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

    await _voiceService.speak(
      'Would you like to add any notes? Say the notes, or say "skip" to continue.',
    );

    final result = await _listenForInput(
      validator: (text) => true, // Notes are optional
      errorMessage: 'I didn\'t catch that. Say your notes, or "skip" to continue.',
    );

    if (result != null) {
      final normalized = result.toLowerCase().trim();
      if (normalized.contains('skip') || normalized.contains('no')) {
        await _voiceService.speak('No notes added.');
      } else {
        _notes = result;
        _notifyDataChanged();
        await _voiceService.speak('Notes added.');
      }
    }
  }

  /// Prompt for confirmation
  Future<void> _promptForConfirmation() async {
    if (_isCancelled) return;

    _currentStep = VoiceRelativeStep.confirm;
    _notifyStepChanged();

    final photoStatus = _photo != null ? 'with photo' : 'without photo';
    final notesStatus = _notes != null && _notes!.isNotEmpty ? 'with notes' : '';
    
    await _voiceService.speak(
      'Ready to save. Name: $_name, Relationship: $_relationship, $photoStatus $notesStatus. '
      'Say "save" to confirm, or "cancel" to discard.',
    );

    bool confirmed = false;
    int attempts = 0;
    const maxAttempts = 3;

    while (!confirmed && attempts < maxAttempts && !_isCancelled) {
      final result = await _listenForInput(
        validator: (text) {
          final normalized = text.toLowerCase().trim();
          return normalized.contains('save') ||
              normalized.contains('confirm') ||
              normalized.contains('yes') ||
              normalized.contains('cancel') ||
              normalized.contains('no');
        },
        errorMessage: 'Please say "save" to confirm, or "cancel" to discard.',
      );

      if (result == null) break;

      final normalized = result.toLowerCase().trim();

      if (normalized.contains('save') ||
          normalized.contains('confirm') ||
          normalized.contains('yes')) {
        confirmed = true;
      } else if (normalized.contains('cancel') || normalized.contains('no')) {
        _isCancelled = true;
        await _voiceService.speak('Cancelled. Relative not saved.');
        return;
      } else {
        attempts++;
      }
    }

    if (!confirmed && !_isCancelled) {
      await _voiceService.speak('No confirmation received. Cancelling.');
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

    await _voiceService.speak('Saving relative information.');

    try {
      // If no photo, we need to handle this case
      // For now, we'll require a photo or use a placeholder
      if (_photo == null) {
        // Create a temporary placeholder or skip photo requirement
        // For this implementation, we'll return null if no photo
        await _voiceService.speak(
          'A photo is required to save the relative. Please try again with a photo.',
        );
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

      await _voiceService.startListening(
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
              (normalized.contains('stop') && normalized.contains('listening'))) {
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
        await _voiceService.speak('Cancelled.');
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
      await _voiceService.speak('Too many attempts. Cancelling.');
      _isCancelled = true;
    }

    return null;
  }

  /// Capitalize first letter of each word
  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
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
