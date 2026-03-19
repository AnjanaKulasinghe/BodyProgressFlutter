import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/photo_metadata.dart';

/// Manages all Firestore data access — users, bodyStats, photoMetadata collections.
class FirestoreService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference get _users     => _db.collection('users');
  CollectionReference get _bodyStats => _db.collection('bodyStats');
  CollectionReference get _photos    => _db.collection('photoMetadata');

  // ── User Profile ──────────────────────────────────────────────────────────

  Future<void> saveUserProfile(UserProfile profile) async {
    final ref = _users.doc(profile.userId);
    await ref.set(profile.toFirestore());
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      // If document doesn't exist or there's a permission error, return null
      print('getUserProfile error: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final ref = _users.doc(profile.userId);
    await ref.set({
      ...profile.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> hasUserProfile(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      return doc.exists;
    } catch (e) {
      // If there's any error checking profile existence, return false
      print('hasUserProfile error: $e');
      return false;
    }
  }

  // ── Body Stats ────────────────────────────────────────────────────────────

  Future<DocumentReference> saveBodyStats(BodyStats stats) =>
      _bodyStats.add(stats.toFirestore());

  Future<void> saveOrUpdateBodyStats(BodyStats stats) async {
    final docId = '${stats.userId}_${stats.date.millisecondsSinceEpoch}';
    await _bodyStats.doc(docId).set(stats.toFirestore());
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
    // Use smaller batches for faster, more reliable commits
    const int batchSize = 50;
    
    for (int i = 0; i < statsList.length; i += batchSize) {
      final batch = _db.batch();
      final end = (i + batchSize < statsList.length) ? i + batchSize : statsList.length;
      final chunk = statsList.sublist(i, end);
      
      for (final stats in chunk) {
        final docId = '${stats.userId}_${stats.date.millisecondsSinceEpoch}';
        batch.set(
          _bodyStats.doc(docId),
          stats.toFirestore(),
          SetOptions(merge: true),
        );
      }
      
      // Add timeout back with generous 60 second limit for slow networks
      try {
        await batch.commit().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Firestore batch commit timed out after 60 seconds');
          },
        );
      } catch (e) {
        print('Batch write error for chunk ${(i ~/ batchSize) + 1}: $e');
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
    // Delete body stats
    final statsDocs = await _bodyStats.where('userId', isEqualTo: userId).get();
    final photosDocs = await _photos.where('userId', isEqualTo: userId).get();
    final userDocs = await _users.where('userId', isEqualTo: userId).get();

    final batch = _db.batch();
    for (final d in statsDocs.docs)  batch.delete(d.reference);
    for (final d in photosDocs.docs) batch.delete(d.reference);
    for (final d in userDocs.docs)   batch.delete(d.reference);
    await batch.commit();
  }
}
