import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Lightweight wrappers around flutter_image_compress.
/// All operations return the original bytes on failure so the upload never
/// silently drops a file.
class ImageCompressor {
  ImageCompressor._();

  /// Compress a proof screenshot from a file path.
  ///
  /// Output: JPEG at quality 75, scaled to fit within 1080×1920.
  /// A 3 MB screenshot typically compresses to 350–600 KB.
  static Future<Uint8List> compressProofFile(String absolutePath) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        absolutePath,
        minWidth: 1080,
        minHeight: 1920,
        quality: 75,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (result == null || result.isEmpty) throw Exception('null result');
      debugPrint(
        '[Compress] Proof ${_kb(result)} KB',
      );
      return result;
    } catch (e) {
      debugPrint('[Compress] Proof compression failed, using original: $e');
      // Fall back to raw bytes so the upload still succeeds
      final xfile = XFile(absolutePath);
      return xfile.readAsBytes();
    }
  }

  /// Compress an app icon from raw bytes (PNG or JPEG).
  ///
  /// Output: JPEG at quality 85, scaled to fit within 512×512.
  static Future<Uint8List> compressIconBytes(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 512,
        minHeight: 512,
        quality: 85,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (result.isEmpty) throw Exception('empty result');
      debugPrint('[Compress] Icon ${_kb(result)} KB');
      return result;
    } catch (e) {
      debugPrint('[Compress] Icon compression failed, using original: $e');
      return bytes;
    }
  }

  static String _kb(Uint8List data) =>
      (data.lengthInBytes / 1024).toStringAsFixed(1);
}
