import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/watermark_error.dart';
import 'package:secure_mark/watermark_processor.dart';

void main() {
  test('file not found error', () {
    var file = File('non_existent_file.jpg');
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
          .having((e) => e.type, 'type', WatermarkErrorType.fileNotFound)),
    );
  });

  test('unsupported file extension error', () async {
    var file = File('example.txt');
    await file.writeAsString('dummy');
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
      expect(false, 'Should have thrown WatermarkError');
    } catch (e) {
      expect(e, isA<WatermarkError>());
      expect(
          (e as WatermarkError).type, WatermarkErrorType.unsupportedFileType);
    } finally {
      if (await file.exists()) await file.delete();
    }
  });
}
