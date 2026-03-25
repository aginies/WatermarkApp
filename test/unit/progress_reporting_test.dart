import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:secure_mark/utils/watermark_field_handler.dart';
import 'package:secure_mark/font_manager.dart';
import 'package:secure_mark/qr_config.dart';

void main() {
  group('Progress Reporting Tests', () {
    test('Should report progress every 5 watermarks with count', () {
      final testImage = img.Image(width: 1200, height: 900, numChannels: 4);
      testImage.clear(img.ColorRgba8(255, 255, 255, 255));

      final progressReports = <String>[];
      final progressValues = <double>[];

      WatermarkFieldHandler.applyWatermarkField(
        testImage,
        'TEST',
        50.0, // transparency
        50.0, // density - should create ~24 watermarks
        false,
        0xFF0000FF,
        24.0,
        WatermarkFont.arial,
        null,
        antiAiLevel: 0.0,
        watermarkType: WatermarkType.text,
        onProgress: (progress, message) {
          progressReports.add(message);
          progressValues.add(progress);
        },
      );

      // Should have progress reports
      expect(progressReports.isNotEmpty, isTrue,
          reason: 'Should have progress reports');

      // Should report every ~5 watermarks
      expect(progressReports.length, greaterThan(1),
          reason: 'Should have multiple progress reports');

      // Check that messages contain counts
      final hasCountInfo = progressReports.any((msg) => msg.contains('/'));
      expect(hasCountInfo, isTrue,
          reason: 'Progress messages should contain count info like (5/24)');

      // Check that final message indicates completion
      final lastMessage = progressReports.last;
      expect(lastMessage, contains('applied'),
          reason: 'Last message should indicate completion');

      // Progress values should increase
      for (var i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]),
            reason: 'Progress values should increase or stay the same');
      }

      // Last progress from applyWatermarkField should be 0.98
      // (1.0 is reserved for the overall process completion in watermark_processor)
      expect(progressValues.last, equals(0.98),
          reason: 'Final progress from field handler should be 0.98');
    });

    test('Should show Anti-AI protection in progress messages', () {
      final testImage = img.Image(width: 800, height: 600, numChannels: 4);
      testImage.clear(img.ColorRgba8(255, 255, 255, 255));

      final progressReports = <String>[];

      WatermarkFieldHandler.applyWatermarkField(
        testImage,
        'PROTECTED',
        50.0,
        50.0,
        false,
        0xFF00FF00,
        24.0,
        WatermarkFont.arial,
        null,
        antiAiLevel: 50.0, // Enable Anti-AI protection
        watermarkType: WatermarkType.text,
        onProgress: (progress, message) {
          progressReports.add(message);
        },
      );

      // Should mention Anti-AI protection in messages
      final hasAntiAiMention =
          progressReports.any((msg) => msg.toLowerCase().contains('anti-ai'));
      expect(hasAntiAiMention, isTrue,
          reason:
              'Progress messages should mention Anti-AI protection when enabled');
    });

    test('Should differentiate between text and logo watermarks', () {
      final testImage = img.Image(width: 600, height: 400, numChannels: 4);
      testImage.clear(img.ColorRgba8(255, 255, 255, 255));

      // Create a simple logo image
      final logoImage = img.Image(width: 50, height: 50, numChannels: 4);
      logoImage.clear(img.ColorRgba8(255, 0, 0, 255));
      final logoBytes = img.encodePng(logoImage);

      final progressReports = <String>[];

      WatermarkFieldHandler.applyWatermarkField(
        testImage,
        'LOGO',
        50.0,
        30.0,
        false,
        0xFFFF0000,
        32.0,
        WatermarkFont.arial,
        null,
        antiAiLevel: 0.0,
        watermarkType: WatermarkType.image,
        watermarkImageBytes: logoBytes,
        onProgress: (progress, message) {
          progressReports.add(message);
        },
      );

      // Should mention logo in messages
      final hasLogoMention =
          progressReports.any((msg) => msg.toLowerCase().contains('logo'));
      expect(hasLogoMention, isTrue,
          reason:
              'Progress messages should mention logo when using image watermarks');
    });

    test('Should limit progress callback frequency', () {
      final testImage = img.Image(width: 1600, height: 1200, numChannels: 4);
      testImage.clear(img.ColorRgba8(255, 255, 255, 255));

      var callbackCount = 0;

      WatermarkFieldHandler.applyWatermarkField(
        testImage,
        'FREQUENCY TEST',
        50.0,
        25.0, // Lower density for testing
        false,
        0xFF0000FF,
        24.0,
        WatermarkFont.arial,
        null,
        onProgress: (progress, message) {
          callbackCount++;
        },
      );

      // Progress is throttled: reported every 10 cells + every 5 stamps + final
      // For 1600x1200 @ density=25: ~143 watermarks, ~200 cells
      // Expected: ~20 cell callbacks + ~28 stamp callbacks + 1 final = ~50 total
      expect(callbackCount, lessThan(60),
          reason: 'Should limit callback frequency to avoid excessive updates');

      expect(callbackCount, greaterThan(5),
          reason: 'Should have several progress updates for large image');
    });
  });
}
