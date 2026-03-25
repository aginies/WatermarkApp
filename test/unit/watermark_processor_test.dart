import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/watermark_error.dart';
import 'package:secure_mark/models/processor_models.dart';
import 'package:secure_mark/watermark_processor.dart';

void main() {
  group('WatermarkProcessor Logic Tests', () {
    test('Validation should fail for non-existent files', () async {
      final file = File('non_existent_file.jpg');
      expect(
          () => WatermarkProcessor.processFile(
                file: file,
                watermarkText: 'test',
                transparency: 0.5,
                density: 0.5,
                useRandomColor: true,
                selectedColorValue: 0,
                fontSize: 20,
              ),
          throwsA(isA<WatermarkError>()
              .having((e) => e.type, 'type', WatermarkErrorType.fileNotFound)));
    });

    test('Validation should fail for unsupported extensions', () async {
      final file = File('test.txt');
      await file.writeAsString('dummy content');

      try {
        await WatermarkProcessor.processFile(
          file: file,
          watermarkText: 'test',
          transparency: 0.5,
          density: 0.5,
          useRandomColor: true,
          selectedColorValue: 0,
          fontSize: 20,
        );
        fail('Should have thrown WatermarkError');
      } catch (e) {
        expect(e, isA<WatermarkError>());
        expect(
            (e as WatermarkError).type, WatermarkErrorType.unsupportedFileType);
      } finally {
        if (await file.exists()) await file.delete();
      }
    });

    test('CancellationToken should stop processing early', () async {
      final token = CancellationToken();
      token.cancel();

      final file = File('dummy.jpg');
      expect(
          () => WatermarkProcessor.processFile(
              file: file,
              watermarkText: 'test',
              transparency: 0.5,
              density: 0.5,
              useRandomColor: true,
              selectedColorValue: 0,
              fontSize: 20,
              cancellationToken: token),
          throwsA(isA<WatermarkError>().having(
              (e) => e.type, 'type', WatermarkErrorType.operationCancelled)));
    });
  });
}
