/// Simple watermark error class for test purposes.
class WatermarkError implements Exception {
  const WatermarkError({
    required this.type,
    required this.message,
    this.filePath,
    this.originalError,
  });

  final WatermarkErrorType type;
  final String message;
  final String? filePath;
  final Object? originalError;

  @override
  String toString() =>
      'WatermarkError(type: $type, message: $message${filePath != null ? ' (File: $filePath)' : ''}${originalError != null ? ' - Original: $originalError' : ''})';
}

enum WatermarkErrorType {
  unsupportedFileType,
  fileTooLarge,
  fileNotFound,
  fileCorrupted,
  invalidImageData,
  invalidPdfData,
  memoryLimitExceeded,
  processingTimeout,
  operationCancelled,
  unknownError,
}
