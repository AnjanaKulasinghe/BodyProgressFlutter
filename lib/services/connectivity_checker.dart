import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Helper to diagnose network connectivity issues with Firebase
class ConnectivityChecker {
  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if Firebase services are reachable
  Future<bool> canReachFirebase() async {
    try {
      await InternetAddress.lookup('firestore.googleapis.com').timeout(
        const Duration(seconds: 5),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test actual Firestore read/write
  Future<bool> testFirestoreReadWrite() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final testDoc = firestore.collection('_connectivity').doc('test');
      
      // Write test
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      }).timeout(const Duration(seconds: 5));
      
      // Read test
      final doc = await testDoc.get().timeout(const Duration(seconds: 5));
      
      // Cleanup
      await testDoc.delete();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Comprehensive connectivity check with detailed results
  Future<ConnectivityResult> diagnoseConnectivity() async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      return ConnectivityResult(
        isConnected: false,
        issue: 'No Internet Connection',
        suggestion: 'Check your WiFi or cellular data connection in Settings.',
      );
    }
    
    final canReachFirebaseServers = await canReachFirebase();
    if (!canReachFirebaseServers) {
      return ConnectivityResult(
        isConnected: false,
        issue: 'Cannot Reach Firebase Servers',
        suggestion: 'Your network may be blocking Firebase. Try:\n'
            '• Disabling VPN\n'
            '• Switching between WiFi and cellular\n'
            '• Checking firewall settings',
      );
    }
    
    final firestoreWorks = await testFirestoreReadWrite();
    if (!firestoreWorks) {
      return ConnectivityResult(
        isConnected: false,
        issue: 'Firestore Read/Write Failed',
        suggestion: 'Check:\n'
            '• Firebase project configuration\n'
            '• GoogleService-Info.plist (iOS) or google-services.json (Android)\n'
            '• Firestore security rules',
      );
    }
    
    return ConnectivityResult(
      isConnected: true,
      issue: null,
      suggestion: null,
    );
  }
}

class ConnectivityResult {
  final bool isConnected;
  final String? issue;
  final String? suggestion;

  const ConnectivityResult({
    required this.isConnected,
    this.issue,
    this.suggestion,
  });

  @override
  String toString() {
    if (isConnected) return 'Connected ✓';
    return 'Issue: $issue\n$suggestion';
  }
}
