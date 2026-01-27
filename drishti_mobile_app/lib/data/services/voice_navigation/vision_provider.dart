import 'dart:typed_data';
import '../../models/voice_navigation/vision_result.dart';
import '../../models/voice_navigation/safety_result.dart';

/// Abstract interface for vision capture and analysis
/// 
/// This interface defines the contract for vision providers that can capture
/// and analyze visual information. Implementations include:
/// - PhoneVisionProvider: Uses device camera
/// - RaspberryPiVisionProvider: Uses Raspberry Pi camera (future)
/// 
/// Requirements: 4.1, 4.7
abstract class VisionProvider {
  /// Capture and analyze the current view
  /// 
  /// Captures a frame from the camera and analyzes it using a VLM
  /// (Vision Language Model). The analysis can be customized with an
  /// optional prompt.
  /// 
  /// [customPrompt] Optional custom prompt for the VLM analysis
  /// 
  /// Returns a [VisionResult] containing the description and detected objects
  Future<VisionResult> analyzeCurrentView({String? customPrompt});
  
  /// Detect obstacles in the current view
  /// 
  /// Specialized analysis focused on identifying obstacles that may
  /// impede navigation or movement.
  /// 
  /// Returns a [VisionResult] with obstacle information
  Future<VisionResult> detectObstacles();
  
  /// Identify people in the current view
  /// 
  /// Specialized analysis focused on detecting and identifying people.
  /// This may include face recognition for known relatives.
  /// 
  /// Returns a [VisionResult] with people information
  Future<VisionResult> identifyPeople();
  
  /// Read text in the current view
  /// 
  /// Specialized analysis focused on extracting and reading text
  /// from signs, labels, documents, etc.
  /// 
  /// Returns a [VisionResult] with extracted text
  Future<VisionResult> readText();
  
  /// Check for safety hazards in the current view
  /// 
  /// Analyzes the scene for dangerous objects or situations that
  /// require immediate attention (vehicles, stairs, holes, etc.).
  /// 
  /// Returns a [SafetyResult] with hazard information and warnings
  Future<SafetyResult> checkForHazards();
  
  /// Get the current camera frame without analysis
  /// 
  /// Returns the raw camera frame as bytes, or null if unavailable.
  /// Useful for caching frames for follow-up questions.
  Future<Uint8List?> getCurrentFrame();
}
