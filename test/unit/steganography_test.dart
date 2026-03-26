import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/watermark_processor.dart';

void main() {
  group('Steganography Tests', () {
    late File testImage;

    setUp(() async {
      final originalImage = File('images/app.jpg');
      if (!await originalImage.exists()) {
        throw Exception('images/app.jpg not found');
      }
      testImage = File('test_app.jpg');
      await originalImage.copy(testImage.path);
    });

    tearDown(() async {
      if (await testImage.exists()) {
        await testImage.delete();
      }
    });

    test('Robust DCT signature embedding and extraction', () async {
      final watermarkText = 'Robust-Test';

      final result = await WatermarkProcessor.processFile(
        file: testImage,
        watermarkText: watermarkText,
        useRobustSteganography: true,
        steganographyText: watermarkText,
        transparency: 100,
        density: 0,
        useRandomColor: false,
        selectedColorValue: 0,
        fontSize: 20,
      );

      // DCT is robust to JPEG compression
      expect(result.robustVerified, true);

      final analysis = await WatermarkProcessor.analyzeImageAsync(
        result.outputBytes,
      );
      expect(analysis.robustSignature, startsWith(watermarkText));
    });

    test('Basic processing without steganography', () async {
      final result = await WatermarkProcessor.processFile(
        file: testImage,
        watermarkText: 'Basic Test',
        transparency: 50,
        density: 15,
        useRandomColor: true,
        selectedColorValue: 0xFFFF0000,
        fontSize: 24,
      );

      expect(result.outputBytes, isNotEmpty);
      expect(result.outputPath, isNotNull);
    });
  });
}
