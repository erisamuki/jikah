# Jikah - Mobile Application

A modern Flutter mobile application built with Firebase backend integration, providing a seamless user experience with cloud-based data management and real-time synchronization.

**Status:** In Development | **Version:** 1.0.0 | **Platform:** iOS & Android

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [System Architecture](#system-architecture)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Firebase Setup](#firebase-setup)
- [Building for Production](#building-for-production)
- [Testing](#testing)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Support](#support)

---

## 📱 Overview

Jikah is a feature-rich Flutter mobile application that leverages Firebase services for authentication, cloud storage, and real-time database capabilities. The application is designed to deliver a responsive, intuitive user experience across iOS and Android platforms.

**Key Capabilities:**
- **Firebase Authentication** - Secure user authentication with multiple auth providers
- **Cloud Firestore** - Real-time NoSQL database for dynamic data management
- **Firebase Storage** - Cloud storage for images and media files
- **State Management** - Provider pattern for efficient state handling
- **Local Storage** - Persistent local data with SharedPreferences
- **Image Management** - Native image picker with upload capabilities
- **Internationalization** - Multi-language support ready
- **Cross-Platform** - Native iOS and Android applications

---

## ✨ Features

- 🔐 **User Authentication** - Secure login/signup with Firebase Auth
- ☁️ **Cloud Sync** - Real-time data synchronization via Firestore
- 📸 **Media Management** - Image picking and cloud storage integration
- 💾 **Offline Support** - Local data caching with SharedPreferences
- 🌐 **Multi-Language** - Internationalization framework ready
- 🎨 **Material Design** - Modern, responsive UI components
- 🔔 **Push Notifications** - Ready for Firebase Cloud Messaging
- 📱 **Responsive Layout** - Adaptive design for all screen sizes

---

## 🛠️ Technology Stack

### Frontend (Mobile)
| Technology | Purpose | Version |
|-----------|---------|---------|
| **Flutter** | UI framework | ^3.11.1 |
| **Dart** | Programming language | ^3.11.1+ |
| **Provider** | State management | ^6.1.5+1 |
| **Firebase Core** | Firebase initialization | ^4.6.0 |
| **Firebase Auth** | User authentication | ^6.3.0 |
| **Cloud Firestore** | NoSQL database | ^6.2.0 |
| **Firebase Storage** | Cloud storage | ^13.2.0 |
| **SharedPreferences** | Local storage | ^2.5.5 |
| **Image Picker** | Image selection | ^1.2.1 |

### Utilities & Libraries
- **intl** - Date/time formatting and localization (^0.20.2)
- **uuid** - UUID generation (^4.5.3)
- **http** - HTTP client for API calls (^1.6.0)
- **url_launcher** - Open URLs and make calls (^6.3.2)
- **flutter_lints** - Code analysis and linting (^6.0.0)

### UI Components
- **Material Icons** - Extensive icon library
- **Cupertino Icons** - iOS-style icons (^1.0.8)

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────┐
│    Jikah Flutter Mobile App         │
│  ├─ UI Layer (Material Design)      │
│  ├─ Provider (State Management)     │
│  └─ Services Layer                  │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┬──────────┬──────────┐
        │             │          │          │
        ▼             ▼          ▼          ▼
┌──────────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ Firebase     │ │ Local  │ │ HTTP   │ │ Image  │
│ Services     │ │Storage │ │Client  │ │Picker  │
└──────────────┘ └────────┘ └────────┘ └────────┘
        │
┌───────┴──────────────────────┬───────────────────┐
│                              │                   │
▼                              ▼                   ▼
┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐
│ Firebase Auth   │  │ Cloud Firestore  │  │ Firebase        │
│ (User Login)    │  │ (Real-time Data) │  │ Storage (Files) │
└─────────────────┘  └──────────────────┘  └─────────────────┘
```

---

## 📋 Prerequisites

Ensure you have the following installed:

### Required Software
- **Flutter SDK** version 3.11.1 or higher
- **Dart** SDK (bundled with Flutter)
- **Xcode** 14.0+ (for iOS development)
- **Android Studio** 2023.1+ (for Android development)
- **CocoaPods** (for iOS dependency management)
- **Git** for version control

### Development Environment
- A code editor (VS Code, Android Studio, or IntelliJ)
- A physical device or emulator for testing

### Firebase Project
- Google Firebase account (https://firebase.google.com/)
- Firebase project created and configured

### Verify Installation
```bash
flutter --version          # Flutter version
dart --version             # Dart version
xcode-select --install     # Xcode (macOS only)
android --version          # Android SDK
```

---

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/erisamuki/jikah.git
cd jikah
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

This command downloads all packages specified in `pubspec.yaml`.

### 3. Upgrade Flutter (Optional but Recommended)
```bash
flutter upgrade
```

### 4. Setup iOS Dependencies
```bash
cd ios
pod install
cd ..
```

### 5. Verify Setup
```bash
flutter doctor
```

Ensure all checks pass before proceeding. Address any warnings or errors indicated.

---

## ⚙️ Configuration

### Firebase Configuration

#### For iOS
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/GoogleService-Info.plist`
3. Add to Xcode project

#### For Android
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`
3. Ensure build.gradle includes Google Services plugin

### Environment Setup

Create `.env` file in the root directory (if needed):
```bash
# Firebase Configuration (if using custom endpoints)
FIREBASE_API_KEY=your_api_key_here
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here

# App Configuration
APP_NAME=Jikah
APP_VERSION=1.0.0
```

**Note:** Firebase configuration is typically handled via GoogleService-Info.plist and google-services.json

---

## 🎯 Running the Application

### Run on Connected Device/Emulator
```bash
flutter run
```

### Run with Verbose Logging
```bash
flutter run -v
```

### Run on Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

### Run on iOS Emulator
```bash
flutter run -d "iPhone 15 Plus"
```

### Run on Android Emulator
```bash
flutter run -d "emulator-5554"
```

### Hot Reload (During Development)
Once the app is running:
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

---

## 📁 Project Structure

```
jikah/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── config/
│   │   ├── firebase_config.dart     # Firebase initialization
│   │   └── app_config.dart          # App configuration
│   ├── screens/
│   │   ├── auth/                    # Authentication screens
│   │   ├── home/                    # Home screen
│   │   └── [feature_screens]/       # Feature-specific screens
│   ├── widgets/
│   │   ├── common/                  # Reusable widgets
│   │   └── [feature_widgets]/       # Feature-specific widgets
│   ├── models/
│   │   ├── user_model.dart          # User data model
│   │   └── [other_models]/          # Domain models
│   ├── services/
│   │   ├── firebase_service.dart    # Firebase operations
│   │   ├── auth_service.dart        # Authentication logic
│   │   ├── storage_service.dart     # Cloud storage
│   │   └── local_storage_service.dart  # Local persistence
│   ├── providers/
│   │   ├── auth_provider.dart       # Auth state management
│   │   └── [other_providers]/       # Feature providers
│   ├── utils/
│   │   ├── constants.dart           # Application constants
│   │   ├── validators.dart          # Input validation
│   │   └── helpers.dart             # Utility functions
│   └── l10n/                        # Localization files
├── android/
│   ├── app/
│   │   ├── google-services.json     # Firebase Android config
│   │   └── build.gradle             # Android build settings
│   └── ...
├── ios/
│   ├── Runner/
│   │   ├── GoogleService-Info.plist # Firebase iOS config
│   │   └── Podfile                  # iOS dependencies
│   └── ...
├── pubspec.yaml                     # Project dependencies
├── pubspec.lock                     # Locked dependency versions
├── analysis_options.yaml            # Lint rules
└── README.md                        # This file
```

---

## 🔄 Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/new-feature
```

### 2. Update Dependencies (if needed)
```bash
flutter pub upgrade
```

### 3. Generate Models (if using code generation)
```bash
flutter pub run build_runner build
```

### 4. Write and Test Code
```bash
# Run tests
flutter test

# Run specific test file
flutter test test/models/user_model_test.dart
```

### 5. Format and Analyze Code
```bash
# Format code
dart format lib/

# Analyze code
flutter analyze

# Fix common issues
dart fix --apply
```

### 6. Commit Changes
```bash
git add .
git commit -m "feat: add new feature"
```

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code formatting
- `refactor:` Code reorganization
- `test:` Test additions
- `chore:` Maintenance tasks

### 7. Push and Create Pull Request
```bash
git push origin feature/new-feature
```

---

## 🔥 Firebase Setup

### Initialize Firebase in the App

The Firebase initialization is handled in `lib/config/firebase_config.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

Call this in `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MyApp());
}
```

### Firebase Services

#### Authentication
```dart
// Sign up
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Login
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Logout
await FirebaseAuth.instance.signOut();
```

#### Firestore Database
```dart
// Add document
await FirebaseFirestore.instance.collection('users').add({
  'name': 'John Doe',
  'email': 'john@example.com',
  'createdAt': Timestamp.now(),
});

// Get document
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

// Real-time listener
FirebaseFirestore.instance
    .collection('users')
    .snapshots()
    .listen((snapshot) {
  // Handle updates
});
```

#### Cloud Storage
```dart
// Upload file
final file = File(path);
await FirebaseStorage.instance
    .ref('uploads/image.jpg')
    .putFile(file);

// Download URL
final url = await FirebaseStorage.instance
    .ref('uploads/image.jpg')
    .getDownloadURL();
```

---

## 🏗️ Building for Production

### iOS Build

#### Create Release Build
```bash
flutter build ios --release
```

#### Archive for App Store
```bash
flutter build ios --release
cd ios
xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcodebuild -workspace Runner.xcworkspace -scheme Runner -config Release -derivedDataPath build
cd ..
```

#### Using Xcode UI
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Product" → "Archive"
3. Sign and upload to App Store Connect

### Android Build

#### Create Release Build
```bash
flutter build apk --release
```

#### Create App Bundle for Play Store
```bash
flutter build appbundle --release
```

#### Sign Release Build
```bash
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/key.jks build/app/outputs/apk/release/app-release-unsigned.apk \
  alias_name
```

---

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

Generate coverage report:
```bash
lcov --remove coverage/lcov.info 'lib/generated/*' -o coverage/lcov_filtered.info
genhtml coverage/lcov_filtered.info -o coverage/html
```

### Widget Testing
```dart
testWidgets('Login button displays', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

### Unit Testing
```dart
test('Email validation', () {
  expect(isValidEmail('test@example.com'), true);
  expect(isValidEmail('invalid-email'), false);
});
```

---

## 🔐 Security Best Practices

1. **Environment Variables** - Store sensitive data in `.env` (never commit)
2. **Firebase Security Rules** - Configure Firestore and Storage rules
3. **API Keys** - Use Firebase restrictions for API keys
4. **Authentication** - Enable multi-factor authentication in Firebase
5. **Data Encryption** - Use SSL/TLS for data transmission
6. **Input Validation** - Validate all user inputs
7. **Error Handling** - Implement proper error handling without exposing sensitive info
8. **Dependencies** - Regularly update packages for security patches

### Firebase Security Rules Example
```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## 🐛 Troubleshooting

### Common Issues

#### Pod Install Error (iOS)
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

#### Build Cache Issues
```bash
flutter clean
flutter pub get
flutter run
```

#### Firebase Configuration Missing
- Verify `GoogleService-Info.plist` (iOS) exists
- Verify `google-services.json` (Android) exists
- Check Firebase Console project settings

#### Emulator Not Starting
```bash
# List available emulators
flutter emulators

# Start emulator
flutter emulators --launch emulator_name

# Create new emulator
flutter emulators --create --name emulator_name
```

#### Dependency Conflicts
```bash
flutter pub get --offline
flutter pub upgrade
flutter pub outdated
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### 1. Fork the Repository
```bash
git clone https://github.com/erisamuki/jikah.git
cd jikah
```

### 2. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 3. Follow Code Style
```bash
# Format code
dart format lib/

# Check code quality
flutter analyze
```

### 4. Write Tests
- Add tests for new features
- Ensure existing tests pass

### 5. Commit with Clear Messages
```bash
git commit -m "feat: add new authentication method"
```

### 6. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

### 7. PR Requirements
- Clear description of changes
- Reference related issues
- All tests passing
- Code formatted and analyzed
- At least one review approval

---

## 📚 Resources

### Official Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Package](https://pub.dev/packages/provider)

### Learning Resources
- [Flutter Codelabs](https://flutter.dev/codelabs)
- [Firebase Tutorials](https://firebase.google.com/docs/database)
- [Dart Cookbook](https://dart.dev/guides)

---

## 📦 Dependencies Overview

| Package | Purpose | Latest Version |
|---------|---------|-----------------|
| firebase_core | Firebase initialization | ^4.6.0 |
| firebase_auth | User authentication | ^6.3.0 |
| cloud_firestore | NoSQL database | ^6.2.0 |
| firebase_storage | Cloud file storage | ^13.2.0 |
| provider | State management | ^6.1.5+1 |
| shared_preferences | Local data storage | ^2.5.5 |
| image_picker | Image selection | ^1.2.1 |
| intl | Internationalization | ^0.20.2 |
| uuid | UUID generation | ^4.5.3 |

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 🆘 Support & Contact

### Report Issues
- GitHub Issues: [Jikah Issues](https://github.com/erisamuki/jikah/issues)
- Include device info, Flutter version, and error logs

### Contact
- **Developer:** Erisamuki
- **Email:** erisamukisa51@gmail.com
- **GitHub:** [@erisamuki](https://github.com/erisamuki)

---

## 🎯 Roadmap

- [ ] Push notifications (FCM)
- [ ] Offline-first architecture
- [ ] Advanced state management refactor
- [ ] Deep linking support
- [ ] Biometric authentication
- [ ] App performance optimization
- [ ] Comprehensive testing suite
- [ ] CI/CD pipeline setup
- [ ] Analytics integration
- [ ] App Store/Play Store release

---

## ⭐ Acknowledgments

- Flutter community for excellent documentation
- Firebase for reliable backend services
- All contributors and maintainers

---

**Last Updated:** September 3, 2026  
**Version:** 1.0.0  
**Status:** Active Development

For the latest updates, visit the [GitHub repository](https://github.com/erisamuki/jikah).
