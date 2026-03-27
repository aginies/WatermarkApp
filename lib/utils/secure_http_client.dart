import 'dart:io';

import 'package:crypto/crypto.dart';

/// Secure HTTP client with certificate fingerprint verification (TOFU model)
///
/// Downloads files over HTTPS with self-signed certificate verification
/// using Trust On First Use (TOFU) model. Users verify the certificate
/// fingerprint from the QR code before downloading.
class SecureHttpClient {
  /// Download file with certificate fingerprint verification
  ///
  /// [url] - HTTPS URL to download from
  /// [expectedFingerprint] - SHA-256 fingerprint of the server's certificate (from QR code)
  /// [outputPath] - Where to save the downloaded file
  /// [onProgress] - Optional progress callback (bytesReceived, totalBytes)
  ///
  /// Throws [CertificateException] if fingerprint doesn't match
  /// Throws [HttpException] for HTTP errors
  static Future<void> downloadWithFingerprint({
    required String url,
    required String expectedFingerprint,
    required String outputPath,
    Function(int, int)? onProgress,
  }) async {
    final client = HttpClient();

    try {
      // Configure client to verify certificate fingerprint
      client.badCertificateCallback = (cert, host, port) {
        // Calculate actual fingerprint from certificate
        final actualFingerprint = _calculateCertFingerprint(cert);

        print('[SecureHttpClient] Certificate fingerprint: $actualFingerprint');
        print('[SecureHttpClient] Expected fingerprint: $expectedFingerprint');

        // TOFU verification: Accept only if fingerprint matches
        final match = actualFingerprint == expectedFingerprint;

        if (!match) {
          print('[SecureHttpClient] ❌ Certificate fingerprint mismatch!');
        } else {
          print('[SecureHttpClient] ✅ Certificate fingerprint verified');
        }

        return match;
      };

      // Download file
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
          'HTTP ${response.statusCode}: Failed to download file',
        );
      }

      // Get content length for progress tracking
      final contentLength = response.contentLength;

      // Stream to file (memory-efficient)
      final outputFile = File(outputPath);
      final sink = outputFile.openWrite();

      int receivedBytes = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        // Report progress
        if (onProgress != null && contentLength > 0) {
          onProgress(receivedBytes, contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      print('[SecureHttpClient] Download complete: $receivedBytes bytes');
    } catch (e) {
      // Clean up partial file on error
      final file = File(outputPath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Calculate SHA-256 fingerprint from X509Certificate
  static String _calculateCertFingerprint(X509Certificate cert) {
    // Get DER-encoded certificate bytes
    final der = cert.der;

    // Calculate SHA-256 hash
    final digest = sha256.convert(der);

    // Format as colon-separated hex string (e.g., "AB:CD:EF:...")
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  /// Download file without certificate verification (HTTP or trusted HTTPS)
  ///
  /// Use this for regular HTTP downloads or when certificate verification
  /// is not needed (e.g., trusted CA-signed certificates)
  static Future<void> downloadUnsecure({
    required String url,
    required String outputPath,
    Function(int, int)? onProgress,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
          'HTTP ${response.statusCode}: Failed to download file',
        );
      }

      final contentLength = response.contentLength;
      final outputFile = File(outputPath);
      final sink = outputFile.openWrite();

      int receivedBytes = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (onProgress != null && contentLength > 0) {
          onProgress(receivedBytes, contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      print('[SecureHttpClient] Download complete: $receivedBytes bytes');
    } catch (e) {
      final file = File(outputPath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }
}

/// Exception thrown when certificate fingerprint verification fails
class CertificateVerificationException implements Exception {
  final String message;
  final String expectedFingerprint;
  final String actualFingerprint;

  CertificateVerificationException({
    required this.message,
    required this.expectedFingerprint,
    required this.actualFingerprint,
  });

  @override
  String toString() {
    return 'CertificateVerificationException: $message\n'
        'Expected: $expectedFingerprint\n'
        'Actual: $actualFingerprint';
  }
}
