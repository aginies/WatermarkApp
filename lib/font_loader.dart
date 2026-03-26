import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'font_manager.dart';

/// Manages loading and caching of TrueType font files for watermark rendering
class FontLoader {
  FontLoader._();
  static final FontLoader instance = FontLoader._();

  // Cache for loaded font bytes (LRU with 50MB limit)
  final Map<WatermarkFont, Uint8List> _cache = {};
  final Map<WatermarkFont, DateTime> _cacheAccess = {};
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  int _currentCacheSize = 0;

  /// Load font bytes for a given font
  /// Returns null if font cannot be loaded or is bitmap-only
  Future<Uint8List?> loadFontBytes(WatermarkFont font) async {
    // Bitmap fonts don't have TTF files
    if (font.isBitmap) return null;

    // Check cache first
    if (_cache.containsKey(font)) {
      _cacheAccess[font] = DateTime.now();
      return _cache[font];
    }

    try {
      Uint8List? bytes;

      // All non-bitmap fonts are asset fonts now
      if (font.source == FontSource.asset) {
        bytes = await _loadAssetFont(font);
      }

      if (bytes != null) {
        _addToCache(font, bytes);
      }

      return bytes;
    } catch (e) {
      debugPrint('Error loading font ${font.fontFamily}: $e');
      return null;
    }
  }

  /// Load font from assets
  Future<Uint8List?> _loadAssetFont(WatermarkFont font) async {
    final assetPath = font.getAssetPath();
    if (assetPath == null) return null;

    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to load asset font $assetPath: $e');
      return null;
    }
  }

  /// Add font bytes to cache with LRU eviction
  void _addToCache(WatermarkFont font, Uint8List bytes) {
    final size = bytes.length;

    // Evict oldest entries if cache would exceed limit
    while (_currentCacheSize + size > maxCacheSize && _cache.isNotEmpty) {
      _evictOldest();
    }

    _cache[font] = bytes;
    _cacheAccess[font] = DateTime.now();
    _currentCacheSize += size;
  }

  /// Evict the least recently used font from cache
  void _evictOldest() {
    if (_cacheAccess.isEmpty) return;

    // Find oldest accessed font
    WatermarkFont? oldest;
    DateTime? oldestTime;

    _cacheAccess.forEach((font, time) {
      if (oldestTime == null || time.isBefore(oldestTime!)) {
        oldest = font;
        oldestTime = time;
      }
    });

    if (oldest != null) {
      final bytes = _cache.remove(oldest);
      _cacheAccess.remove(oldest);
      if (bytes != null) {
        _currentCacheSize -= bytes.length;
      }
    }
  }

  /// Pre-load commonly used fonts to improve performance
  Future<void> preloadCommonFonts() async {
    // Pre-load all bundled asset fonts
    final commonFonts = [
      WatermarkFont.liberationMono,
      WatermarkFont.liberationSerif,
      WatermarkFont.vera,
    ];

    for (final font in commonFonts) {
      await loadFontBytes(font);
    }
  }

  /// Clear all cached font data
  void clearCache() {
    _cache.clear();
    _cacheAccess.clear();
    _currentCacheSize = 0;
  }

  /// Get current cache size in bytes
  int getCacheSize() => _currentCacheSize;

  /// Get number of fonts in cache
  int getCacheCount() => _cache.length;
}
