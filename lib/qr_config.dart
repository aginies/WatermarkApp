import 'dart:convert';

/// Configuration for QR code watermarking
class QrWatermarkConfig {
  const QrWatermarkConfig({
    this.author,
    this.url,
    required this.timestamp,
    this.includeTimestamp = true,
    this.includeAuthor = true,
    this.includeUrl = true,
    this.position = QrPosition.bottomRight,
    this.size = 100.0,
    this.opacity = 0.8,
    this.visibleQr = true,
    this.invisibleQr = false,
  });

  final String? author;
  final String? url;
  final DateTime timestamp;
  final bool includeTimestamp;
  final bool includeAuthor;
  final bool includeUrl;

  // For visible QR codes
  final QrPosition position;
  final double size; // 50-200 pixels
  final double opacity; // 0.0-1.0

  // Mode selection
  final bool visibleQr;
  final bool invisibleQr;

  /// Converts metadata to JSON string for QR code content
  String toJsonString() {
    final data = <String, dynamic>{};

    if (includeAuthor && author != null && author!.isNotEmpty) {
      data['author'] = author;
    }
    if (includeUrl && url != null && url!.isNotEmpty) {
      data['url'] = url;
    }
    if (includeTimestamp) {
      data['timestamp'] = timestamp.toIso8601String();
    }
    data['app'] = 'SecureMark';
    data['version'] = '1.0';

    return jsonEncode(data);
  }

  /// Creates a copy with updated values
  QrWatermarkConfig copyWith({
    String? author,
    String? url,
    DateTime? timestamp,
    bool? includeTimestamp,
    bool? includeAuthor,
    bool? includeUrl,
    QrPosition? position,
    double? size,
    double? opacity,
    bool? visibleQr,
    bool? invisibleQr,
  }) {
    return QrWatermarkConfig(
      author: author ?? this.author,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
      includeTimestamp: includeTimestamp ?? this.includeTimestamp,
      includeAuthor: includeAuthor ?? this.includeAuthor,
      includeUrl: includeUrl ?? this.includeUrl,
      position: position ?? this.position,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      visibleQr: visibleQr ?? this.visibleQr,
      invisibleQr: invisibleQr ?? this.invisibleQr,
    );
  }
}

/// Position for visible QR codes on the image
enum QrPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}
