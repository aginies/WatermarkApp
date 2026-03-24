import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/watermark_processor.dart';

void main() {
  test('Validation fails for non‑existent PDF', () async {
    final file = File('nonexistent.pdf');
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
      throwsA(isA<WatermarkError>().having(
        (e) => e.type,
        'type',
        WatermarkErrorType.fileNotFound,
      )),
    );
  });

  test('Process should reject unsupported image format', () async {
    // create a dummy file with unsupported extension .txt
    final file = File('dummy.txt');
    await file.writeAsString('not an image');
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
}
