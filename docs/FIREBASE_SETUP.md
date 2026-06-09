# Firebase Setup

The Firebase SDK is wired into the app (Auth, Firestore, Messaging, Google Sign-In).
The code is in `lib/core/firebase/`. Until you run `flutterfire configure`, the
app still boots — authentication just fails gracefully with a clear message,
and **Continue as Guest** keeps the BLE onboarding flow working for local tests.

## One-time setup

1. **Install the Firebase CLI and log in**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Install the FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```
   Make sure `~/.pub-cache/bin` is on your `PATH`.

3. **Create the project (or attach to an existing one)**
   - Go to <https://console.firebase.google.com/> and create a project named
     `chorerobotics` (or whatever fits).
   - Enable the following from the left nav:
     - **Authentication** → Sign-in methods → enable **Email/Password** and **Google**.
     - **Firestore Database** → Create database → start in *production mode*.
     - **Cloud Messaging** (enabled by default).

4. **Configure the Flutter app**
   From the project root:
   ```bash
   flutterfire configure
   ```
   Pick the `chorerobotics` project and select platforms (android, ios).
   This regenerates `lib/firebase_options.dart` with your real credentials and
   drops `android/app/google-services.json` / `ios/Runner/GoogleService-Info.plist`
   into place.

5. **Rebuild**
   ```bash
   flutter run
   ```
   The first `Firebase.initializeApp` call will now succeed.

## Firestore schema

```
users/{uid}
  uid, email, displayName, photoUrl, createdAt, updatedAt

users/{uid}/robots/{robotId}
  robotId, name, model, firmware, attachment, pairingToken,
  pairedAt, lastSeenAt, isOnline
```

## Security rules starter

Put this in `firestore.rules` and deploy with `firebase deploy --only firestore:rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /robots/{robotId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

## Notes

- `AuthService`, `UserRepository`, `RobotRepository`, and `MessagingService`
  all no-op safely when Firebase isn't initialized. You can keep developing
  BLE features without touching Firebase.
- `OnboardingBloc._persistPairedRobot` writes the paired robot to
  `users/{uid}/robots/{serial}` automatically after a successful BLE pairing,
  but only when a user is signed in (guest mode skips it).
- Google Sign-In on Android requires the SHA-1 fingerprint of your debug key
  to be registered in the Firebase project (under Project Settings → Your
  apps → Android → Add fingerprint). Run:
  ```bash
  keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
  ```
