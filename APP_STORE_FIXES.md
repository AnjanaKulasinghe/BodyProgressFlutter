# App Store Rejection Fixes

## ✅ CODE FIXES COMPLETED

### 1. Sign in with Apple - Fixed
**Issue**: App was asking for name/email after Apple authentication  
**Fix Applied**:
- Updated `AuthService.signInWithApple()` to capture and store Apple-provided name
- Modified `ProfileSetupView` to pre-fill name/email from Apple credentials
- Form fields now show as disabled with helper text when data is provided by Apple
- This meets Apple's requirement that you don't re-ask for data Apple already provides

### 2. Account Creation Bug - Fixed  
**Issue**: Error `[cloud_firestore/not-found]` when creating new user profile  
**Fixes Applied**:
1. Changed `FirestoreService.updateUserProfile()` from `.update()` to `.set()` with merge
   - `.update()` fails for new users because document doesn't exist
   - `.set()` with merge works for both new and existing profiles
2. Updated profile queries to use document ID directly instead of field queries
   - Changed from `.where('userId', isEqualTo: userId)` to `.doc(userId).get()`
   - More efficient and avoids potential index/query issues
3. Added comprehensive error handling throughout profile operations
   - `loadProfile()` now catches errors gracefully
   - `saveProfile()` validates userId before saving
   - `initializeAppData()` continues even if some operations fail
4. Added delay after profile creation before navigation to ensure Firestore write completes

---

## 📝 APP STORE CONNECT ACTIONS REQUIRED

### 3. Remove Android References

**What to do**: Edit your app's "What's New" text in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to "My Apps" → "Body Progress"
3. Select the version under review (Version 4)
4. Find "What's New in This Version" section
5. Remove any mentions of:
   - Android
   - Google Play
   - Cross-platform
   - "Available on Android"
   - Any other references to competing platforms
   
**Good example**:
```
Version 4.0 - Major Update
• Enhanced photo comparison tools
• Improved progress tracking
• New statistics dashboard  
• Bug fixes and performance improvements
```

**Bad example** (what NOT to include):
```
Version 4.0
• Now available on Android and iOS
• Cross-platform sync between devices
```

### 4. Provide Demo Account

**What to do**: Add test credentials in App Review Information

1. In App Store Connect → "Body Progress" → Version 4
2. Scroll to "App Review Information" section
3. Under "Sign-in required", provide:

**Recommended Test Account**:
```
Username: reviewer@bodyprogress.com
Password: AppReview2026!
```

**IMPORTANT**: You need to create this account first!

#### Creating the Demo Account:

Option A - Create via your app:
```bash
# Run your Flutter app in debug mode
flutter run

# Then create account through the app UI with above credentials
```

Option B - Create via Firebase Console:
1. Go to Firebase Console → Authentication
2. Click "Add user"
3. Email: reviewer@bodyprogress.com
4. Password: AppReview2026!
5. Also create a user profile in Firestore:
   - Collection: `users`
   - Document ID: `<the auth uid>`
   - Add fields:
     - `userId`: (auth uid)
     - `email`: reviewer@bodyprogress.com
     - `name`: "App Reviewer"
     - `dateOfBirth`: (pick any date)
     - `gender`: "male" or "female"
     - `activityLevel`: "moderatelyActive"
     - `fitnessGoal`: "maintainWeight"
     - `createdAt`: (current timestamp)
     - `updatedAt`: (current timestamp)

**Populate Demo Data** (Optional but recommended):
- Add some sample body stats
- Upload sample photos
- This gives reviewers a better experience and shows app functionality

---

## 🚀 RESUBMISSION CHECKLIST

Before resubmitting:

- [ ] Build and test the app with latest code fixes
- [ ] Test Sign in with Apple flow end-to-end
- [ ] Test creating a new account with email/password
- [ ] Verify no crashes or errors
- [ ] Update "What's New" text in App Store Connect (remove Android refs)
- [ ] Create and test the demo account
- [ ] Add demo credentials to App Review Information
- [ ] Build and upload new version to App Store Connect
- [ ] Submit for review with a reply message

---

## 📧 SUGGESTED REPLY TO APP REVIEW

When resubmitting, reply in App Store Connect:

```
Hello App Review Team,

Thank you for the detailed feedback. We have addressed all the issues:

1. **Sign in with Apple**: Fixed - The app now uses Apple-provided name and email 
   directly without asking users to re-enter this information.

2. **Account Creation Bug**: Fixed - Resolved a database write issue that was 
   causing errors when creating new accounts.

3. **Metadata**: Updated - Removed all Android platform references from the 
   "What's New" section.

4. **Demo Account**: Provided test credentials in the App Review Information 
   section with full access to all app features.

We've thoroughly tested these changes on iPhone and iPad. Please let us know 
if you need any additional information.

Best regards,
Body Progress Team
```

---

## 🧪 TESTING THE FIXES

Test on a real iOS device before resubmitting:

```bash
# 1. Clean and build
cd /Users/anjanakulasinghe/Documents/Development/KoungaGames/BodyProgressFlutter
flutter clean
flutter pub get

# 2. Build iOS release
flutter build ios --release

# 3. Open Xcode to run on device
open ios/Runner.xcworkspace
```

Test these scenarios:
1. ✅ Sign in with Apple → Should auto-fill name/email in profile setup
2. ✅ Create new email/password account → Should save successfully
3. ✅ Demo account login → Should work with provided credentials
4. ✅ No crashes on profile creation

---

## 📱 NEXT STEPS

1. Test the code changes locally
2. Build new version (bump build number to 5)
3. Upload to App Store Connect
4. Update What's New text
5. Add demo credentials
6. Resubmit for review
