import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/photo_metadata.dart';

/// Manages all Firestore data access — users, bodyStats, photoMetadata collections.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users     => _db.collection('users');
  CollectionReference get _bodyStats => _db.collection('bodyStats');
  CollectionReference get _photos    => _db.collection('photoMetadata');

  // ── User Profile ──────────────────────────────────────────────────────────

  Future<void> saveUserProfile(UserProfile profile) async {
    final ref = profile.id != null ? _users.doc(profile.id) : _users.doc(profile.userId);
    await ref.set(profile.toFirestore());
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final query = await _users.where('userId', isEqualTo: userId).limit(1).get();
    if (query.docs.isEmpty) return null;
    return UserProfile.fromFirestore(query.docs.first);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final ref = profile.id != null ? _users.doc(profile.id) : _users.doc(profile.userId);
    await ref.update({
      ...profile.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasUserProfile(String userId) async {
    final query = await _users.where('userId', isEqualTo: userId).limit(1).get();
    return query.docs.isNotEmpty;
  }

  // ── Body Stats ────────────────────────────────────────────────────────────

  Future<DocumentReference> saveBodyStats(BodyStats stats) =>
      _bodyStats.add(stats.toFirestore());

  Future<void> saveOrUpdateBodyStats(BodyStats stats) async {
    final docId = '${stats.userId}_${stats.date.millisecondsSinceEpoch}';
    await _bodyStats.doc(docId).set(stats.toFirestore(), SetOptions(merge: true));
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
    final batch = _db.batch();
    for (final s in statsList) {
      final ref = _bodyStats.doc();
      batch.set(ref, s.toFirestore());
    }
    await batch.commit();
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
