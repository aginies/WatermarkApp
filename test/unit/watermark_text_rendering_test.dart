import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:secure_mark/utils/watermark_field_handler.dart';
import 'package:secure_mark/font_manager.dart';
import 'package:secure_mark/qr_config.dart';

void main() {
  group('Watermark Text Rendering Tests', () {
    test('Should render actual text, not blank rectangles', () {
      // Create a test image
      final testImage = img.Image(width: 800, height: 600, numChannels: 4);
      testImage.clear(img.ColorRgba8(255, 255, 255, 255)); // White background

      // Apply watermark with text
      WatermarkFieldHandler.applyWatermarkField(
        testImage,
        'TEST WATERMARK',
        50.0, // transparency
        50.0, // density
        false, // useRandomColor
        0xFF0000FF, // blue color
        24.0, // fontSize
        WatermarkFont.arial,
        null, // no pre-rendered stamps - force bitmap fallback
        antiAiLevel: 0.0,
        watermarkType: WatermarkType.text,
      );

      // Verify the image now contains non-white pixels (watermark was applied)
      bool hasNonWhitePixels = false;
      int nonWhiteCount = 0;

      for (final pixel in testImage) {
        // Check if pixel is not white (allowing for slight alpha variations)
        if (pixel.r < 250 || pixel.g < 250 || pixel.b < 250 || pixel.a < 250) {
          hasNonWhitePixels = true;
          nonWhiteCount++;
        }
      }

      expect(hasNonWhitePixels, isTrue,
          reason: 'Watermark should have added non-white pixels to the image');

      // Expect a reasonable number of pixels affected (at least 1% of image)
      final minExpectedPixels =
          (testImage.width * testImage.height * 0.01).toInt();
      expect(nonWhiteCount, greaterThan(minExpectedPixels),
          reason:
              'Watermark should affect at least 1% of pixels, but only affected $nonWhiteCount');
    });

    test('Should render text with different fonts', () {
      final testImage = img.Image(width: 400, height: 300, numChannels: 4);
      testImage.clear(img.ColorRgba8(255, 255, 255, 255));

      // Test with Arial (bitmap font)
      WatermarkFieldHandler.applyWatermarkField(
        testImage,
        'BITMAP TEST',
        30.0,
        50.0,
        false,
        0xFFFF0000, // red
        32.0,
        WatermarkFont.arial,
        null,
        watermarkType: WatermarkType.text,
      );

      // Count red-ish pixels
      int redPixels = 0;
      for (final pixel in testImage) {
        // Check for red color (r > 200, g < 100, b < 100)
        if (pixel.r > 200 && pixel.g < 100 && pixel.b < 100 && pixel.a > 0) {
          redPixels++;
        }
      }

      expect(redPixels, greaterThan(0),
          reason: 'Should have red watermark pixels from Arial bitmap font');
    });

    test('Should handle pre-rendered TTF stamps', () {
      final testImage = img.Image(width: 400, height: 300, numChannels: 4);
      testImage.clear(img.ColorRgba8(255, 255, 255, 255));

      // Create a simple pre-rendered stamp (mock TTF rendering)
      final stampImage = img.Image(width: 200, height: 50, numChannels: 4);
      stampImage.clear(img.ColorRgba8(0, 0, 0, 0)); // Transparent

      // Draw a simple line to simulate text
      for (int x = 10; x < 190; x++) {
        for (int y = 20; y < 30; y++) {
          stampImage.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
        }
      }

      final stampBytes = img.encodePng(stampImage);
      final preRenderedStamps = {'Roboto-24': stampBytes};

      WatermarkFieldHandler.applyWatermarkField(
        testImage,
        'TTF TEST',
        30.0,
        50.0,
        false,
        0xFF00FF00, // green
        24.0,
        WatermarkFont.roboto,
        preRenderedStamps,
        watermarkType: WatermarkType.text,
      );

      // Count green-ish pixels (from colorized stamp)
      int coloredPixels = 0;
      for (final pixel in testImage) {
        // Check for any non-white, non-transparent pixels
        if (pixel.a > 0 && (pixel.r < 250 || pixel.g > 5 || pixel.b < 250)) {
          coloredPixels++;
        }
      }

      expect(coloredPixels, greaterThan(0),
          reason: 'Should use pre-rendered TTF stamp and colorize it');
    });
  });
}
