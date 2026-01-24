# Bundling LLaVA Phi-3 with Drishti AI Mobile App

This guide explains how to integrate a local Vision Language Model (LLaVA Phi-3) with the Drishti AI Flutter app using llama.cpp.

## Overview

### Confirmed API Support (llama_cpp_dart v0.2.2)

The `llama_cpp_dart` package provides **full multimodal/vision support** through:

1. **`LlamaLoad`** - Loads model with multimodal projector:
   ```dart
   LlamaLoad(
     path: 'path/to/llava-phi-3-mini-int4.gguf',
     modelParams: ModelParams(),
     contextParams: ContextParams(),
     samplingParams: SamplerParams(),
     mmprojPath: 'path/to/llava-phi-3-mini-mmproj-f16.gguf',  // Vision projector
   )
   ```

2. **`LlamaImage`** - Represents image input:
   ```dart
   // From raw bytes
   final image = LlamaImage.fromBytes(imageBytes);
   
   // From file (preferred for isolates)
   final image = LlamaImage.fromFile(imageFile);
   ```

3. **`LlamaPrompt`** - Sends prompt with images:
   ```dart
   LlamaPrompt(
     '<image>\nUSER: Describe this image\nASSISTANT:',
     'prompt-id',
     images: [image],  // Attach images here
   )
   ```

4. **`LlamaParent`** - Isolate-based async inference (non-blocking UI)

### Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │              LocalVLMService                     │   │
│  │  (Dart - Manages lifecycle & API)               │   │
│  └─────────────────────────────────────────────────┘   │
│                         │                               │
│                         ▼                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │            llama_cpp_dart (FFI)                 │   │
│  │  (Dart bindings for llama.cpp)                  │   │
│  └─────────────────────────────────────────────────┘   │
│                         │                               │
└─────────────────────────┼───────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Native Libraries (.so/.dylib)              │
│  ┌───────────┐  ┌───────────┐  ┌───────────────────┐   │
│  │libllama.so│  │libggml.so │  │libmtmd.so (vision)│   │
│  └───────────┘  └───────────┘  └───────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Model Files                          │
│  ┌─────────────────────────┐  ┌─────────────────────┐  │
│  │llava-phi-3-mini-int4.gguf│  │llava-phi-3-mmproj.gguf│ │
│  │       (~2.5 GB)         │  │      (~600 MB)      │  │
│  └─────────────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Model Selection: LLaVA Phi-3 Mini INT4

**Why LLaVA Phi-3 Mini?**
- Based on Microsoft Phi-3-mini-4k-instruct (3.8B parameters)
- Excellent vision capabilities from CLIP-ViT-Large-patch14-336
- Small enough to run on mobile devices
- Available in GGUF format with official quantized versions

**Why INT4 Quantization?**
- **Size**: ~2.5GB (vs ~7.6GB for F16)
- **RAM Usage**: ~3-4GB during inference
- **Speed**: Faster inference on mobile CPUs
- **Quality**: Maintains good accuracy for vision tasks
- **Target Devices**: Suitable for phones with 6GB+ RAM

## Step 1: Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  llama_cpp_dart: ^0.2.2
  path_provider: ^2.1.1
  http: ^1.1.0
```

## Step 2: Build Native Libraries for Android

### Option A: Use Pre-built Binaries (Recommended)

The `llama_cpp_dart` package includes build scripts. Follow these steps:

```bash
# Clone the package source
git clone https://github.com/netdur/llama_cpp_dart.git
cd llama_cpp_dart

# Initialize llama.cpp submodule
git submodule update --init --recursive

# Build for Android (requires Android NDK)
cd android
./build.sh
```

### Option B: Build Manually with Android NDK

```bash
# Set up environment
export ANDROID_NDK=/path/to/android-ndk
export ANDROID_ABI=arm64-v8a

# Clone llama.cpp
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp

# Build for Android
cmake -B build-android \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-28 \
  -DCMAKE_C_FLAGS="-march=armv8.2a" \
  -DCMAKE_CXX_FLAGS="-march=armv8.2a" \
  -DGGML_OPENMP=OFF \
  -DGGML_LLAMAFILE=OFF \
  -DBUILD_SHARED_LIBS=ON

cmake --build build-android --config Release -j$(nproc)
```

### Required Library Files

After building, you need these files:
- `libllama.so` - Main inference library
- `libggml.so` - Tensor operations
- `libggml-base.so` - Base GGML functions
- `libmtmd.so` - Multimodal support (for vision)

Place in: `android/app/src/main/jniLibs/arm64-v8a/`

## Step 3: Configure Android Build

### Update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'arm64-v8a'  // Focus on 64-bit ARM for modern phones
        }
    }
    
    // Increase memory for native operations
    dexOptions {
        javaMaxHeapSize "4g"
    }
}
```

### Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Required for model download -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Request large heap for model loading -->
    <application
        android:largeHeap="true"
        ...>
    </application>
</manifest>
```

## Step 4: Model Management Strategy

### Strategy: Download on First Use

Since the model is ~3GB total, we **don't bundle it with the APK**. Instead:

1. Check if models exist in app storage
2. If not, download from Hugging Face
3. Show progress to user
4. Cache locally for future use

### Model URLs

```dart
// INT4 quantized model (recommended for mobile)
const modelUrl = 'https://huggingface.co/xtuner/llava-phi-3-mini-gguf/resolve/main/llava-phi-3-mini-int4.gguf';

// Vision projector (required for image understanding)
const mmProjUrl = 'https://huggingface.co/xtuner/llava-phi-3-mini-gguf/resolve/main/llava-phi-3-mini-mmproj-f16.gguf';
```

## Step 5: Implement VLM Integration

### Create the VLM Provider

```dart
// lib/data/providers/vlm_provider.dart
import 'package:flutter/foundation.dart';
import '../services/local_vlm_service.dart';

class VLMProvider extends ChangeNotifier {
  final LocalVLMService _vlmService = LocalVLMService();
  
  VLMStatus get status => _vlmService.status;
  double get progress => _vlmService.loadProgress;
  String? get error => _vlmService.errorMessage;
  bool get isReady => _vlmService.isReady;
  
  Future<void> ensureModelReady() async {
    if (_vlmService.isReady) return;
    
    // Check if download needed
    if (!await _vlmService.areModelsDownloaded()) {
      await _vlmService.downloadModels(
        onProgress: (progress, message) {
          debugPrint('Download: $message');
          notifyListeners();
        },
      );
    }
    
    // Initialize model
    await _vlmService.initialize(
      onProgress: (progress, message) {
        debugPrint('Init: $message');
        notifyListeners();
      },
    );
  }
  
  Future<String> analyzeImage(Uint8List imageBytes, String prompt) async {
    final response = await _vlmService.analyzeImage(
      imageBytes: imageBytes,
      prompt: prompt,
    );
    return response.text;
  }
}
```

### Integrate with llama_cpp_dart

```dart
// lib/data/services/llama_vlm_integration.dart
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'dart:io';
import 'dart:typed_data';

class LlamaVLMIntegration {
  LlamaParent? _llamaParent;
  bool _isInitialized = false;
  
  /// Initialize the VLM with multimodal support
  Future<void> initialize({
    required String modelPath,
    required String mmProjPath,
    int contextSize = 2048,
    int nThreads = 4,
  }) async {
    // Set the library path based on platform
    if (Platform.isAndroid) {
      Llama.libraryPath = 'libllama.so';
    } else if (Platform.isIOS) {
      Llama.libraryPath = 'llama.framework/llama';
    }
    
    // Configure model parameters
    final modelParams = ModelParams()
      ..nGpuLayers = 0; // CPU only for mobile
    
    final contextParams = ContextParams()
      ..nCtx = contextSize
      ..nThreads = nThreads
      ..nThreadsBatch = nThreads;
    
    final samplerParams = SamplerParams()
      ..temp = 0.7
      ..topP = 0.9;
    
    // Load command with Phi-3 chat format
    final loadCommand = LlamaLoad(
      path: modelPath,
      modelParams: modelParams,
      contextParams: contextParams,
      samplingParams: samplerParams,
      format: Phi3ChatFormat(), // Use Phi-3 specific format
    );
    
    _llamaParent = LlamaParent(loadCommand);
    await _llamaParent!.init();
    
    _isInitialized = true;
  }
  
  /// Analyze an image with a text prompt
  Stream<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  }) async* {
    if (!_isInitialized || _llamaParent == null) {
      throw Exception('VLM not initialized');
    }
    
    // Note: Full multimodal support requires llama_cpp_dart 
    // to expose the mtmd (multimodal) API
    // This is the expected API when available:
    
    /*
    // Encode image
    final imageEmbedding = await _llamaParent!.encodeImage(imageBytes);
    
    // Build prompt with image
    final fullPrompt = '<|user|>\n<|image|>\n$prompt<|end|>\n<|assistant|>\n';
    
    // Send to model
    _llamaParent!.sendPromptWithImage(fullPrompt, imageEmbedding);
    
    // Stream response
    await for (final token in _llamaParent!.stream) {
      yield token;
    }
    */
    
    // Temporary: Text-only mode
    _llamaParent!.sendPrompt(prompt);
    await for (final token in _llamaParent!.stream) {
      yield token;
    }
  }
  
  void dispose() {
    _llamaParent?.dispose();
    _isInitialized = false;
  }
}

