# SafeWalk — Student Safety & Emergency Assistance App

SafeWalk is a Flutter + Dart semester-project starter with:
- Login and signup using Firebase Authentication
- Firestore-backed emergency contacts and incident records
- SOS flow that obtains GPS coordinates and prepares an SMS with a Google Maps link
- Safe Walk timer/check-in flow
- Nearby safe places screen with map-search links
- Incident report form
- Responsive, beginner-friendly UI

## Important: Firebase must be configured before real authentication/database use

This ZIP includes the complete Flutter source, but it cannot contain your private Firebase project configuration. The app opens in **Preview mode** until you connect Firebase.

### 1. Generate Flutter platform folders and install dependencies
This ZIP contains all authored app source files, but does not bundle generated Android/Web/iOS platform scaffolding or SDK build output. Open the extracted folder in VS Code and run:
```powershell
flutter create .
flutter pub get
```
This generates the platform folders for the Flutter SDK installed on your computer. If Flutter asks about overwriting your `lib/main.dart`, choose **No** / keep the existing app source.

### 2. Connect Firebase
1. Open https://console.firebase.google.com/ and create or select your Firebase project.
2. In Firebase Console, enable **Authentication → Sign-in method → Email/Password**.
3. Create a **Cloud Firestore** database.
4. Install/confirm Firebase CLI and FlutterFire CLI:
```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```
5. From this project folder run:
```powershell
flutterfire configure
```
Choose your Firebase project and platforms (Android and Web if you need both). This generates/replaces `lib/firebase_options.dart`.
6. Open `lib/app_config.dart` and change:
```dart
static const bool firebaseConfigured = false;
```
to:
```dart
static const bool firebaseConfigured = true;
```
7. Run:
```powershell
flutter pub get
flutter run
```

Do not turn the flag to `true` until `flutterfire configure` has completed successfully and Firebase Authentication + Firestore are enabled.

## Firestore security rules

For a semester demo, begin with secure per-user rules. In Firebase Console → Firestore Database → Rules, use the following rules and publish them:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /contacts/{contactId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /incidents/{incidentId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /journeys/{journeyId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Never use public read/write rules for real personal data.

## Run in Chrome
```powershell
flutter run -d chrome
```
Note: browser support for GPS depends on browser permissions and secure context. Real SOS SMS/call actions should be tested on an Android phone.

## Build Android APK
```powershell
flutter build apk --release
```
APK output:
`build/app/outputs/flutter-apk/app-release.apk`

If Android build asks for SDK setup, open Android Studio/SDK Manager and install the required Android SDK.

## Deploy Flutter Web to Firebase Hosting
1. Configure Firebase for Web using `flutterfire configure`.
2. Build:
```powershell
flutter build web --release
```
3. Install/confirm Firebase CLI and log in:
```powershell
firebase login
```
4. From the project root run:
```powershell
firebase init hosting
```
- Select your Firebase project.
- Set public directory to `build/web`.
- Configure as a single-page app: **Yes**.
- If asked to overwrite `index.html`, choose **No**.
5. Deploy:
```powershell
firebase deploy --only hosting
```
Firebase Hosting has free quotas, not unlimited usage. Review current plan and usage in Firebase Console. Keep billing on the no-cost Spark plan if you do not want paid usage.

## Safety and demo limitations
- This is a semester-project prototype, not a replacement for local emergency services.
- SOS prepares an SMS message and opens the phone's SMS composer; it does not silently send a message.
- Firestore stores a report only after Firebase is configured and the user is signed in.
- Live background location sharing, push notifications, automatic SMS delivery, and a production monitoring service are not implemented in this starter.
- Safe Places opens a map search; it does not verify that a place is currently staffed or safe.
- Test all permissions and emergency actions on a real device before presenting.

## Folder overview
- `lib/main.dart`: app entry point and theme
- `lib/app_config.dart`: Firebase setup flag
- `lib/firebase_options.dart`: placeholder; replaced by `flutterfire configure`
- `lib/services/`: authentication, Firestore, and location helpers
- `lib/screens/`: login, signup, home, contacts, safe walk, safe places, incidents
- `lib/widgets/`: shared UI components
