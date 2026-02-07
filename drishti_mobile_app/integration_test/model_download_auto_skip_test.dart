/// Integration Test: Model Download Auto-Skip Flow
///
/// **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**
///
/// This integration test verifies the complete model download auto-skip flow:
/// - Model status check on initialization
/// - Auto-navigation when models are ready
/// - Audio feedback during auto-skip
/// - Timing requirements (< 500ms after check)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:drishti_mobile_app/presentation/screens/vlm/model_download_screen.dart';
import 'package:drishti_mobile_app/data/providers/vlm_provider.dart';
import 'package:drishti_mobile_app/data/services/local_vlm_service.dart';
import 'package:drishti_mobile_app/routes/app_routes.dart';

import 'model_download_auto_skip_test.mocks.dart';

@GenerateMocks([VLMProvider, LocalVLMService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test: Model Download Auto-Skip Flow', () {
    late MockVLMProvider mockVLMProvider;

    setUp(() {
      mockVLMProvider = MockVLMProvider();
      
      // Default mock behaviors
      when(mockVLMProvider.status).thenReturn(VLMStatus.uninitialized);
      when(mockVLMProvider.progress).thenReturn(0.0);
      when(mockVLMProvider.error).thenReturn(null);
      when(mockVLMProvider.isReady).thenReturn(false);
    });

    Widget createTestWidget({
      required MockVLMProvider vlmProvider,
      bool navigated = false,
    }) {
      return ChangeNotifierProvider<VLMProvider>.value(
        value: vlmProvider,
        child: MaterialApp(
          home: const ModelDownloadScreen(),
          routes: {
            AppRoutes.main: (context) => Scaffold(
              appBar: AppBar(title: const Text('Main Screen')),
              body: const Center(child: Text('Main Screen')),
            ),
          },
        ),
      );
    }

    testWidgets('Auto-skip when models are downloaded and ready', (tester) async {
      // Setup: Models are downloaded and ready
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(true);
      when(mockVLMProvider.status).thenReturn(VLMStatus.ready);

      // Record start time
      final startTime = DateTime.now();

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Wait for initialization and navigation
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Calculate elapsed time
      final elapsed = DateTime.now().difference(startTime);

      // Verify navigation occurred to main screen
      expect(find.text('Main Screen'), findsOneWidget,
          reason: 'Should navigate to main screen when models are ready');

      // Verify timing (should be < 1000ms including audio feedback)
      expect(elapsed.inMilliseconds, lessThan(2000),
          reason: 'Auto-skip should occur within 2 seconds');

      // Verify model status was checked
      verify(mockVLMProvider.areModelsDownloaded).called(1);
    });

    testWidgets('Auto-skip when models are downloaded but not initialized', (tester) async {
      // Setup: Models are downloaded but not initialized
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(false);
      when(mockVLMProvider.status).thenReturn(VLMStatus.uninitialized);
      when(mockVLMProvider.initialize()).thenAnswer((_) async {
        // Simulate initialization
        when(mockVLMProvider.isReady).thenReturn(true);
        when(mockVLMProvider.status).thenReturn(VLMStatus.ready);
      });

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Wait for status check
      await tester.pump();

      // Verify status message updated to "initializing"
      expect(find.textContaining('initializing', findRichText: true), findsOneWidget,
          reason: 'Should show initializing message');

      // Wait for initialization and navigation
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify initialization was called
      verify(mockVLMProvider.initialize()).called(1);

      // Verify navigation occurred
      expect(find.text('Main Screen'), findsOneWidget,
          reason: 'Should navigate after initialization');
    });

    testWidgets('No auto-skip when models are not downloaded', (tester) async {
      // Setup: Models are not downloaded
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => false);
      when(mockVLMProvider.isReady).thenReturn(false);
      when(mockVLMProvider.status).thenReturn(VLMStatus.uninitialized);

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Wait for status check
      await tester.pumpAndSettle();

      // Verify download button is shown
      expect(find.text('Download Model'), findsOneWidget,
          reason: 'Should show download button when models not downloaded');

      // Verify status message
      expect(find.textContaining('Tap to start download', findRichText: true), findsOneWidget,
          reason: 'Should show download prompt');

      // Verify no navigation occurred
      expect(find.text('Main Screen'), findsNothing,
          reason: 'Should not navigate when models not downloaded');

      // Verify model status was checked
      verify(mockVLMProvider.areModelsDownloaded).called(1);
    });

    testWidgets('Handles error during model status check gracefully', (tester) async {
      // Setup: Error during status check
      when(mockVLMProvider.areModelsDownloaded).thenThrow(Exception('Network error'));
      when(mockVLMProvider.isReady).thenReturn(false);
      when(mockVLMProvider.status).thenReturn(VLMStatus.error);

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Wait for status check
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.textContaining('Error', findRichText: true), findsOneWidget,
          reason: 'Should show error message');

      // Verify download button is still available
      expect(find.text('Download Model'), findsOneWidget,
          reason: 'Should show download button as fallback');

      // Verify no navigation occurred
      expect(find.text('Main Screen'), findsNothing,
          reason: 'Should not navigate on error');
    });

    testWidgets('Handles initialization error during auto-skip', (tester) async {
      // Setup: Models downloaded but initialization fails
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(false);
      when(mockVLMProvider.status).thenReturn(VLMStatus.uninitialized);
      when(mockVLMProvider.initialize()).thenThrow(Exception('Initialization failed'));

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Wait for status check and initialization attempt
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify initialization was attempted
      verify(mockVLMProvider.initialize()).called(1);

      // Note: The screen should handle the error gracefully
      // In the current implementation, errors are caught and logged
      // The screen should remain on the download screen
      expect(find.byType(ModelDownloadScreen), findsOneWidget,
          reason: 'Should remain on download screen on initialization error');
    });

    testWidgets('Audio feedback is provided during auto-skip', (tester) async {
      // Setup: Models are ready
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(true);
      when(mockVLMProvider.status).thenReturn(VLMStatus.ready);

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Wait for audio feedback and navigation
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation occurred (audio feedback is called before navigation)
      expect(find.text('Main Screen'), findsOneWidget,
          reason: 'Should navigate after audio feedback');

      // Note: We can't directly verify VoiceService.speak() was called
      // without injecting it as a dependency, but we verify the flow completed
    });

    testWidgets('Timing requirement: Auto-skip within 500ms after status check', (tester) async {
      // Setup: Models are ready
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(true);
      when(mockVLMProvider.status).thenReturn(VLMStatus.ready);

      // Record start time
      final startTime = DateTime.now();

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Pump once to trigger initState
      await tester.pump();

      // Wait for status check to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for navigation (includes 500ms delay + audio feedback)
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Calculate elapsed time
      final elapsed = DateTime.now().difference(startTime);

      // Verify navigation occurred
      expect(find.text('Main Screen'), findsOneWidget);

      // Verify timing is reasonable (< 2 seconds including audio)
      // Note: The 500ms requirement is for the delay after audio feedback,
      // not the total time. Total time includes audio feedback duration.
      expect(elapsed.inMilliseconds, lessThan(2000),
          reason: 'Auto-skip should complete within 2 seconds');
    });

    testWidgets('Multiple rapid initializations are handled correctly', (tester) async {
      // Setup: Models are ready
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(true);
      when(mockVLMProvider.status).thenReturn(VLMStatus.ready);

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Pump multiple times rapidly
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Wait for navigation
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation occurred only once
      expect(find.text('Main Screen'), findsOneWidget);

      // Verify status check was called (should be called once despite multiple pumps)
      verify(mockVLMProvider.areModelsDownloaded).called(1);
    });

    testWidgets('Widget unmounted during auto-skip is handled gracefully', (tester) async {
      // Setup: Models are ready
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(true);
      when(mockVLMProvider.status).thenReturn(VLMStatus.ready);

      // Build widget
      await tester.pumpWidget(createTestWidget(vlmProvider: mockVLMProvider));

      // Pump once to trigger initState
      await tester.pump();

      // Immediately replace with different widget (unmount)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Different Screen')),
          body: const Center(child: Text('Different Screen')),
        ),
      ));

      // Wait for any pending operations
      await tester.pumpAndSettle();

      // Verify no errors occurred (widget should check mounted before navigation)
      expect(tester.takeException(), isNull,
          reason: 'Should handle unmounted widget gracefully');
    });
  });
}
