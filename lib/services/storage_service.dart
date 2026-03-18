import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:body_progress/models/photo_metadata.dart';

const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
const _jpegQuality       = 80;
const _thumbnailSize     = 300;
const _thumbnailQuality  = 60;

class UploadResult {
  final String imageUrl;
  final String? thumbnailUrl;
  const UploadResult({required this.imageUrl, this.thumbnailUrl});
}

/// Handles Firebase Storage uploads, downloads, and deletions for progress photos.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<UploadResult> uploadPhoto(
    File imageFile, {
    required PhotoMetadata metadata,
  }) async {
    // Compress original
    final compressed = await _compressImage(imageFile);
    if (compressed.lengthInBytes > _maxFileSizeBytes) {
      throw Exception('Image exceeds 5 MB limit after compression');
    }

    // Upload original
    final imageRef = _storage.ref(metadata.storagePath);
    await imageRef.putData(compressed,
        SettableMetadata(contentType: 'image/jpeg'));
    final imageUrl = await imageRef.getDownloadURL();

    // Upload thumbnail
    String? thumbnailUrl;
    try {
      final thumbData = await _createThumbnail(compressed);
      final thumbRef = _storage.ref(metadata.thumbnailStoragePath);
      await thumbRef.putData(thumbData,
          SettableMetadata(contentType: 'image/jpeg'));
      thumbnailUrl = await thumbRef.getDownloadURL();
    } catch (_) {
      // Thumbnail upload failure is non-fatal
    }

    return UploadResult(imageUrl: imageUrl, thumbnailUrl: thumbnailUrl);
  }

  // ── Download / Caching ────────────────────────────────────────────────────

  Future<File?> downloadAndCachePhoto(PhotoMetadata metadata) async {
    if (metadata.id == null) return null;
    final cacheDir = await getApplicationCacheDirectory();
    final localPath = '${cacheDir.path}/photo_${metadata.id}.jpg';
    final localFile = File(localPath);

    if (await localFile.exists()) return localFile;

    try {
      final data = await _storage.ref(metadata.storagePath).getData();
      if (data == null) return null;
      await localFile.writeAsBytes(data);
      return localFile;
    } catch (_) {
      return null;
    }
  }

  Future<File?> getOrDownload(PhotoMetadata metadata) async {
    final cacheDir = await getApplicationCacheDirectory();
    // Try id-based cache
    if (metadata.id != null) {
      final f = File('${cacheDir.path}/photo_${metadata.id}.jpg');
      if (await f.exists()) return f;
    }
    // Try url-hash-based cache
    final urlHash = metadata.storageUrl.hashCode.abs();
    final hashFile = File('${cacheDir.path}/photo_$urlHash.jpg');
    if (await hashFile.exists()) return hashFile;

    // Download
    return downloadAndCachePhoto(metadata);
  }

  /// Get a fresh (non-expired) download URL for a given storage path.
  /// This bypasses stale tokens stored in Firestore.
  Future<String> getFreshDownloadUrl(String storagePath) async {
    return _storage.ref(storagePath).getDownloadURL();
  }

  /// Get a fresh thumbnail URL, falling back to full image URL.
  Future<String> getFreshThumbnailUrl(PhotoMetadata metadata) async {
    try {
      return await getFreshDownloadUrl(metadata.thumbnailStoragePath);
    } catch (_) {
      return getFreshDownloadUrl(metadata.storagePath);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deletePhoto(PhotoMetadata metadata) async {
    await _safeDelete(metadata.storagePath);
    await _safeDelete(metadata.thumbnailStoragePath);

    // Remove local cache
    if (metadata.id != null) {
      await _safeDeleteLocal(
          '${(await getApplicationCacheDirectory()).path}/photo_${metadata.id}.jpg');
    }
  }

  Future<void> deletePhotos(List<PhotoMetadata> metadataList) async {
    await Future.wait(metadataList.map(deletePhoto));
  }

  Future<void> _safeDelete(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {}
  }

  Future<void> _safeDeleteLocal(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ── Image Processing ──────────────────────────────────────────────────────

  Future<Uint8List> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Unable to decode image');

    // Resize if very large (max 2048px on longest side)
    img.Image resized = decoded;
    if (decoded.width > 2048 || decoded.height > 2048) {
      resized = decoded.width > decoded.height
          ? img.copyResize(decoded, width: 2048)
          : img.copyResize(decoded, height: 2048);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
  }

  Future<Uint8List> _createThumbnail(Uint8List imageData) async {
    final decoded = img.decodeImage(imageData);
    if (decoded == null) throw Exception('Unable to decode image');
    final thumb = img.copyResizeCropSquare(decoded, size: _thumbnailSize);
    return Uint8List.fromList(img.encodeJpg(thumb, quality: _thumbnailQuality));
  }

  // ── Validation ────────────────────────────────────────────────────────────

  Future<bool> validateImageSize(File file) async {
    final size = await file.length();
    return size <= _maxFileSizeBytes;
  }

  PhotoDimensions? getDimensions(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return PhotoDimensions(width: decoded.width, height: decoded.height);
  }
}