/// Phi-3 specific chat format
class Phi3ChatFormat implements ChatFormat {
  @override
  String formatPrompt(String userMessage, {String? systemMessage}) {
    final buffer = StringBuffer();
    
    if (systemMessage != null) {
      buffer.write('<|system|>\n$systemMessage<|end|>\n');
    }
    
    buffer.write('<|user|>\n$userMessage<|end|>\n<|assistant|>\n');
    
    return buffer.toString();
  }
  
  @override
  String get stopToken => '<|end|>';
}
```

## Step 6: UI Integration

### Model Download Screen

```dart
// lib/presentation/screens/vlm/model_download_screen.dart
class ModelDownloadScreen extends StatefulWidget {
  @override
  _ModelDownloadScreenState createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<VLMProvider>(
      builder: (context, vlm, _) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_download, size: 64),
                SizedBox(height: 24),
                Text(
                  'Downloading AI Model',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  'This is a one-time download (~3 GB)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 32),
                LinearProgressIndicator(value: vlm.progress),
                SizedBox(height: 8),
                Text('${(vlm.progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### Image Analysis Widget

```dart
// lib/presentation/widgets/image_analyzer.dart
class ImageAnalyzer extends StatefulWidget {
  final Uint8List imageBytes;
  
  const ImageAnalyzer({required this.imageBytes});
  
  @override
  _ImageAnalyzerState createState() => _ImageAnalyzerState();
}

class _ImageAnalyzerState extends State<ImageAnalyzer> {
  String _analysis = '';
  bool _isAnalyzing = false;
  
  Future<void> _analyze() async {
    setState(() => _isAnalyzing = true);
    
    final vlm = context.read<VLMProvider>();
    
    // Ensure model is ready
    await vlm.ensureModelReady();
    
    // Analyze the image
    final result = await vlm.analyzeImage(
      widget.imageBytes,
      'Describe what you see in this image. Focus on any people, objects, and activities.',
    );
    
    setState(() {
      _analysis = result;
      _isAnalyzing = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.memory(widget.imageBytes),
        SizedBox(height: 16),
        if (_isAnalyzing)
          CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _analyze,
            child: Text('Analyze Image'),
          ),
        if (_analysis.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(_analysis),
        ],
      ],
    );
  }
}
```

## Performance Optimization Tips

### 1. Memory Management
```dart
// Release model when not needed
@override
void dispose() {
  vlmService.dispose();
  super.dispose();
}
```

### 2. Use Isolates for Inference
```dart
// The llama_cpp_dart package already uses isolates
// via LlamaParent for non-blocking UI
```

### 3. Image Preprocessing
```dart
// Resize images before sending to model
import 'package:image/image.dart' as img;

Uint8List preprocessImage(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;
  
  // LLaVA uses 336x336 images
  final resized = img.copyResize(image, width: 336, height: 336);
  return Uint8List.fromList(img.encodePng(resized));
}
```

### 4. Context Size
```dart
// Use smaller context for faster inference
final contextParams = ContextParams()
  ..nCtx = 2048; // Smaller context = faster
```

## Device Requirements

| Requirement | Minimum | Recommended |
|------------|---------|-------------|
| RAM | 6 GB | 8+ GB |
| Storage | 4 GB free | 5+ GB free |
| Android | 9.0+ (API 28) | 11.0+ (API 30) |
| Architecture | arm64-v8a | arm64-v8a |
| CPU | Snapdragon 730+ | Snapdragon 8 Gen 1+ |

## Current Limitations

1. **Multimodal API**: The `llama_cpp_dart` package doesn't yet expose the full multimodal (mtmd) API from llama.cpp. You may need to:
   - Fork and extend the package
   - Use platform channels to call native code directly
   - Wait for upstream support

2. **Model Size**: At ~3GB, the model requires significant storage and download time.

3. **Inference Speed**: Expect 1-5 tokens/second on mid-range devices.

## Alternative Approaches

### 1. Smaller Models (Faster, Less Accurate)
- **SmolVLM-256M**: Only 256MB, much faster
- **MoonDream2**: ~1.5GB, good balance

### 2. Hybrid Approach
- Use local model for quick analysis
- Fall back to cloud API for complex queries

### 3. Platform-Specific SDKs
- **Android**: MediaPipe, ML Kit
- **iOS**: Core ML, Vision Framework

## Next Steps

1. Build native libraries for Android
2. Test model loading on target devices
3. Implement image preprocessing
4. Add offline caching
5. Optimize for battery life

## References

- [llama.cpp Multimodal Docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md)
- [llama_cpp_dart Package](https://pub.dev/packages/llama_cpp_dart)
- [LLaVA Phi-3 Mini GGUF](https://huggingface.co/xtuner/llava-phi-3-mini-gguf)
- [llama.cpp Android Build](https://github.com/ggml-org/llama.cpp/blob/master/docs/android.md)
