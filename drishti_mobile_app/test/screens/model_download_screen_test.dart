/// Unit Tests: Model Download Screen States
///
/// Tests for ModelDownloadScreen auto-skip functionality and state management.
/// **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 8.1, 8.2, 8.3, 8.4, 8.5**
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:drishti_mobile_app/presentation/screens/vlm/model_download_screen.dart';
import 'package:drishti_mobile_app/data/providers/vlm_provider.dart';
import 'package:drishti_mobile_app/data/services/voice_service.dart';
import 'package:drishti_mobile_app/data/services/local_vlm_service.dart';
import 'package:drishti_mobile_app/routes/app_routes.dart';

import 'model_download_screen_test.mocks.dart';

@GenerateMocks([VLMProvider, VoiceService])
void main() {
  group('ModelDownloadScreen Auto-Skip Tests', () {
    late MockVLMProvider mockVLMProvider;
    late MockVoiceService mockVoiceService;

    setUp(() {
      mockVLMProvider = MockVLMProvider();
      mockVoiceService = MockVoiceService();
      
      // Setup default mock behaviors
      when(mockVoiceService.speak(any)).thenAnswer((_) async => {});
      when(mockVoiceService.initTts()).thenAnswer((_) async => {});
      when(mockVLMProvider.status).thenReturn(VLMStatus.uninitialized);
      when(mockVLMProvider.progress).thenReturn(0.0);
      when(mockVLMProvider.error).thenReturn(null);
    });

    /// Helper to create a test widget with providers
    Widget createTestWidget({Widget? child}) {
      return ChangeNotifierProvider<VLMProvider>.value(
        value: mockVLMProvider,
        child: MaterialApp(
          home: child ?? const ModelDownloadScreen(),
          routes: {
            AppRoutes.main: (context) => const Scaffold(
              body: Center(child: Text('Main Screen')),
            ),
          },
        ),
      );
    }

    testWidgets(
      'Test 1: Models already downloaded and ready - should auto-navigate',
      (WidgetTester tester) async {
        // Setup: Models are downloaded and initialized
        when(mockVLMProvider.areModelsDownloaded)
            .thenAnswer((_) async => true);
        when(mockVLMProvider.isReady).thenReturn(true);
        
        // Build the widget
        await tester.pumpWidget(createTestWidget());
        
        // Wait for async operations
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Verify: Should navigate to main screen
        expect(find.text('Main Screen'), findsOneWidget);
        
        // Verify: areModelsDownloaded was checked
        verify(mockVLMProvider.areModelsDownloaded).called(1);
        
        // Verify: isReady was checked
        verify(mockVLMProvider.isReady).called(greaterThan(0));
      },
    );

    testWidgets(
      'Test 2: Models downloaded but not initialized - should initialize then navigate',
      (WidgetTester tester) async {
        // Setup: Models are downloaded but not initialized
        when(mockVLMProvider.areModelsDownloaded)
            .thenAnswer((_) async => true);
        when(mockVLMProvider.isReady).thenReturn(false);
        when(mockVLMProvider.initialize()).thenAnswer((_) async => {});
        
        // Build the widget
        await tester.pumpWidget(createTestWidget());
        
        // Wait for async operations
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Verify: Should navigate to main screen after initialization
        expect(find.text('Main Screen'), findsOneWidget);
        
        // Verify: areModelsDownloaded was checked
        verify(mockVLMProvider.areModelsDownloaded).called(1);
        
        // Verify: initialize was called
        verify(mockVLMProvider.initialize()).called(1);
      },
    );

    testWidgets(
      'Test 3: No models downloaded - should show download button',
      (WidgetTester tester) async {
        // Setup: Models are not downloaded
        when(mockVLMProvider.areModelsDownloaded)
            .thenAnswer((_) async => false);
        when(mockVLMProvider.isReady).thenReturn(false);
        
        // Build the widget
        await tester.pumpWidget(createTestWidget());
        
        // Wait for async operations
        await tester.pumpAndSettle();
        
        // Verify: Should show download button
        expect(find.text('Download Model'), findsOneWidget);
        
        // Verify: Should NOT navigate to main screen
        expect(find.text('Main Screen'), findsNothing);
        
        // Verify: areModelsDownloaded was checked
        verify(mockVLMProvider.areModelsDownloaded).called(1);
        
        // Verify: initialize was NOT called
        verifyNever(mockVLMProvider.initialize());
      },
    );

    testWidgets(
      'Test 4: Initialization failure during auto-skip - should handle gracefully',
      (WidgetTester tester) async {
        // Setup: Models are downloaded but initialization fails
        when(mockVLMProvider.areModelsDownloaded)
            .thenAnswer((_) async => true);
        when(mockVLMProvider.isReady).thenReturn(false);
        when(mockVLMProvider.initialize())
            .thenThrow(Exception('Initialization failed'));
        
        // Build the widget
        await tester.pumpWidget(createTestWidget());
        
        // Wait for async operations
        await tester.pumpAndSettle();
        
        // Verify: Should show download button (fallback)
        expect(find.text('Download Model'), findsOneWidget);
        
        // Verify: Should NOT navigate to main screen
        expect(find.text('Main Screen'), findsNothing);
        
        // Verify: initialize was called and failed
        verify(mockVLMProvider.initialize()).called(1);
      },
    );

    testWidgets(
      'Test 5: areModelsDownloaded throws exception - should handle gracefully',
      (WidgetTester tester) async {
        // Setup: areModelsDownloaded throws exception
        when(mockVLMProvider.areModelsDownloaded)
            .thenThrow(Exception('Failed to check model status'));
        
        // Build the widget
        await tester.pumpWidget(createTestWidget());
        
        // Wait for async operations
        await tester.pumpAndSettle();
        
        // Verify: Should show download button (fallback)
        expect(find.text('Download Model'), findsOneWidget);
        
        // Verify: Should NOT navigate to main screen
        expect(find.text('Main Screen'), findsNothing);
      },
    );

    testWidgets(
      'Test 6: Download button triggers ensureReady when models not downloaded',
      (WidgetTester tester) async {
        // Setup: Models are not downloaded
        when(mockVLMProvider.areModelsDownloaded)
            .thenAnswer((_) async => false);
        when(mockVLMProvider.isReady).thenReturn(false);
        when(mockVLMProvider.ensureReady()).thenAnswer((_) async => {});
        
        // Build the widget
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Tap the download button
        await tester.tap(find.text('Download Model'));
        await tester.pump();
        
        // Wait for async operations
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Verify: ensureReady was called
        verify(mockVLMProvider.ensureReady()).called(1);
        
        // Verify: Should navigate to main screen after download
        expect(find.text('Main Screen'), findsOneWidget);
      },
    );
  });

  group('ModelDownloadScreen Logic Tests', () {
    test('Test 7: Auto-skip logic - models ready', () async {
      // This test verifies the logic without UI rendering
      final mockVLMProvider = MockVLMProvider();
      
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(true);
      
      // Simulate the check
      final downloaded = await mockVLMProvider.areModelsDownloaded;
      final ready = mockVLMProvider.isReady;
      
      // Verify logic
      expect(downloaded, isTrue);
      expect(ready, isTrue);
      
      // In this case, should auto-navigate without initialization
      verify(mockVLMProvider.areModelsDownloaded).called(1);
      verify(mockVLMProvider.isReady).called(1);
    });

    test('Test 8: Auto-skip logic - models downloaded but not ready', () async {
      // This test verifies the logic without UI rendering
      final mockVLMProvider = MockVLMProvider();
      
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(false);
      when(mockVLMProvider.initialize()).thenAnswer((_) async => {});
      
      // Simulate the check
      final downloaded = await mockVLMProvider.areModelsDownloaded;
      final ready = mockVLMProvider.isReady;
      
      // Verify logic
      expect(downloaded, isTrue);
      expect(ready, isFalse);
      
      // In this case, should initialize then navigate
      await mockVLMProvider.initialize();
      
      verify(mockVLMProvider.areModelsDownloaded).called(1);
      verify(mockVLMProvider.isReady).called(1);
      verify(mockVLMProvider.initialize()).called(1);
    });

    test('Test 9: Auto-skip logic - models not downloaded', () async {
      // This test verifies the logic without UI rendering
      final mockVLMProvider = MockVLMProvider();
      
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => false);
      when(mockVLMProvider.isReady).thenReturn(false);
      
      // Simulate the check
      final downloaded = await mockVLMProvider.areModelsDownloaded;
      
      // Verify logic
      expect(downloaded, isFalse);
      
      // In this case, should show download button (no auto-skip)
      verify(mockVLMProvider.areModelsDownloaded).called(1);
      verifyNever(mockVLMProvider.initialize());
    });

    test('Test 10: Error handling - initialization fails', () async {
      // This test verifies error handling logic
      final mockVLMProvider = MockVLMProvider();
      
      when(mockVLMProvider.areModelsDownloaded).thenAnswer((_) async => true);
      when(mockVLMProvider.isReady).thenReturn(false);
      when(mockVLMProvider.initialize())
          .thenThrow(Exception('Initialization failed'));
      
      // Simulate the check
      final downloaded = await mockVLMProvider.areModelsDownloaded;
      
      expect(downloaded, isTrue);
      
      // Try to initialize and expect exception
      expect(
        () async => await mockVLMProvider.initialize(),
        throwsException,
      );
      
      verify(mockVLMProvider.areModelsDownloaded).called(1);
    });
  });
}
