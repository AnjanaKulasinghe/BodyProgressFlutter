import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/photo_metadata.dart';
import 'package:firebase_core/firebase_core.dart';

/// Manages all Firestore data access — users, bodyStats, photoMetadata collections.
class FirestoreService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference get _users     => _db.collection('users');
  CollectionReference get _bodyStats => _db.collection('bodyStats');
  CollectionReference get _photos    => _db.collection('photoMetadata');

  // ── Diagnostics ───────────────────────────────────────────────────────────

  /// Test Firestore connectivity by writing and reading a test document
  Future<bool> testFirestoreConnectivity() async {
    try {
      final testRef = _db.collection('_diagnostics').doc('connectivity_test');
      
      // Test write
      final testData = {
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'connectivity',
      };
      
      await testRef.set(testData).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Test write timed out');
        },
      );
      
      // Test read
      final doc = await testRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Test read timed out');
        },
      );
      
      if (!doc.exists) {
        return false;
      }
      
      // Clean up
      await testRef.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retry a Firestore operation with exponential backoff for network issues
  Future<T> _retryOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    
    while (true) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        final isNetworkError = e.code == 'unavailable' || 
                              e.code == 'deadline-exceeded' ||
                              e.code == 'cancelled';
        
        if (!isNetworkError || retryCount >= maxRetries) {
          rethrow;
        }
        
        retryCount++;
        final delayMs = (100 * (1 << retryCount)); // 200ms, 400ms, 800ms
        await Future.delayed(Duration(milliseconds: delayMs));
      } catch (e) {
        rethrow;
      }
    }
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final ref = _users.doc(profile.userId);
      await ref.set(profile.toFirestore()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('User profile save timed out');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      return await _retryOperation(
        operation: () async {
          final doc = await _users.doc(userId).get();
          if (!doc.exists) return null;
          return UserProfile.fromFirestore(doc);
        },
        operationName: 'getUserProfile',
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final ref = _users.doc(profile.userId);
      await ref.set({
        ...profile.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('User profile update timed out');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> hasUserProfile(String userId) async {
    try {
      return await _retryOperation(
        operation: () async {
          final doc = await _users.doc(userId).get();
          return doc.exists;
        },
        operationName: 'hasUserProfile',
      );
    } catch (e) {
      return false;
    }
  }

  // ── Body Stats ────────────────────────────────────────────────────────────

  Future<DocumentReference> saveBodyStats(BodyStats stats) =>
      _bodyStats.add(stats.toFirestore());

  Future<void> saveOrUpdateBodyStats(BodyStats stats) async {
    try {
      final docId = '${stats.userId}_${stats.date.millisecondsSinceEpoch}';
      final data = stats.toFirestore();
      
      await _bodyStats.doc(docId).set(data).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firestore write timed out after 10 seconds for doc: $docId');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BodyStats>> getBodyStats(String userId, {int limit = 100}) async {
    final q = await _bodyStats
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return q.docs.map(BodyStats.fromFirestore).toList();
  }

  Future<List<BodyStats>> getBodyStatsInRange(
      String userId, DateTime from, DateTime to) async {
    final q = await _bodyStats
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .get();
    return q.docs.map(BodyStats.fromFirestore).toList();
  }

  Future<BodyStats?> getLatestBodyStats(String userId) async {
    final q = await _bodyStats
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return BodyStats.fromFirestore(q.docs.first);
  }

  Future<void> updateBodyStats(BodyStats stats) async {
    if (stats.id == null) throw Exception('Cannot update BodyStats without an id');
    await _bodyStats.doc(stats.id).update(stats.toFirestore());
  }

  Future<void> deleteBodyStats(String id) => _bodyStats.doc(id).delete();

  Future<void> batchSaveBodyStats(List<BodyStats> statsList) async {
    if (statsList.isEmpty) {
      return;
    }
    
    // Use smaller batches for faster, more reliable commits
    const int batchSize = 50;
    
    for (int i = 0; i < statsList.length; i += batchSize) {
      final batch = _db.batch();
      final end = (i + batchSize < statsList.length) ? i + batchSize : statsList.length;
      final chunk = statsList.sublist(i, end);
      final chunkNum = (i ~/ batchSize) + 1;
      final totalChunks = ((statsList.length - 1) ~/ batchSize) + 1;
      
      for (final stats in chunk) {
        final docId = '${stats.userId}_${stats.date.millisecondsSinceEpoch}';
        batch.set(
          _bodyStats.doc(docId),
          stats.toFirestore(),
          SetOptions(merge: true),
        );
      }
      
      try {
        await batch.commit().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Batch commit timed out after 30 seconds (chunk $chunkNum/$totalChunks)');
          },
        );
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<List<BodyStats>> getWeightHistory(String userId, {int days = 90}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    return getBodyStatsInRange(userId, from, DateTime.now());
  }

  // ── Photo Metadata ────────────────────────────────────────────────────────

  Future<DocumentReference> savePhotoMetadata(PhotoMetadata photo) =>
      _photos.add(photo.toFirestore());

  Future<List<PhotoMetadata>> getPhotoMetadata(String userId, {int limit = 50}) async {
    final q = await _photos
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return q.docs.map(PhotoMetadata.fromFirestore).toList();
  }

  Future<List<PhotoMetadata>> getPhotoMetadataByType(
      String userId, PhotoType type) async {
    final q = await _photos
        .where('userId', isEqualTo: userId)
        .where('photoType', isEqualTo: type.value)
        .orderBy('date', descending: true)
        .get();
    return q.docs.map(PhotoMetadata.fromFirestore).toList();
  }

  Future<List<PhotoMetadata>> getPhotoMetadataInRange(
      String userId, DateTime from, DateTime to) async {
    final q = await _photos
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .get();
    return q.docs.map(PhotoMetadata.fromFirestore).toList();
  }

  Future<PhotoMetadata?> getLatestPhotoByType(
      String userId, PhotoType type) async {
    final q = await _photos
        .where('userId', isEqualTo: userId)
        .where('photoType', isEqualTo: type.value)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return PhotoMetadata.fromFirestore(q.docs.first);
  }

  Future<void> updatePhotoMetadata(PhotoMetadata photo) async {
    if (photo.id == null) throw Exception('Cannot update PhotoMetadata without an id');
    await _photos.doc(photo.id).update(photo.toFirestore());
  }

  Future<void> deletePhotoMetadata(String id) => _photos.doc(id).delete();

  Future<int> getPhotoCount(String userId) async {
    final q = await _photos.where('userId', isEqualTo: userId).count().get();
    return q.count ?? 0;
  }

  Future<int> getStatsCount(String userId) async {
    final q = await _bodyStats.where('userId', isEqualTo: userId).count().get();
    return q.count ?? 0;
  }

  // ── Batch Delete (account deletion) ─────────────────────────────────────

  Future<void> batchDeleteUserData(String userId) async {
    // Delete body stats and user profile
    final statsDocs = await _bodyStats.where('userId', isEqualTo: userId).get();
    final userDocs = await _users.where('userId', isEqualTo: userId).get();

    final batch = _db.batch();
    for (final d in statsDocs.docs)  batch.delete(d.reference);
    for (final d in userDocs.docs)   batch.delete(d.reference);
    
    await batch.commit().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Failed to delete user data - operation timed out');
      },
    );
  }
}
