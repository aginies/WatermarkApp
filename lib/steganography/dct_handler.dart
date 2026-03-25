import 'dart:convert';

import 'package:image/image.dart' as img;

import '../utils/color_utils.dart';
import '../utils/dct_utils.dart';

/// Robust steganography handler using DCT (Discrete Cosine Transform).
///
/// Performance: DCT operations optimized with lookup tables (5-10x faster).
/// For 4K images: ~130K blocks processed, each using optimized O(n²) DCT.
class DctHandler {
  static img.Image embedRobustSignature(img.Image image, String sig) {
    if (sig.isEmpty) {
      return image;
    }
    final bits = _getRobustSignatureBits(sig);
    final nX = image.width ~/ 8, nY = image.height ~/ 8;
    int bIdx = 0;
    for (var y = 0; y < nY && bIdx < bits.length; y++) {
      for (var x = 0; x < nX && bIdx < bits.length; x++) {
        final block = List<double>.generate(64, (i) {
          final p = _getPixelInBlock(image, x, y, i);
          return ColorUtils.rgbToYRed * p.r +
              ColorUtils.rgbToYGreen * p.g +
              ColorUtils.rgbToYBlue * p.b;
        });
        final dct = DctUtils.dct8x8(block);
        const coeff = 36; // Mid-frequency
        if (bits[bIdx]) {
          dct[coeff] = dct[coeff] < 20 ? 20 : dct[coeff] + 20;
        } else {
          dct[coeff] = dct[coeff] > -20 ? -20 : dct[coeff] - 20;
        }
        final idct = DctUtils.idct8x8(dct);
        for (var i = 0; i < 64; i++) {
          final p = _getPixelInBlock(image, x, y, i);
          final diff = idct[i] -
              (ColorUtils.rgbToYRed * p.r +
                  ColorUtils.rgbToYGreen * p.g +
                  ColorUtils.rgbToYBlue * p.b);
          p.r = (p.r + diff).clamp(0, 255).toInt();
          p.g = (p.g + diff).clamp(0, 255).toInt();
          p.b = (p.b + diff).clamp(0, 255).toInt();
        }
        bIdx++;
      }
    }
    return image;
  }

  static String? extractRobustSignature(img.Image image) {
    final bits = <bool>[];
    final nX = image.width ~/ 8, nY = image.height ~/ 8;
    for (var y = 0; y < nY && bits.length < 1024 * 8; y++) {
      for (var x = 0; x < nX && bits.length < 1024 * 8; x++) {
        final block = List<double>.generate(64, (i) {
          final p = _getPixelInBlock(image, x, y, i);
          return ColorUtils.rgbToYRed * p.r +
              ColorUtils.rgbToYGreen * p.g +
              ColorUtils.rgbToYBlue * p.b;
        });
        bits.add(DctUtils.dct8x8(block)[36] > 0);
      }
    }
    if (bits.length < 16) {
      return null;
    }
    final bytes = <int>[];
    for (var i = 0; i < bits.length ~/ 8; i++) {
      var b = 0;
      for (var j = 0; j < 8; j++) {
        if (bits[i * 8 + j]) {
          b |= (1 << (7 - j));
        }
      }
      bytes.add(b);
    }
    if (bytes.length < 4 || bytes[0] != 83 || bytes[1] != 82) {
      return null; // 'S','R'
    }
    final len = (bytes[2] << 8) | bytes[3];
    if (bytes.length < 4 + len) {
      return null;
    }
    try {
      return utf8.decode(bytes.sublist(4, 4 + len), allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static List<bool> _getRobustSignatureBits(String sig) {
    final b = utf8.encode(sig);
    return [83, 82, (b.length >> 8) & 0xFF, b.length & 0xFF, ...b]
        .expand((x) => List.generate(8, (i) => (x >> (7 - i)) & 1 == 1))
        .toList();
  }

  /// Converts block coordinates and sub-pixel index to pixel
  /// Used for 8x8 DCT block processing
  static img.Pixel _getPixelInBlock(
      img.Image image, int blockX, int blockY, int subIndex) {
    return image.getPixel(
        blockX * 8 + (subIndex % 8), blockY * 8 + (subIndex ~/ 8));
  }
}
