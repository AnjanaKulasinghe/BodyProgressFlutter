# Firestore Security Rules Check

## Current Issue
- Reads work fine (you can view data)
- ALL writes hang indefinitely (even test writes to 'test' collection)
- persistenceEnabled set to false
- Network explicitly enabled

## Most Likely Cause: Security Rules Blocking Writes

### Check Your Rules in Firebase Console
1. Go to https://console.firebase.google.com
2. Select your project
3. Click "Firestore Database" 
4. Click "Rules" tab

### Your rules should look like this for testing:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /bodyStats/{document} {
      allow read, write: if request.auth != null;
    }
    
    match /test/{document} {
      allow read, write: if request.auth != null;
    }
    
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /photoMetadata/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Temporary Open Rules (FOR TESTING ONLY - NOT PRODUCTION):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // WARNING: Open to everyone!
    }
  }
}
```

## After Changing Rules
1. Save rules in Firebase Console
2. Wait 10-30 seconds for propagation
3. Try sync again

## If Still Hanging After Rule Changes
Check these:
- [ ] Device has internet connectivity (try opening a website)
- [ ] Not using VPN that blocks Firebase
- [ ] Firebase project ID matches GoogleService-Info.plist
- [ ] User is authenticated (check if request.auth.uid is valid)
- [ ] Try restarting the app completely
