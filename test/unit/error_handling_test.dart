import 'package:flutter_test/flutter_test.dart';
import 'package:secure_mark/watermark_error.dart';
import 'package:secure_mark/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('WatermarkError Tests', () {
    test('Should construct with basic properties', () {
      const error = WatermarkError(
        type: WatermarkErrorType.fileNotFound,
        message: 'Original message',
        filePath: 'path/to/file.jpg',
      );

      expect(error.type, WatermarkErrorType.fileNotFound);
      expect(error.message, 'Original message');
      expect(error.filePath, 'path/to/file.jpg');
      expect(error.toString(), contains('Original message'));
      expect(error.toString(), contains('file.jpg'));
    });

    test('Verify all user-friendly error messages', () {
      const types = WatermarkErrorType.values;
      for (final type in types) {
        final error = WatermarkError(type: type, message: 'test');
        expect(error.getLocalizedMessage(l10n), isNotEmpty,
            reason: 'Type $type should have a user message');
      }
    });

    test('Specific user message content checks', () {
      expect(
          const WatermarkError(
                  type: WatermarkErrorType.unsupportedFileType, message: '')
              .getLocalizedMessage(l10n),
          contains('failed'));

      expect(
          const WatermarkError(
                  type: WatermarkErrorType.operationCancelled, message: '')
              .getLocalizedMessage(l10n),
          contains('cancelled'));
    });
  });
}
