import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

final Random _random = Random();
const int _fixedFontSize = 24;
const int _maxImageDimension = 1600;
const double _pdfRasterDpi = 96;
const double _angleStepDegrees = 15;
const int _randomColorPoolSize = 6;

class ProcessResult {
  const ProcessResult({
    required this.outputPath,
    required this.outputBytes,
    required this.previewBytes,
  });

  final String outputPath;
  final Uint8List outputBytes;
  final Uint8List? previewBytes;
}

class _Placement {
  const _Placement({
    required this.x,
    required this.y,
    required this.fontSize,
    required this.angle,
    required this.colorKey,
    required this.color,
  });

  final int x;
  final int y;
  final int fontSize;
  final double angle;
  final int colorKey;
  final img.Color color;
}

class _ResolvedColor {
  const _ResolvedColor({
    required this.key,
    required this.color,
  });

  final int key;
  final img.Color color;
}

class WatermarkProcessor {
  static Future<ProcessResult?> processFile({
    required File file,
    required double transparency,
    required double density,
    required String watermarkText,
    required bool useRandomColor,
    required int selectedColorValue,
  }) async {
    final extension = p.extension(file.path).toLowerCase();
    final resolvedText = _resolvedWatermarkText(watermarkText);

    if (extension == '.pdf') {
      return _processPdf(
        file: file,
        transparency: transparency,
        density: density,
        watermarkText: resolvedText,
        useRandomColor: useRandomColor,
        selectedColorValue: selectedColorValue,
      );
    }

    if (extension == '.jpg' || extension == '.jpeg' || extension == '.png') {
      return _processImage(
        file: file,
        transparency: transparency,
        density: density,
        watermarkText: resolvedText,
        useRandomColor: useRandomColor,
        selectedColorValue: selectedColorValue,
      );
    }

    return null;
  }

  static Future<ProcessResult?> _processImage({
    required File file,
    required double transparency,
    required double density,
    required String watermarkText,
    required bool useRandomColor,
    required int selectedColorValue,
  }) async {
    final inputBytes = await file.readAsBytes();
    final outputBytes = await Isolate.run(
      () => _renderWatermarkedImageBytes(
        inputBytes: inputBytes,
        transparency: transparency,
        density: density,
        watermarkText: watermarkText,
        useRandomColor: useRandomColor,
        selectedColorValue: selectedColorValue,
      ),
    );
    if (outputBytes == null) {
      return null;
    }
    final outputPath = _outputPath(file.path, '.png');

    return ProcessResult(
      outputPath: outputPath,
      outputBytes: outputBytes,
      previewBytes: outputBytes,
    );
  }

