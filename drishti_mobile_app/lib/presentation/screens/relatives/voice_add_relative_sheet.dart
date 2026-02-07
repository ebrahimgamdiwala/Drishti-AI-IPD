/// Drishti App - Voice-Guided Add Relative Sheet
///
/// Voice-controlled form for adding relatives with step-by-step guidance.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/relative_model.dart';
import '../../../data/repositories/relatives_repository.dart';
import '../../../data/services/voice_service.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/buttons/gradient_button.dart';

enum VoiceFormStep {
  welcome,
  name,
  relationship,
  photo,
  notes,
  confirm,
  saving,
  complete,
}

/// Voice-guided sheet for adding relatives
class VoiceAddRelativeSheet extends StatefulWidget {
  const VoiceAddRelativeSheet({super.key});

  @override
  State<VoiceAddRelativeSheet> createState() => _VoiceAddRelativeSheetState();
}

class _VoiceAddRelativeSheetState extends State<VoiceAddRelativeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _notesController = TextEditingController();
  final RelativesRepository _repository = RelativesRepository();
  final VoiceService _voiceService = VoiceService();
  final ImagePicker _picker = ImagePicker();

  VoiceFormStep _currentStep = VoiceFormStep.welcome;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startVoiceGuidance();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startVoiceGuidance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _voiceService.speak(
      'Let\'s add a new relative. I\'ll guide you through each step. Say "stop listening" at any time to cancel.',
    );
    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      _moveToNextStep();
    }
  }

  Future<void> _moveToNextStep() async {
    if (!mounted) return;

    switch (_currentStep) {
      case VoiceFormStep.welcome:
        setState(() => _currentStep = VoiceFormStep.name);
        await _promptForName();
        break;
      case VoiceFormStep.name:
        if (_nameController.text.isEmpty) {
          await _voiceService.speak('Please provide a name first');
          await Future.delayed(const Duration(milliseconds: 1500));
          await _promptForName();
        } else {
          setState(() => _currentStep = VoiceFormStep.relationship);
          await _promptForRelationship();
        }
        break;
      case VoiceFormStep.relationship:
        if (_relationshipController.text.isEmpty) {
          await _voiceService.speak('Please provide a relationship first');
          await Future.delayed(const Duration(milliseconds: 1500));
          await _promptForRelationship();
        } else {
          setState(() => _currentStep = VoiceFormStep.photo);
          await _promptForPhoto();
        }
        break;
      case VoiceFormStep.photo:
        if (_selectedImage == null) {
          await _voiceService.speak('Please take a photo first');
          await Future.delayed(const Duration(milliseconds: 1500));
          await _promptForPhoto();
        } else {
          setState(() => _currentStep = VoiceFormStep.notes);
          await _promptForNotes();
        }
        break;
      case VoiceFormStep.notes:
        setState(() => _currentStep = VoiceFormStep.confirm);
        await _promptForConfirmation();
        break;
      case VoiceFormStep.confirm:
        await _saveRelative();
        break;
      default:
        break;
    }
  }

  Future<void> _promptForName() async {
    if (!mounted) return;
    
    await _voiceService.speak('What is the person\'s name? Please speak clearly.');
    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    await _listenForInput((text) async {
      if (!mounted) return;
      
      setState(() {
        _nameController.text = text;
      });
      await _voiceService.speak('Got it. Name is $text');
      await Future.delayed(const Duration(milliseconds: 2000));
    }, shouldAutoAdvance: true);
  }

  Future<void> _promptForRelationship() async {
    if (!mounted) return;
    
    await _voiceService.speak(
      'What is their relationship to you? For example, mother, father, friend, or sibling.',
    );
    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 4000));
    
    if (!mounted) return;
    await _listenForInput((text) async {
      if (!mounted) return;
      
      setState(() {
        _relationshipController.text = text;
      });
      await _voiceService.speak('Relationship set to $text');
      await Future.delayed(const Duration(milliseconds: 2000));
    }, shouldAutoAdvance: true);
  }

  Future<void> _promptForPhoto() async {
    if (!mounted) return;
    
    await _voiceService.speak(
      'Now let\'s take a photo. Say "take photo" to open the camera, or "skip" to continue without a photo.',
    );
    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 4000));
    
    if (!mounted) return;
    await _listenForInput((text) async {
      if (!mounted) return;
      
      final normalized = text.toLowerCase().trim();
      if (normalized.contains('take') ||
          normalized.contains('photo') ||
          normalized.contains('camera')) {
        await _pickImage();
      } else if (normalized.contains('skip')) {
        await _voiceService.speak('Skipping photo');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) _moveToNextStep();
      } else {
        await _voiceService.speak('Say "take photo" or "skip"');
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) await _promptForPhoto();
      }
    }, shouldAutoAdvance: false);
  }

  Future<void> _promptForNotes() async {
    if (!mounted) return;
    
    await _voiceService.speak(
      'Would you like to add any notes? Say the notes, or say "skip" to continue.',
    );
    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if (!mounted) return;
    await _listenForInput((text) async {
      if (!mounted) return;
      
      final normalized = text.toLowerCase().trim();
      if (normalized.contains('skip') || normalized.contains('no')) {
        await _voiceService.speak('No notes added');
        await Future.delayed(const Duration(milliseconds: 1500));
      } else {
        setState(() {
          _notesController.text = text;
        });
        await _voiceService.speak('Notes added');
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }, shouldAutoAdvance: true);
  }

  Future<void> _promptForConfirmation() async {
    if (!mounted) return;
    
    final summary = 'Ready to save. Name: ${_nameController.text}, '
        'Relationship: ${_relationshipController.text}. '
        'Say "save" to confirm, or "cancel" to go back.';
    
    await _voiceService.speak(summary);
    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 4000));
    
    if (!mounted) return;
    await _listenForInput((text) async {
      if (!mounted) return;
      
      final normalized = text.toLowerCase().trim();
      if (normalized.contains('save') || normalized.contains('confirm')) {
        await _saveRelative();
      } else if (normalized.contains('cancel') || normalized.contains('back')) {
        await _voiceService.speak('Cancelled');
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) Navigator.pop(context);
      } else {
        await _voiceService.speak('Say "save" or "cancel"');
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) await _promptForConfirmation();
      }
    }, shouldAutoAdvance: false);
  }

  Future<void> _listenForInput(
    Function(String) onResult, {
    bool shouldAutoAdvance = false,
  }) async {
    if (!mounted) return;
    
    setState(() => _isListening = true);
    
    await _voiceService.startListening(
      onResult: (text) async {
        if (!mounted) return;
        
        setState(() => _isListening = false);
        
        if (text.isEmpty) return;
        
        // Check for stop command
        final normalized = text.toLowerCase().trim();
        if (normalized.contains('stop listening') || 
            normalized.contains('stop') && normalized.contains('listening')) {
          await _voiceService.speak('Stopping voice input. Closing form.');
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) Navigator.pop(context);
          return;
        }
        
        await onResult(text);
        
        // Auto-advance if requested
        if (shouldAutoAdvance && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _moveToNextStep();
        }
      },
      onError: (error) async {
        if (!mounted) return;
        
        setState(() => _isListening = false);
        await _voiceService.speak('Sorry, I didn\'t catch that. Please try again.');
        await Future.delayed(const Duration(milliseconds: 2000));
        
        if (mounted) {
          await _listenForInput(onResult, shouldAutoAdvance: shouldAutoAdvance);
        }
      },
      listenFor: const Duration(seconds: 15),
    );
  }

  Future<void> _pickImage() async {
    await _voiceService.speak('Opening camera');
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _voiceService.speak('Photo captured successfully');
      await Future.delayed(const Duration(milliseconds: 1000));
      _moveToNextStep();
    } else {
      await _voiceService.speak('No photo taken. Say "take photo" to try again, or "skip" to continue.');
      await _promptForPhoto();
    }
  }

  Future<void> _saveRelative() async {
    if (!_formKey.currentState!.validate()) {
      await _voiceService.speak('Please fill in all required fields');
      return;
    }

    if (_selectedImage == null) {
      await _voiceService.speak('A photo is required. Let\'s take one now.');
      setState(() => _currentStep = VoiceFormStep.photo);
      await _promptForPhoto();
      return;
    }

    setState(() {
      _currentStep = VoiceFormStep.saving;
      _isLoading = true;
    });

    await _voiceService.speak('Saving relative information');

    try {
      final result = await _repository.addRelative(
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        image: _selectedImage!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      setState(() => _currentStep = VoiceFormStep.complete);
      await _voiceService.speak(
        '${result.name} has been added successfully as your ${result.relationship}',
      );

      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      await _voiceService.speak('Failed to save. Please try again.');
      setState(() {
        _currentStep = VoiceFormStep.confirm;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice-Guided Add Relative',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStepDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Listening indicator
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Listening...',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Photo preview
                    GestureDetector(
                      onTap: _currentStep == VoiceFormStep.photo ? _pickImage : null,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.lightInputFill,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentStep == VoiceFormStep.photo
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.withValues(alpha: 0.3),
                            width: _currentStep == VoiceFormStep.photo ? 3 : 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: AppColors.primaryBlue,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Photo',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: 'Speak the name',
                      prefixIcon: Icons.person_outline,
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _relationshipController,
                      label: AppStrings.relationship,
                      hint: 'Speak the relationship',
                      prefixIcon: Icons.family_restroom,
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Relationship is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _notesController,
                      label: AppStrings.notes,
                      hint: 'Optional notes',
                      prefixIcon: Icons.notes,
                      maxLines: 3,
                      enabled: false,
                    ),

                    const SizedBox(height: 32),

                    if (_currentStep == VoiceFormStep.saving ||
                        _currentStep == VoiceFormStep.complete)
                      GradientButton(
                        text: _currentStep == VoiceFormStep.complete
                            ? 'Complete'
                            : 'Saving...',
                        isLoading: _isLoading,
                        onPressed: () {},
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case VoiceFormStep.welcome:
        return 'Getting ready...';
      case VoiceFormStep.name:
        return 'Step 1: Speak the name';
      case VoiceFormStep.relationship:
        return 'Step 2: Speak the relationship';
      case VoiceFormStep.photo:
        return 'Step 3: Take a photo';
      case VoiceFormStep.notes:
        return 'Step 4: Add notes (optional)';
      case VoiceFormStep.confirm:
        return 'Step 5: Confirm details';
      case VoiceFormStep.saving:
        return 'Saving...';
      case VoiceFormStep.complete:
        return 'Complete!';
    }
  }
}
