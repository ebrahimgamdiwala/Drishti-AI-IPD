# Voice-Guided Add Relative Feature

## Overview
Implemented a voice-guided form for adding relatives that walks users through each step with voice prompts and speech recognition, plus a global "stop listening" command.

## Changes Made

### 1. Fixed Theme Toggle Issue
**File**: `drishti_mobile_app/lib/data/services/voice_navigation/voice_command_executor.dart`

**Problem**: Theme toggle was being called twice (once in `_executeToggleTheme()` and once at the end of `executeCommand()`), causing it to cancel itself out.

**Solution**: Removed duplicate `_onFeatureAction` calls from theme execution methods, letting the single call at the end of `executeCommand()` handle it properly.

### 2. Created Voice-Guided Add Relative Sheet
**File**: `drishti_mobile_app/lib/presentation/screens/relatives/voice_add_relative_sheet.dart`

**Features**:
- Step-by-step voice guidance through the form
- Automatic speech recognition for each field
- **Proper timing**: Waits for TTS to finish before listening
- **Stop listening support**: Say "stop listening" at any time to cancel
- Voice prompts for:
  - Name input
  - Relationship input
  - Photo capture
  - Optional notes
  - Confirmation
- Visual feedback showing current step
- Listening indicator when capturing voice input
- Disabled text fields (voice-only input)
- Auto-advancement between steps with proper delays
- Error recovery with retry logic

**Voice Flow**:
1. Welcome message: "Let's add a new relative. I'll guide you through each step. Say 'stop listening' at any time to cancel."
2. "What is the person's name? Please speak clearly." → Listens for name
3. "Got it. Name is [name]" → Confirms and advances
4. "What is their relationship to you? For example, mother, father, friend, or sibling." → Listens for relationship
5. "Relationship set to [relationship]" → Confirms and advances
6. "Now let's take a photo. Say 'take photo' to open the camera, or 'skip' to continue without a photo." → Listens for command
7. "Would you like to add any notes? Say the notes, or say 'skip' to continue." → Listens for notes
8. "Ready to save. Name: [name], Relationship: [relationship]. Say 'save' to confirm, or 'cancel' to go back." → Listens for confirmation
9. Saves and confirms: "[Name] has been added successfully as your [relationship]"

**Key Improvements**:
- **Timing fixes**: Added proper delays after TTS to ensure voice prompts finish before listening starts
- **Stop listening**: Users can say "stop listening" at any step to cancel the form
- **Better error handling**: Retries on speech recognition errors
- **Mounted checks**: Prevents errors when widget is disposed
- **Longer listen duration**: 15 seconds instead of 10 for more flexibility

### 3. Added Global "Stop Listening" Command
**Files**: 
- `drishti_mobile_app/lib/data/services/voice_navigation/voice_command_executor.dart`
- `drishti_mobile_app/lib/data/services/voice_navigation/voice_navigation_controller.dart`

**Features**:
- Say "stop listening" anywhere in the app to stop voice control
- Stops hotword detection
- Provides audio feedback: "Voice control stopped. Tap the microphone to start again."
- Can be reactivated by tapping the microphone button

**Commands that trigger stop**:
- "stop listening"
- "stop" (when speaking stops TTS, "stop listening" stops voice control)
- "quiet"
- "silence"

### 4. Updated Voice Command Executor
**File**: `drishti_mobile_app/lib/data/services/voice_navigation/voice_command_executor.dart`

**Changes**:
- Modified `_executeAddRelative()` to trigger voice-guided flow
- Passes `voiceGuided: true` parameter to feature action callback
- Updated `_executeStop()` to support stopping voice control
- Added more stop command variations

### 5. Updated Voice Navigation Controller
**File**: `drishti_mobile_app/lib/data/services/voice_navigation/voice_navigation_controller.dart`

**Changes**:
- Added import for `VoiceAddRelativeSheet`
- Added handling for `FeatureAction.addRelative` in `_onFeatureAction()`
- Created `_showVoiceGuidedAddRelative()` method to display the modal sheet
- Added early check for "stop listening" command in `processVoiceCommand()`
- Enhanced stop action to support both stopping speech and stopping voice control
- Fixed navigator key storage issue

## Usage

### Adding a Relative
Users can now say:
- "Add relative"
- "Add family member"
- "New relative"
- "Create relative"

The system will:
1. Open the voice-guided form
2. Announce: "Opening voice-guided form to add a new relative"
3. Guide the user through each step with voice prompts
4. Wait for TTS to finish before listening
5. Listen for voice input at each step
6. Automatically advance to the next step
7. Save the relative when confirmed

### Stopping Voice Control
Users can say:
- "Stop listening" - Stops voice control completely
- "Stop" - Stops current speech
- "Quiet" - Stops voice control
- "Silence" - Stops voice control

## Voice Commands During Form

- **Name step**: Speak the person's name clearly
- **Relationship step**: Say the relationship (e.g., "mother", "father", "friend")
- **Photo step**: Say "take photo" to open camera, or "skip" to continue
- **Notes step**: Speak notes or say "skip"/"no" to continue
- **Confirmation step**: Say "save" to confirm or "cancel" to abort
- **Any step**: Say "stop listening" to cancel and close the form

## Error Handling

- If voice input fails, the system will say "Sorry, I didn't catch that. Please try again."
- Automatic retry after 2 seconds
- If required fields are missing, appropriate prompts are given
- If photo is required but missing, user is prompted to take one
- Network errors during save are announced with retry option
- Proper cleanup when widget is disposed

## Benefits

1. **Fully Accessible**: Completely hands-free operation for visually impaired users
2. **Guided Experience**: Step-by-step voice prompts reduce confusion
3. **Error Prevention**: Validation at each step ensures data quality
4. **Natural Interaction**: Conversational flow feels intuitive
5. **Visual Feedback**: Sighted users can see progress and current step
6. **Flexible**: Users can skip optional fields like notes
7. **Proper Timing**: Waits for TTS to finish before listening
8. **Stop Control**: Users can cancel at any time with "stop listening"
9. **Reliable**: Better error handling and retry logic

## Testing

To test the feature:
1. Say "Hey Vision" to activate hotword detection
2. Say "Add relative"
3. Wait for the prompt to finish speaking
4. Speak the name when prompted
5. Wait for confirmation
6. Speak the relationship when prompted
7. Say "take photo" or "skip" when prompted
8. Optionally add notes or say "skip"
9. Say "save" to confirm
10. Verify the relative is saved successfully

To test stop listening:
1. Say "Hey Vision"
2. Say any command
3. Say "stop listening" at any time
4. Verify voice control stops
5. Tap microphone to restart

## Future Enhancements

- Support for editing relatives via voice
- Voice-guided photo retake if user is unhappy with first photo
- Support for multiple photos
- Voice search for existing relatives
- Batch import of relatives via voice
- Adjustable TTS timing based on speech rate
- Visual waveform during listening
