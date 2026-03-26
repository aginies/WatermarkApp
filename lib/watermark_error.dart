import 'package:path/path.dart' as p;
import 'l10n/app_localizations.dart';

/// Specific error types for better error handling
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
  missingSteganographySignature,
  missingQrContent,
  unknownError,
}

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
  String toString() {
    final buffer = StringBuffer('WatermarkError: $message');
    if (filePath != null) {
      buffer.write(' (File: ${p.basename(filePath!)})');
    }
    if (originalError != null) {
      buffer.write(' - Original error: $originalError');
    }
    return buffer.toString();
  }

  /// Get user-friendly error message
  String get userMessage => message;

  /// Get localized user-friendly error message
  String getLocalizedMessage(AppLocalizations l10n) {
    // Check for specific steganography capacity error
    if (message.contains('too large to hide')) {
      return message;
    }

    // Check for resolution limit error
    if (message.startsWith('Image resolution') ||
        message.contains('exceeds maximum') ||
        message.contains('MP)')) {
      return message;
    }

    // Check for Samsung TIFF-wrapped JPEG error
    if (message.contains('Samsung') ||
        message.contains('TIFF-wrapped JPEG') ||
        message.contains('photo editor')) {
      return message;
    }

    switch (type) {
      case WatermarkErrorType.unsupportedFileType:
        return l10n
            .processingFailed; // Fallback to general processing failed if specific not available
      case WatermarkErrorType.fileTooLarge:
        return 'File is too large (max 100MB).'; // Could add this to arb if needed
      case WatermarkErrorType.fileNotFound:
        return 'File not found.';
      case WatermarkErrorType.fileCorrupted:
        return l10n.processingFailed;
      case WatermarkErrorType.invalidImageData:
        return l10n.processingFailed;
      case WatermarkErrorType.invalidPdfData:
        return l10n.processingFailed;
      case WatermarkErrorType.memoryLimitExceeded:
        return 'Not enough memory to process this file.';
      case WatermarkErrorType.processingTimeout:
        return 'Processing took too long and was cancelled.';
      case WatermarkErrorType.operationCancelled:
        return l10n.processingCancelled;
      case WatermarkErrorType.missingSteganographySignature:
        return l10n.missingSteganographySignature;
      case WatermarkErrorType.missingQrContent:
        return l10n.missingQrContent;
      case WatermarkErrorType.unknownError:
        return l10n.processingFailed;
    }
  }
}
