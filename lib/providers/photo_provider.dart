import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:body_progress/models/photo_metadata.dart';
import 'package:body_progress/services/firestore_service.dart';
import 'package:body_progress/services/storage_service.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/providers/achievement_provider.dart';
import 'package:intl/intl.dart';

class PhotoState {
  final List<PhotoMetadata> photos;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;
  final bool showingAlert;
  // Upload form
  final XFile? selectedImage;
  final PhotoType selectedPhotoType;
  final DateTime photoDate;
  final String photoWeight;
  final String photoNotes;
  // Comparison
  final bool showingComparison;
  final List<PhotoMetadata> comparisonPhotos;
  final PhotoType comparisonType;
  // Upload progress
  final double uploadProgress;

  PhotoState({
    this.photos = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.errorMessage,
    this.showingAlert = false,
    this.selectedImage,
    this.selectedPhotoType = PhotoType.front,
    DateTime? photoDate,
    this.photoWeight = '',
    this.photoNotes = '',
    this.showingComparison = false,
    this.comparisonPhotos = const [],
    this.comparisonType = PhotoType.front,
    this.uploadProgress = 0.0,
  }) : photoDate = photoDate ?? DateTime.now();

  PhotoState copyWith({
    List<PhotoMetadata>? photos,
    bool? isLoading,
    bool? isUploading,
    String? errorMessage,
    bool? showingAlert,
    XFile? selectedImage,
    PhotoType? selectedPhotoType,
    DateTime? photoDate,
    String? photoWeight,
    String? photoNotes,
    bool? showingComparison,
    List<PhotoMetadata>? comparisonPhotos,
    PhotoType? comparisonType,
    double? uploadProgress,
    bool clearError = false,
    bool clearImage = false,
    bool clearForm = false,
  }) => PhotoState(
    photos: photos ?? this.photos,
    isLoading: isLoading ?? this.isLoading,
    isUploading: isUploading ?? this.isUploading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    showingAlert: clearError ? false : (showingAlert ?? this.showingAlert),
    selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
    selectedPhotoType: clearForm ? PhotoType.front : (selectedPhotoType ?? this.selectedPhotoType),
    photoDate: clearForm ? DateTime.now() : (photoDate ?? this.photoDate),
    photoWeight: clearForm ? '' : (photoWeight ?? this.photoWeight),
    photoNotes: clearForm ? '' : (photoNotes ?? this.photoNotes),
    showingComparison: showingComparison ?? this.showingComparison,
    comparisonPhotos: comparisonPhotos ?? this.comparisonPhotos,
    comparisonType: comparisonType ?? this.comparisonType,
    uploadProgress: clearForm ? 0.0 : (uploadProgress ?? this.uploadProgress),
  );
}

