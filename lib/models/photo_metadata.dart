import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PhotoMetadata {
  final String? id;
  final String userId;
  final String fileName;
  final String storageUrl;
  final String? thumbnailUrl;
  final DateTime date;
  final PhotoType photoType;
  final double? weight;
  final String? notes;
  final bool isPublic;
  final DateTime uploadedAt;
  final int fileSize; // bytes
  final PhotoDimensions? dimensions;

  const PhotoMetadata({
    this.id,
    required this.userId,
    required this.fileName,
    required this.storageUrl,
    this.thumbnailUrl,
    required this.date,
    required this.photoType,
    this.weight,
    this.notes,
    required this.isPublic,
    required this.uploadedAt,
    required this.fileSize,
    this.dimensions,
  });

  // ── Storage paths (same structure as iOS) ────────────────────────────────

  String get storagePath => 'progress_photos/$userId/$fileName';

  String get thumbnailStoragePath {
    final nameWithoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    return 'progress_photos/$userId/thumbnails/${nameWithoutExt}_thumb.jpg';
  }

  Future<String?> get localFilePath async {
    if (id == null) return null;
    final cacheDir = await getApplicationCacheDirectory();
    return '${cacheDir.path}/photo_$id.jpg';
  }

  // ── Firestore serialisation ──────────────────────────────────────────────

  factory PhotoMetadata.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PhotoMetadata(
      id: doc.id,
      userId: d['userId'] as String,
      fileName: d['fileName'] as String,
      storageUrl: d['storageURL'] as String,
      thumbnailUrl: d['thumbnailURL'] as String?,
      date: (d['date'] as Timestamp).toDate(),
      photoType: PhotoType.fromString(d['photoType'] as String? ?? 'front'),
      weight: (d['weight'] as num?)?.toDouble(),
      notes: d['notes'] as String?,
      isPublic: d['isPublic'] as bool? ?? false,
      uploadedAt: (d['uploadedAt'] as Timestamp).toDate(),
      fileSize: (d['fileSize'] as num?)?.toInt() ?? 0,
      dimensions: d['dimensions'] != null
          ? PhotoDimensions.fromMap(d['dimensions'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'fileName': fileName,
    'storageURL': storageUrl,
    if (thumbnailUrl != null) 'thumbnailURL': thumbnailUrl,
    'date': Timestamp.fromDate(date),
    'photoType': photoType.value,
    if (weight != null) 'weight': weight,
    if (notes != null) 'notes': notes,
    'isPublic': isPublic,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'fileSize': fileSize,
    if (dimensions != null) 'dimensions': dimensions!.toMap(),
  };

  PhotoMetadata copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? storageUrl,
    String? thumbnailUrl,
    DateTime? date,
    PhotoType? photoType,
    double? weight,
    String? notes,
    bool? isPublic,
    DateTime? uploadedAt,
    int? fileSize,
    PhotoDimensions? dimensions,
  }) => PhotoMetadata(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    fileName: fileName ?? this.fileName,
    storageUrl: storageUrl ?? this.storageUrl,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    date: date ?? this.date,
    photoType: photoType ?? this.photoType,
    weight: weight ?? this.weight,
    notes: notes ?? this.notes,
    isPublic: isPublic ?? this.isPublic,
    uploadedAt: uploadedAt ?? this.uploadedAt,
    fileSize: fileSize ?? this.fileSize,
    dimensions: dimensions ?? this.dimensions,
  );

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String generateFileName(String userId, PhotoType type, {DateTime? date}) {
    final d = date ?? DateTime.now();
    final fmt = DateFormat('yyyyMMdd_HHmmss');
    return '${userId}_${type.value}_${fmt.format(d)}.jpg';
  }

  String get formattedDate => DateFormat.yMMMd().format(date);

  String? get formattedWeight =>
      weight != null ? '${weight!.toStringAsFixed(1)} kg' : null;

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Supporting types ─────────────────────────────────────────────────────────

enum PhotoType {
  front('front', 'Front View', 'person'),
  side('side', 'Side View', 'person_outline'),
  back('back', 'Back View', 'person'),
  custom('custom', 'Custom', 'camera_alt');

  const PhotoType(this.value, this.displayName, this.iconName);
  final String value;
  final String displayName;
  final String iconName;

  static PhotoType fromString(String s) =>
      PhotoType.values.firstWhere((e) => e.value == s, orElse: () => PhotoType.front);
}

class PhotoDimensions {
  final int width;
  final int height;

  const PhotoDimensions({required this.width, required this.height});

  double get aspectRatio => width / height;

  factory PhotoDimensions.fromMap(Map<String, dynamic> m) =>
      PhotoDimensions(
        width: (m['width'] as num).toInt(),
        height: (m['height'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {'width': width, 'height': height};
}
