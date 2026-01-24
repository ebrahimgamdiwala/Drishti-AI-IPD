# Building Native Libraries for Local VLM

## Prerequisites

1. **Android NDK** (r25 or later)
   - Download from: https://developer.android.com/ndk/downloads
   - Or install via Android Studio → SDK Manager → SDK Tools → NDK

2. **CMake** (3.21+)
   - Install via Android Studio → SDK Manager → SDK Tools → CMake

3. **Git**

## Option A: Use Pre-built Libraries (Easiest)

Check if `llama_cpp_dart` provides pre-built binaries:

```bash
# The package may include build scripts
flutter pub cache repair
cd ~/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/
ls android/  # Check for existing .so files
```

## Option B: Build from Source

### Step 1: Clone llama.cpp

```bash
cd /tmp  # or any temp directory
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
```

### Step 2: Set Environment Variables

**Windows (PowerShell):**
```powershell
$env:ANDROID_NDK = "C:\Users\<you>\AppData\Local\Android\Sdk\ndk\<version>"
$env:CMAKE_PATH = "C:\Users\<you>\AppData\Local\Android\Sdk\cmake\<version>\bin"
```

**Linux/macOS:**
```bash
export ANDROID_NDK=$HOME/Android/Sdk/ndk/<version>
export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
```

### Step 3: Build for Android arm64-v8a

```bash
mkdir build-android-arm64
cd build-android-arm64

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DGGML_OPENMP=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF

cmake --build . --config Release -j$(nproc)
```

### Step 4: Copy Libraries to Flutter Project

```bash
# Copy the built .so files
cp libllama.so /path/to/drishti_mobile_app/android/app/src/main/jniLibs/arm64-v8a/
cp libggml.so /path/to/drishti_mobile_app/android/app/src/main/jniLibs/arm64-v8a/

# If multimodal support built separately:
cp libmtmd.so /path/to/drishti_mobile_app/android/app/src/main/jniLibs/arm64-v8a/
```

## Option C: Use Docker (Recommended for Reproducibility)

```bash
# Use the official Android NDK Docker image
docker run --rm -v $(pwd):/work -w /work \
  thyrlian/android-sdk:latest \
  bash -c "
    apt-get update && apt-get install -y cmake git
    git clone https://github.com/ggml-org/llama.cpp.git
    cd llama.cpp
    mkdir build && cd build
    cmake .. \
      -DCMAKE_TOOLCHAIN_FILE=\$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-24 \
      -DBUILD_SHARED_LIBS=ON
    make -j\$(nproc)
  "
```

## Verify Installation

After copying the `.so` files, your directory should look like:

```
android/app/src/main/jniLibs/
└── arm64-v8a/
    ├── libllama.so
    ├── libggml.so
    └── libmtmd.so  (optional, for vision)
```

## Test the Build

```bash
cd /path/to/drishti_mobile_app
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

### "libllama.so not found"
- Ensure the .so files are in the correct jniLibs path
- Check that you built for the correct ABI (arm64-v8a for modern phones)

### "undefined symbol" errors
- Rebuild llama.cpp with matching compiler flags
- Ensure all dependencies (ggml, etc.) are included

### Model loading fails
- Ensure model files are downloaded to the correct path
- Check available RAM (LLaVA needs ~4GB)