class PhotoNotifier extends StateNotifier<PhotoState> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  final Ref _ref;

  PhotoNotifier(this._ref) : super(PhotoState(photoDate: DateTime.now()));

  String? get _uid => _ref.read(authProvider).user?.uid;

  // ── Form ──────────────────────────────────────────────────────────────────
  void setPhotoType(PhotoType t)    => state = state.copyWith(selectedPhotoType: t);
  void setPhotoDate(DateTime d)     => state = state.copyWith(photoDate: d);
  void setPhotoWeight(String v)     => state = state.copyWith(photoWeight: v);
  void setPhotoNotes(String v)      => state = state.copyWith(photoNotes: v);
  void setComparisonType(PhotoType t) => state = state.copyWith(comparisonType: t);
  void clearError()                 => state = state.copyWith(clearError: true);

  // ── Image Picker ──────────────────────────────────────────────────────────

  Future<void> pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked != null) state = state.copyWith(selectedImage: picked);
  }

  Future<void> pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (picked != null) state = state.copyWith(selectedImage: picked);
  }

  // ── Load Photos ───────────────────────────────────────────────────────────

  Future<void> loadPhotos() async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final photos = await _firestoreService.getPhotoMetadata(uid);
      state = state.copyWith(photos: photos, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString(), showingAlert: true);
    }
  }

  // ── Upload Photo ──────────────────────────────────────────────────────────

  Future<bool> uploadPhoto() async {
    final uid = _uid;
    final img = state.selectedImage;
    if (uid == null || img == null) return false;

    state = state.copyWith(isUploading: true, uploadProgress: 0.0);
    try {
      return await _uploadPhotoFile(uid, File(img.path), state.selectedPhotoType, 
          state.photoDate, state.photoWeight, state.photoNotes);
    } catch (e) {
      state = state.copyWith(
          isUploading: false, errorMessage: e.toString(), showingAlert: true);
      return false;
    }
  }

  // Upload a photo directly from a file (for multi-photo upload journey)
  Future<bool> uploadPhotoFromFile(File file, PhotoType type, DateTime date, 
      String weight, String notes) async {
    final uid = _uid;
    if (uid == null) return false;

    state = state.copyWith(isUploading: true, uploadProgress: 0.0);
    try {
      return await _uploadPhotoFile(uid, file, type, date, weight, notes);
    } catch (e) {
      state = state.copyWith(
          isUploading: false, errorMessage: e.toString(), showingAlert: true);
      return false;
    }
  }

  Future<bool> _uploadPhotoFile(String uid, File file, PhotoType type, 
      DateTime date, String weight, String notes) async {
    try {
      // Check for existing photo of same type on same day — delete if found
      final existing = await _firestoreService.getLatestPhotoByType(uid, type);
      if (existing != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final existingDateStr = DateFormat('yyyy-MM-dd').format(existing.date);
        if (dateStr == existingDateStr) {
          await _storageService.deletePhoto(existing);
          if (existing.id != null) await _firestoreService.deletePhotoMetadata(existing.id!);
        }
      }

      state = state.copyWith(uploadProgress: 0.3);

      final fileName = PhotoMetadata.generateFileName(uid, type, date: date);
      final bytes = await _storageService.getDimensions(await file.readAsBytes());

      final metadata = PhotoMetadata(
        userId: uid,
        fileName: fileName,
        storageUrl: '', // temp — filled after upload
        date: date,
        photoType: type,
        weight: double.tryParse(weight),
        notes: notes.isEmpty ? null : notes,
        isPublic: false,
        uploadedAt: DateTime.now(),
        fileSize: await file.length(),
        dimensions: bytes,
      );

      state = state.copyWith(uploadProgress: 0.5);

      final result = await _storageService.uploadPhoto(file, metadata: metadata);

      state = state.copyWith(uploadProgress: 0.8);

      final finalMetadata = metadata.copyWith(
        storageUrl: result.imageUrl,
        thumbnailUrl: result.thumbnailUrl,
      );

      final ref = await _firestoreService.savePhotoMetadata(finalMetadata);
      final savedMetadata = finalMetadata.copyWith(id: ref.id);

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        photos: [savedMetadata, ...state.photos],
        clearForm: true,
        clearImage: true,
        clearError: true,
      );
      
      // Check for photo achievements
      _ref.read(achievementProvider.notifier).checkForNewAchievements();
      
      return true;
    } catch (e) {
      state = state.copyWith(
          isUploading: false, errorMessage: e.toString(), showingAlert: true);
      return false;
    }
  }

  // ── Delete Photo ──────────────────────────────────────────────────────────

  Future<bool> deletePhoto(PhotoMetadata photo) async {
    try {
      await _storageService.deletePhoto(photo);
      if (photo.id != null) await _firestoreService.deletePhotoMetadata(photo.id!);
      state = state.copyWith(
          photos: state.photos.where((p) => p.id != photo.id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), showingAlert: true);
      return false;
    }
  }

  // ── Comparison ────────────────────────────────────────────────────────────

  Future<void> loadComparisonPhotos(PhotoType type) async {
    // Use cached photos if available (from loadPhotos() called on app init)
    if (state.photos.isNotEmpty) {
      final filteredPhotos = state.photos
          .where((p) => p.photoType == type)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
      state = state.copyWith(
        comparisonPhotos: filteredPhotos,
        comparisonType: type,
        showingComparison: true,
      );
      return;
    }

    // Fallback: load from Firestore if cache is empty
    final uid = _uid;
    if (uid == null) return;
    final photos = await _firestoreService.getPhotoMetadataByType(uid, type);
    photos.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    state = state.copyWith(
      comparisonPhotos: photos, 
      comparisonType: type, 
      showingComparison: true,
    );
  }

  void closeComparison() => state = state.copyWith(showingComparison: false);

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<PhotoMetadata> get photosByType =>
      state.photos.where((p) => p.photoType == state.selectedPhotoType).toList();

  List<PhotoMetadata> photosByTypeFilter(PhotoType type) =>
      state.photos.where((p) => p.photoType == type).toList();
}

final photoProvider = StateNotifierProvider<PhotoNotifier, PhotoState>(
    (ref) => PhotoNotifier(ref));
