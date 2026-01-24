/// VLM Camera Screen
///
/// Demonstrates using the local VLM for real-time image analysis.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/vlm_provider.dart';
import '../../../data/services/local_vlm_service.dart';

class VLMCameraScreen extends StatefulWidget {
  const VLMCameraScreen({super.key});

  @override
  State<VLMCameraScreen> createState() => _VLMCameraScreenState();
}

class _VLMCameraScreenState extends State<VLMCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _analysisResult;
  bool _isAnalyzing = false;
  String _selectedMode = 'describe';

  final Map<String, String> _analysisPrompts = {
    'describe': 'Describe what you see in this image in detail.',
    'accessibility': '''Describe this image for a visually impaired person. 
Include the main subject, people present, important objects, colors, and any visible text.''',
    'navigation':
        '''Describe this scene for someone who needs navigation assistance.
Focus on obstacles, pathways, doors, stairs, people, and landmarks.''',
    'objects': 'List all objects you can identify in this image.',
    'text': 'Read and transcribe any text visible in this image.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Local AI Vision'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<VLMProvider>(
        builder: (context, vlm, child) {
          if (!vlm.isReady) {
            return _buildNotReadyState(vlm);
          }
          return _buildReadyState(vlm);
        },
      ),
    );
  }

  Widget _buildNotReadyState(VLMProvider vlm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_rounded,
              size: 80,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              vlm.status == VLMStatus.downloading
                  ? 'Downloading AI Model...'
                  : vlm.status == VLMStatus.loading
                  ? 'Loading AI Model...'
                  : 'AI Model Not Ready',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (vlm.status == VLMStatus.downloading ||
                vlm.status == VLMStatus.loading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: vlm.progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(vlm.progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => vlm.ensureReady(),
                icon: const Icon(Icons.download),
                label: const Text('Download Model (~3GB)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            if (vlm.error != null) ...[
              const SizedBox(height: 16),
              Text(
                vlm.error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadyState(VLMProvider vlm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select an image to analyze',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // Image selection buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlueLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Analysis mode selector
          const Text(
            'Analysis Mode',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _analysisPrompts.keys.map((mode) {
              final isSelected = _selectedMode == mode;
              return ChoiceChip(
                label: Text(mode.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedMode = mode);
                },
                selectedColor: AppColors.primaryBlue,
                backgroundColor: Colors.white12,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Analyze button
          ElevatedButton(
            onPressed: _selectedImage != null && !_isAnalyzing
                ? () => _analyzeImage(vlm)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Analyzing...'),
                    ],
                  )
                : const Text(
                    'Analyze Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),

          const SizedBox(height: 24),

          // Results
          if (_analysisResult != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _analysisResult!,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _analysisResult = null;
      });
    }
  }

  Future<void> _analyzeImage(VLMProvider vlm) async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final response = await vlm.analyzeImageFromFile(
        imageFile: _selectedImage!,
        prompt: _analysisPrompts[_selectedMode],
      );

      setState(() {
        _analysisResult = response.text;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _analysisResult = 'Error: $e';
        _isAnalyzing = false;
      });
    }
  }
}
