# Debug Notes - Health Sync Issue

## Problem
Health sync hangs indefinitely when writing to Firestore. Even individual `.set()` calls timeout or hang forever.

## Current Status (2026-03-19)
- Issue: Sequential Firestore writes hang on the `.set()` call
- Tested: Batch writes, sequential writes, with/without timeouts - ALL HANG
- Observation: Writes go into offline persistence queue and never sync to server
- Current approach: Disabled offline persistence (`persistenceEnabled: false`) and added debug logs

## Debug Logging Locations

### 1. lib/services/firestore_service.dart - saveOrUpdateBodyStats()
**Purpose**: Track individual Firestore write operations step-by-step
**DO NOT REMOVE**: These logs show exactly where writes hang
```dart
print('[Firestore] Doc ID: $docId');
print('[Firestore] Data keys: ${data.keys.join(", ")}');
print('[Firestore] Data size: ${data.toString().length} chars');
print('[Firestore] Calling .set() with merge...');
print('[Firestore] .set() completed in ${setElapsed}ms');
print('[Firestore] Waiting for server sync...');
print('[Firestore] Server sync complete in ${totalElapsed}ms total');
```
**Expected flow**:
- Doc ID logs immediately
- Data inspection logs immediately
- "Calling .set()" logs immediately
- ".set() completed" should log in <100ms (if hangs here, .set() is stuck)
- "Server sync complete" should log in <200ms (if hangs here, waitForPendingWrites is stuck)

### 2. lib/services/health_service.dart - syncHealthData()
**Purpose**: Track overall sync progress with clear visual separators
**DO NOT REMOVE**: Shows which record is being processed and success/fail rate
```dart
print('═══════════════════════════════════════');
print('Starting upload of ${validStats.length} records...');
print('[$recordNum/$total] Writing 2025-11-21...');
print('[$recordNum/$total] ✓ Success' / '✗ Failed');
print('Upload complete: X/Y successful, Z failed');
print('═══════════════════════════════════════');
```

### 3. lib/main.dart - Firebase initialization
**Purpose**: Confirm Firestore online-only mode is configured
**DO NOT REMOVE**: Critical for debugging connectivity
```dart
print('Configuring Firestore...');
print('Firestore configured for online-only mode');
```

## Changes Made to Fix Issue

### Attempt 1: Batch writes (FAILED)
- Replaced 31 sequential writes with single batch commit
- Result: Batch commit hung/timed out after 30-60 seconds
- Reason: Offline persistence queue backed up

### Attempt 2: Remove timeouts (FAILED)
- Removed artificial timeouts to let Firestore complete naturally
- Result: Writes hung forever, no timeout
- Reason: Still using offline persistence

### Attempt 3: Disable offline persistence + Test Writes (CURRENT)
- Set `persistenceEnabled: false` in main.dart
- Added `await firestore.enableNetwork()` 
- Removed `waitForPendingWrites()` and merge option
- Added test write to 'test' collection to verify write connectivity
- Result: TESTING - if test write fails, writes are completely blocked

## Next Steps if Still Hanging
1. **If test write hangs**: Firestore writes are completely blocked
   - Check device network connectivity (WiFi/cellular data)
   - Verify Firebase project is accessible from this device
   - Try connecting to a different network
   - Check if VPN or firewall is blocking Firebase
   - Verify GoogleService-Info.plist matches your Firebase project
   
2. **If test write succeeds but body stats fail**: Issue is specific to bodyStats collection
   - Check Firestore security rules for 'bodyStats' collection
   - Verify document ID format is valid
   - Check if data structure matches Firestore expectations

3. **If writes complete but timeout messages still appear**: UI sync issue
   - Check dialog dismissal timing in views
   - Verify post-frame callbacks are working

4. **Try Firebase Emulator**: Test with local Firestore emulator to isolate network issues

## Performance Target
- 31 records should complete in 3-5 seconds total (100-150ms per write)
- Any single write taking >5 seconds indicates a problem