  static Future<ProcessResult?> _processPdf({
    required File file,
    required double transparency,
    required double density,
    required String watermarkText,
    required bool useRandomColor,
    required int selectedColorValue,
  }) async {
    final inputBytes = await file.readAsBytes();
    final doc = pw.Document();
    Uint8List? preview;
    var hasPages = false;

    await for (final page in Printing.raster(inputBytes, dpi: _pdfRasterDpi)) {
      hasPages = true;
      final pngBytes = await page.toPng();
      if (pngBytes == null) {
        continue;
      }

      final decoded = img.decodeImage(pngBytes);
      if (decoded == null) {
        continue;
      }

      final watermarked = img.Image.from(decoded);
      _applyWatermarkField(
        watermarked,
        watermarkText,
        transparency,
        density,
        useRandomColor,
        selectedColorValue,
      );

      final encoded = _encodePngForSharing(watermarked);
      preview ??= encoded;

      final provider = pw.MemoryImage(encoded);
      final format = PdfPageFormat(
        page.width.toDouble(),
        page.height.toDouble(),
      );

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.SizedBox.expand(
            child: pw.Image(provider, fit: pw.BoxFit.fill),
          ),
        ),
      );
    }

    if (!hasPages) {
      return null;
    }

    final outputBytes = await doc.save();
    final outputPath = _outputPath(file.path, '.pdf');

    return ProcessResult(
      outputPath: outputPath,
      outputBytes: outputBytes,
      previewBytes: preview,
    );
  }

  static Uint8List? _renderWatermarkedImageBytes({
    required Uint8List inputBytes,
    required double transparency,
    required double density,
    required String watermarkText,
    required bool useRandomColor,
    required int selectedColorValue,
  }) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      return null;
    }

    final resized = _resizeForSharing(decoded);
    final outputImage = img.Image.from(resized);
    _applyWatermarkField(
      outputImage,
      watermarkText,
      transparency,
      density,
      useRandomColor,
      selectedColorValue,
    );
    return _encodePngForSharing(outputImage);
  }

  static img.Image _buildWatermarkStamp(String watermarkText, _Placement placement) {
    final baseTextWidth = max(1, watermarkText.length * 18);
    final baseTextHeight = 48;
    final textImage = img.Image(
      width: baseTextWidth,
      height: baseTextHeight,
      numChannels: 4,
    );
    textImage.clear(img.ColorRgba8(0, 0, 0, 0));
    textImage.backgroundColor = img.ColorRgba8(0, 0, 0, 0);
    img.drawString(
      textImage,
      watermarkText,
      font: img.arial24,
      x: 0,
      y: 12,
      color: placement.color,
    );

    final rotated = img.copyRotate(
      textImage,
      angle: placement.angle,
      interpolation: img.Interpolation.linear,
    );
    rotated.backgroundColor = img.ColorRgba8(0, 0, 0, 0);
    return rotated;
  }

  static void _applyWatermarkField(
    img.Image image,
    String watermarkText,
    double transparency,
    double density,
    bool useRandomColor,
    int selectedColorValue,
  ) {
    final placements = _buildPlacements(
      width: image.width,
      height: image.height,
      watermarkText: watermarkText,
      transparency: transparency,
      density: density,
      useRandomColor: useRandomColor,
      selectedColorValue: selectedColorValue,
    );
    final stampCache = <String, img.Image>{};

    for (final placement in placements) {
      final stampKey = '${placement.angle.round()}-${placement.colorKey}';
      final stamp = stampCache.putIfAbsent(
        stampKey,
        () => _buildWatermarkStamp(watermarkText, placement),
      );
      img.compositeImage(
        image,
        stamp,
        dstX: placement.x,
        dstY: placement.y,
        blend: img.BlendMode.alpha,
      );
    }
  }

  static List<_Placement> _buildPlacements({
    required int width,
    required int height,
    required String watermarkText,
    required double transparency,
    required double density,
    required bool useRandomColor,
    required int selectedColorValue,
  }) {
    final placements = <_Placement>[];
    final targetCount = _watermarkCount(width, height, density);
    final alpha = _alphaFromTransparency(transparency);
    final colorPool = _buildColorPool(useRandomColor, selectedColorValue, alpha);
    final columns = max(2, sqrt(targetCount * (width / max(1, height))).round());
    final rows = max(2, (targetCount / columns).ceil());
    final cellWidth = max(1.0, width / columns.toDouble());
    final cellHeight = max(1.0, height / rows.toDouble());
    final cells = <Point<int>>[];

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        cells.add(Point<int>(column, row));
      }
    }
    cells.shuffle(_random);

    for (final cell in cells) {
      if (placements.length >= targetCount) {
        break;
      }

      final placement = _tryPlacementInCell(
        width: width,
        height: height,
        watermarkText: watermarkText,
        cellColumn: cell.x,
        cellRow: cell.y,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        colorPool: colorPool,
      );

      if (placement != null) {
        placements.add(placement);
      }
    }

    var extraAttempts = targetCount * 4;
    while (placements.length < targetCount && extraAttempts > 0) {
      extraAttempts -= 1;
      final placement = _tryPlacementAnywhere(
        width: width,
        height: height,
        watermarkText: watermarkText,
        colorPool: colorPool,
      );
      if (placement != null) {
        placements.add(placement);
      }
    }

    return placements;
  }

  static _Placement? _tryPlacementInCell({
    required int width,
    required int height,
    required String watermarkText,
    required int cellColumn,
    required int cellRow,
    required double cellWidth,
    required double cellHeight,
    required List<_ResolvedColor> colorPool,
  }) {
    for (var attempt = 0; attempt < 6; attempt++) {
      final angle = _randomAngle();
      final rotatedSize = _rotatedStampSize(watermarkText, _fixedFontSize, angle);
      if (rotatedSize.$1 >= width || rotatedSize.$2 >= height) {
        continue;
      }

      final minX = (cellColumn * cellWidth).floor();
      final maxX = min(
        width - 1,
        (((cellColumn + 1) * cellWidth).floor() - 1).clamp(-rotatedSize.$1 + 1, width - 1),
      );
      final minY = (cellRow * cellHeight).floor();
      final maxY = min(
        height - 1,
        (((cellRow + 1) * cellHeight).floor() - 1).clamp(-rotatedSize.$2 + 1, height - 1),
      );

      final relaxedMinX = max(-rotatedSize.$1 + 1, minX - (rotatedSize.$1 ~/ 3));
      final relaxedMinY = max(-rotatedSize.$2 + 1, minY - (rotatedSize.$2 ~/ 3));

      if (maxX < relaxedMinX || maxY < relaxedMinY) {
        continue;
      }

      final x = relaxedMinX + _random.nextInt(maxX - relaxedMinX + 1);
      final y = relaxedMinY + _random.nextInt(maxY - relaxedMinY + 1);
      final resolvedColor = _pickColor(colorPool);
      return _Placement(
        x: x,
        y: y,
        fontSize: _fixedFontSize,
        angle: angle,
        colorKey: resolvedColor.key,
        color: resolvedColor.color,
      );
    }

    return null;
  }

  static _Placement? _tryPlacementAnywhere({
    required int width,
    required int height,
    required String watermarkText,
    required List<_ResolvedColor> colorPool,
  }) {
    for (var attempt = 0; attempt < 12; attempt++) {
      final angle = _randomAngle();
      final rotatedSize = _rotatedStampSize(watermarkText, _fixedFontSize, angle);
      if (rotatedSize.$1 >= width || rotatedSize.$2 >= height) {
        continue;
      }

      final minX = -rotatedSize.$1 + 1;
      final maxX = width - 1;
      final minY = -rotatedSize.$2 + 1;
      final maxY = height - 1;
      final x = minX + _random.nextInt(maxX - minX + 1);
      final y = minY + _random.nextInt(maxY - minY + 1);
      final resolvedColor = _pickColor(colorPool);
      return _Placement(
        x: x,
        y: y,
        fontSize: _fixedFontSize,
        angle: angle,
        colorKey: resolvedColor.key,
        color: resolvedColor.color,
      );
    }

    return null;
  }

  static (int, int) _rotatedStampSize(String watermarkText, int fontSize, double angle) {
    final scale = fontSize / 24.0;
    final baseWidth = max(1, watermarkText.length * 18);
    final baseHeight = 48;
    final scaledWidth = max(1, (baseWidth * scale).round());
    final scaledHeight = max(1, (baseHeight * scale).round());
    final radians = angle * pi / 180.0;
    final rotatedWidth =
        (scaledWidth * cos(radians).abs() + scaledHeight * sin(radians).abs()).ceil();
    final rotatedHeight =
        (scaledWidth * sin(radians).abs() + scaledHeight * cos(radians).abs()).ceil();
    return (rotatedWidth, rotatedHeight);
  }

  static int _watermarkCount(int width, int height, double density) {
    final area = width * height;
    final baseDensity = area / 18000;
    final densityFactor = (density / 50).clamp(0.4, 2.0);
    return max(8, (baseDensity * 2.69 * densityFactor).round());
  }

  static int _alphaFromTransparency(double transparency) {
    final opacity = (100 - transparency).clamp(10, 90) / 100;
    return (opacity * 255).round();
  }

  static img.Image _resizeForSharing(img.Image image) {
    final width = image.width;
    final height = image.height;
    final longestSide = max(width, height);

    if (longestSide <= _maxImageDimension) {
      return image;
    }

    if (width >= height) {
      return img.copyResize(
        image,
        width: _maxImageDimension,
        interpolation: img.Interpolation.average,
      );
    }

    return img.copyResize(
      image,
      height: _maxImageDimension,
      interpolation: img.Interpolation.average,
    );
  }

  static Uint8List _encodePngForSharing(img.Image image) {
    return Uint8List.fromList(img.encodePng(image, level: 2));
  }

  static double _randomAngle() {
    final stepCount = (360 / _angleStepDegrees).round();
    return _random.nextInt(stepCount) * _angleStepDegrees;
  }

  static List<_ResolvedColor> _buildColorPool(
    bool useRandomColor,
    int selectedColorValue,
    int alpha,
  ) {
    if (!useRandomColor) {
      final color = _resolveWatermarkColor(false, selectedColorValue, alpha);
      return <_ResolvedColor>[
        _ResolvedColor(key: (alpha << 24) | (selectedColorValue & 0x00FFFFFF), color: color),
      ];
    }

    return List<_ResolvedColor>.generate(_randomColorPoolSize, (index) {
      return _ResolvedColor(
        key: index,
        color: _randomWatermarkColor(alpha),
      );
    });
  }

  static _ResolvedColor _pickColor(List<_ResolvedColor> colorPool) {
    return colorPool[_random.nextInt(colorPool.length)];
  }

  static img.Color _randomWatermarkColor(int alpha) {
    final hue = _random.nextDouble() * 360;
    const saturation = 0.8;
    const value = 0.95;
    final chroma = value * saturation;
    final x = chroma * (1 - (((hue / 60) % 2) - 1).abs());
    final m = value - chroma;

    double red;
    double green;
    double blue;

    if (hue < 60) {
      red = chroma;
      green = x;
      blue = 0;
    } else if (hue < 120) {
      red = x;
      green = chroma;
      blue = 0;
    } else if (hue < 180) {
      red = 0;
      green = chroma;
      blue = x;
    } else if (hue < 240) {
      red = 0;
      green = x;
      blue = chroma;
    } else if (hue < 300) {
      red = x;
      green = 0;
      blue = chroma;
    } else {
      red = chroma;
      green = 0;
      blue = x;
    }

    return img.ColorRgba8(
      ((red + m) * 255).round(),
      ((green + m) * 255).round(),
      ((blue + m) * 255).round(),
      alpha,
    );
  }

  static img.Color _resolveWatermarkColor(
    bool useRandomColor,
    int selectedColorValue,
    int alpha,
  ) {
    if (useRandomColor) {
      return _randomWatermarkColor(alpha);
    }

    final red = (selectedColorValue >> 16) & 0xFF;
    final green = (selectedColorValue >> 8) & 0xFF;
    final blue = selectedColorValue & 0xFF;
    return img.ColorRgba8(red, green, blue, alpha);
  }

  static String _outputPath(String originalPath, String targetExtension) {
    final directory = p.dirname(originalPath);
    final baseName = p.basenameWithoutExtension(originalPath);
    return p.join(directory, 'watermarked-$baseName$targetExtension');
  }

  static String _resolvedWatermarkText(String userText) {
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final trimmed = userText.trim();
    if (trimmed.isEmpty) {
      return '$date $time';
    }
    return '$trimmed $date $time';
  }
}
