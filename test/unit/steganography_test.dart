import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/watermark_processor.dart';

void main() {
  group('Comprehensive Steganography Tests with app.jpg', () {
    late Uint8List dummyFileBytes;
    late String dummyFileContent;
    late String testText;
    late String testPassword;
    late File appJpgCopy;

    setUp(() async {
      final File originalAppJpg = File('images/app.jpg');
      if (!await originalAppJpg.exists()) {
        throw Exception(
            'images/app.jpg not found! Please ensure it exists in the images directory.');
      }
      appJpgCopy = File('app_test_copy.jpg');
      await originalAppJpg.copy(appJpgCopy.path);
      testText = 'SecureMark-Test';
      dummyFileContent = 'This is a test file for steganography.';
      dummyFileBytes = Uint8List.fromList(utf8.encode(dummyFileContent));
      testPassword = 'test-password-2026';
    });

    tearDown(() async {
      if (appJpgCopy.existsSync()) {
        await appJpgCopy.delete();
      }
    });

    test(
        'Ultimate Scenario: ALL TOGETHER (LSB Signature + Robust DCT + Hidden File)',
        () async {
      final result = await WatermarkProcessor.processFile(
        file: appJpgCopy,
        watermarkText: testText,
        useSteganography: true, // For LSB Signature & File
        useRobustSteganography: true, // For DCT Signature
        hiddenFileName: 'test_hidden.txt',
        hiddenFileBytes: dummyFileBytes,
        steganographyPassword: testPassword,
        transparency: 50,
        density: 15,
        useRandomColor: true,
        selectedColorValue: 0xFFFF0000,
        fontSize: 24,
      );

      // 1. Verify internal verification flags in ProcessResult
      expect(result.steganographyVerified, true,
          reason: 'LSB/File verification failed during processing');
      expect(result.robustVerified, true,
          reason: 'Robust DCT verification failed during processing');

      // 2. Perform manual extraction for deeper verification
      final analysis = await WatermarkProcessor.analyzeImageAsync(
        result.outputBytes,
        password: testPassword,
      );

      expect(analysis.signature, startsWith(testText),
          reason: 'LSB Signature extraction mismatch');
      expect(analysis.robustSignature, startsWith(testText),
          reason: 'Robust DCT Signature extraction mismatch');
      expect(analysis.file?.fileName, 'test_hidden.txt',
          reason: 'Hidden File name mismatch');
      expect(utf8.decode(analysis.file!.fileBytes), dummyFileContent,
          reason: 'Hidden File content mismatch');
    });

    test('Scenario: Only Robust Watermark', () async {
      final result = await WatermarkProcessor.processFile(
        file: appJpgCopy,
        watermarkText: 'ROBUST-ONLY',
        useRobustSteganography: true,
        useSteganography: false,
        transparency: 100, // invisible visual watermark
        density: 0,
        useRandomColor: false,
        selectedColorValue: 0,
        fontSize: 20,
      );

      expect(result.robustVerified, true);

      final analysis =
          await WatermarkProcessor.analyzeImageAsync(result.outputBytes);
      expect(analysis.robustSignature, startsWith('ROBUST-ONLY'));
      expect(analysis.signature, isNull,
          reason: 'LSB signature should NOT be present');
    });

    test('Scenario: Only Hidden File (LSB)', () async {
      final result = await WatermarkProcessor.processFile(
        file: appJpgCopy,
        watermarkText: '',
        useSteganography: true,
        hiddenFileName: 'only_file.dat',
        hiddenFileBytes: dummyFileBytes,
        transparency: 100,
        density: 0,
        useRandomColor: false,
        selectedColorValue: 0,
        fontSize: 20,
      );

      expect(result.steganographyVerified, true);

      final analysis =
          await WatermarkProcessor.analyzeImageAsync(result.outputBytes);
      expect(analysis.file?.fileName, 'only_file.dat');
      expect(analysis.file?.fileBytes, dummyFileBytes);
      expect(analysis.signature, isNotNull,
          reason:
              'LSB Signature always contains at least a timestamp if useSteganography is true');
    });
    group('PDF Steganography Tests', () {
      test('Should hide and extract file in PDF', () async {
        // PDF specific test can be added here
      });
    });
  });
}
