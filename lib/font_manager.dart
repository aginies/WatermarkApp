import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum FontSource {
  bitmap, // System bitmap fonts
  asset, // Custom TTF files in assets
}

enum WatermarkFont {
  arial('Arial', 'Arial (System Default)', true, FontSource.bitmap),
  // Asset fonts - bundled with the app (no internet required)
  liberationMono(
      'LiberationMono', 'Liberation Mono (Monospace)', false, FontSource.asset),
  liberationSerif('LiberationSerif', 'Liberation Serif (Traditional)', false,
      FontSource.asset),
  vera('Vera', 'Bitstream Vera Sans (Modern)', false, FontSource.asset);

  const WatermarkFont(
      this.fontFamily, this.displayName, this.isBitmap, this.source);

  final String fontFamily;
  final String displayName;
  final bool isBitmap; // Whether it uses bitmap fonts for watermarking
  final FontSource source;

  /// Get TextStyle for UI preview
  TextStyle getTextStyle({double fontSize = 16, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  /// Get bitmap font for watermarking (for Arial) or null for TrueType fonts
  img.BitmapFont? getBitmapFont(int fontSize) {
    if (!isBitmap) return null;

    // Only Arial uses bitmap fonts for backward compatibility and performance
    if (fontSize <= 18) return img.arial14;
    if (fontSize <= 32) return img.arial24;
    return img.arial48;
  }

  /// Get font path or family name for TrueType watermarking
  String getFontIdentifier() {
    switch (this) {
      case WatermarkFont.arial:
        return 'Arial';
      case WatermarkFont.liberationMono:
        return 'LiberationMono';
      case WatermarkFont.liberationSerif:
        return 'LiberationSerif';
      case WatermarkFont.vera:
        return 'Vera';
    }
  }

  /// Get asset path for asset-based fonts
  /// Returns null for bitmap fonts
  String? getAssetPath() {
    if (source != FontSource.asset) return null;

    switch (this) {
      case WatermarkFont.liberationMono:
        return 'assets/fonts/LiberationMono-Regular.ttf';
      case WatermarkFont.liberationSerif:
        return 'assets/fonts/LiberationSerif-Regular.ttf';
      case WatermarkFont.vera:
        return 'assets/fonts/Vera.ttf';
      default:
        return null;
    }
  }
}

class FontManager {
  static const List<WatermarkFont> availableFonts = WatermarkFont.values;

  static WatermarkFont getDefaultFont() => WatermarkFont.arial;

  static WatermarkFont? getFontByName(String name) {
    try {
      return WatermarkFont.values.firstWhere(
        (font) => font.fontFamily.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if font is available
  static Future<bool> isFontAvailable(WatermarkFont font) async {
    // All bundled fonts are always available
    return true;
  }

  /// Get fonts by source type
  static List<WatermarkFont> get assetFonts => WatermarkFont.values
      .where((font) => font.source == FontSource.asset)
      .toList();

  static List<WatermarkFont> get bitmapFonts => WatermarkFont.values
      .where((font) => font.source == FontSource.bitmap)
      .toList();

  /// Get appropriate fonts for different categories
  static List<WatermarkFont> get professionalFonts => [
        WatermarkFont.arial,
        WatermarkFont.liberationSerif,
        WatermarkFont.vera,
      ];

  static List<WatermarkFont> get modernFonts => [
        WatermarkFont.vera,
        WatermarkFont.liberationSerif,
      ];

  static List<WatermarkFont> get monospaceFonts => [
        WatermarkFont.liberationMono,
      ];

  static List<WatermarkFont> get serifFonts => [
        WatermarkFont.liberationSerif,
      ];
}
