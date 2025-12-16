
<div align="center">
  
# Missing Persons Platform 



![Missing_Persons_Platform Logo](assets/icons/Missing_Persons_PlatformLogo.png)

**Real-time missing persons reporting & tracking system**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

## 📋 Overview

Missing Persons Platform is a cross-platform mobile application designed to revolutionize the process of reporting and tracking missing persons. By leveraging modern mobile technology and real-time data synchronization, the application aims to reduce critical response time and increase community engagement in search operations.

### 🎯 Key Objectives
- **Reduce search time** from hours to minutes
- **Increase report accuracy** with structured data collection
- **Mobilize community** through real-time notifications
- **Provide real-time tracking** of active searches

---

## 🏗️ Project Structure

```

Missing_Persons_Platform
├── assets
│   ├── colors
│   │   └── palette.dart
│   ├── icons
│   │   ├── Missing_Persons_Platform.png
│   │   └── Missing_Persons_PlatformLogo.png
│   ├── images
│   │   ├── 125504-customised-report.json
│   │   ├── Missing_Persons_PlatformLogo.png
│   │   ├── NearbyCont.png
│   │   ├── currect_marker.png
│   │   ├── home.png
│   │   ├── login.png
│   │   ├── mp_marker.png
│   │   ├── no_notif.png
│   │   ├── position_marker.png
│   │   ├── register.png
│   │   ├── reportCont.png
│   │   ├── verify-email.png
│   │   └── verify-email_2.png
│   ├── lottie
│   │   ├── noLocation.json
│   │   ├── noNotifications.json
│   │   ├── noReports.json
│   │   └── swipeLeft.json
│   ├── mapMPStyle.txt
│   └── map_style.json

├── cais.py
├── caisar.py
├── database.rules.json
├── firebase.json
├── functions
│   ├── index.js
│   ├── package-lock.json
│   └── package.json
├── functions.gitignore

├── lib
│   ├── Temp.dart
│   ├── assets
│   │   └── colors
│   │       └── palette.dart
│   ├── firebase_options.dart
│   ├── main.dart
│   └── views
│       ├── GmapsTest.dart
│       ├── companion
│       │   └── homepage_companion.dart
│       ├── login_view.dart
│       ├── main
│       │   ├── homepage_main.dart
│       │   ├── navigation_view_main.dart
│       │   └── pages
│       │       ├── found_persons_dashboard.dart
│       │       ├── home_main.dart
│       │       ├── nearby_main.dart
│       │       ├── notification_main.dart
│       │       ├── profile_main.dart
│       │       ├── report_main.dart
│       │       ├── report_pages
│       │       │   ├── mapDialog.dart
│       │       │   ├── p1_classifier.dart
│       │       │   ├── p2_reportee_details.dart
│       │       │   ├── p3_mp_info.dart
│       │       │   ├── p4_mp_description.dart
│       │       │   ├── p5_incident_details.dart
│       │       │   └── p6_auth_confirm.dart
│       │       ├── reports_dashboard.dart
│       │       └── update_main.dart
│       ├── register_view.dart
│       └── verify_email_view.dart

├── macos.gitignore
├── pubspec.lock
├── pubspec.yaml



```

---

## ✨ Features

### 🚨 **6-Step Reporting System**
1. **Classifier** - Incident type selection
2. **Reporter Details** - Who is reporting
3. **MP Information** - Missing person details
4. **Physical Description** - Detailed appearance
5. **Incident Details** - When and where
6. **Authentication & Confirmation** - Final verification

### 🗺️ **Real-Time Map Integration**
- Live display of nearby missing persons
- Custom markers for different incident types
- Real-time location updates
- Interactive map with detailed views

### 🔔 **Notification System**
- Push notifications for new incidents nearby
- Status updates on reported cases
- Community alerts for search operations

### 👤 **User Management**
- Secure authentication with email verification
- User profiles with reporting history
- Personalized dashboard

---

## 🛠️ Technical Implementation

### **Frontend (Flutter/Dart)**
```
// Main app structure
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Navigation structure
class NavigationViewMain extends StatefulWidget {
  const NavigationViewMain({Key? key}) : super(key: key);

  @override
  State<NavigationViewMain> createState() => _NavigationViewMainState();
}
```

Backend (Firebase)

```
// Cloud Functions (functions/index.js)
exports.sendNotificationOnNewReport = functions.database
  .ref('/reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    const report = snapshot.val();
    
    // Get users within radius
    const nearbyUsers = await getUsersWithinRadius(
      report.location.latitude,
      report.location.longitude,
      10 // 10km radius
    );
    
    // Send notifications
    await sendPushNotifications(nearbyUsers, report);
    
    return null;
  });
```

Database Structure

```
{
  "reports": {
    "reportId": {
      "reporterId": "user123",
      "incidentType": "missing_person",
      "personInfo": {
        "name": "John Doe",
        "age": 25,
        "description": "..."
      },
      "location": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "timestamp": "2024-01-15T10:30:00Z",
      "status": "active"
    }
  },
  "users": {
    "userId": {
      "email": "user@example.com",
      "name": "User Name",
      "notificationTokens": ["token1", "token2"],
      "locationPreferences": {
        "radius": 10,
        "notificationEnabled": true
      }
    }
  }
}
```

---

🚀 Getting Started

Prerequisites

· Flutter SDK 3.0+
· Dart SDK 2.19+
· Firebase account
· Google Maps API key

Installation

1. Clone the repository

```
git clone https://github.com/ashrafaliqhtan/Missing_Persons_Platform.git
cd Missing_Persons_Platform
```

1. Install dependencies

```
flutter pub get
```

1. Configure Firebase

```
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase
firebase init
```

1. Configure Google Maps

· Get API key from Google Cloud Console
· Add to android/app/src/main/AndroidManifest.xml and ios/Runner/AppDelegate.swift

1. Run the application

```
# For development
flutter run

# For production build
flutter build apk --release
```

---

📱 Screens & Navigation Flow

Authentication Flow

```
Login View → Register View → Verify Email → Main Navigation
```

Main Navigation

```
Home
├── Nearby (Map View)
├── Report (6-step workflow)
├── Notifications
├── Profile
└── Updates
```

Reporting Workflow

```
Report Main → 6-Step Process:
1. Classifier → 2. Reporter Details → 3. MP Info →
4. Description → 5. Incident Details → 6. Confirmation
```

---

🔧 Configuration Files

Firebase Configuration (firebase_options.dart)

```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Platform-specific configuration
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
```

Dependencies (pubspec.yaml)

```
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.4.0
  firebase_auth: ^4.2.0
  firebase_database: ^10.0.0
  firebase_messaging: ^14.1.0
  
  # UI & Maps
  flutter_map: ^5.0.0
  geolocator: ^9.0.0
  shared_preferences: ^2.0.0
  lottie: ^2.0.0
  
  # Utilities
  provider: ^6.0.0
  intl: ^0.18.0
  image_picker: ^0.8.0
```

---

🧪 Testing

Unit Tests

```
# Run all tests
flutter test

# Run specific test file
flutter test test/report_pages_test.dart
```

Integration Tests

```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete report flow', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());
    
    // Navigate to report screen
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // Complete 6-step process
    await _completeReportingFlow(tester);
    
    // Verify report was submitted
    expect(find.text('Report Submitted'), findsOneWidget);
  });
}
```

---

📊 Database Rules

Security Rules (database.rules.json)

```
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    
    "reports": {
      "$reportId": {
        ".validate": "
          newData.hasChildren(['reporterId', 'incidentType', 'timestamp']) &&
          newData.child('reporterId').val() === auth.uid &&
          newData.child('timestamp').isNumber()
        "
      }
    },
    
    "users": {
      "$userId": {
        ".read": "auth.uid === $userId",
        ".write": "auth.uid === $userId"
      }
    }
  }
}
```

---

🔄 Deployment

Android

```
# Generate signed APK
flutter build apk --release

# Generate app bundle
flutter build appbundle --release
```

iOS

```
# Build for iOS
flutter build ios --release

# Archive for App Store
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner archive
```

Web

```
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---



## 📸 Screenshots

<div align="center">

| | |
|:---:|:---:|
| <img src="images/screenshot_1.jpg" width="250"> | <img src="images/screenshot_2.jpg" width="250"> |
| <img src="images/screenshot_3.jpg" width="250"> | <img src="images/screenshot_4.jpg" width="250"> |
| <img src="images/screenshot_5.jpg" width="250"> | <img src="images/screenshot_6.jpg" width="250"> |
| <img src="images/screenshot_7.jpg" width="250"> | <img src="images/screenshot_8.jpg" width="250"> |
| <img src="images/screenshot_9.jpg" width="250"> | <img src="images/screenshot_10.jpg" width="250"> |
| <img src="images/screenshot_11.jpg" width="250"> | <img src="images/screenshot_12.jpg" width="250"> |
| <img src="images/screenshot_13.jpg" width="250"> | <img src="images/screenshot_14.jpg" width="250"> |
| <img src="images/screenshot_15.jpg" width="250"> | <img src="images/screenshot_16.jpg" width="250"> |
| <img src="images/screenshot_17.jpg" width="250"> | <img src="images/screenshot_18.jpg" width="250"> |
| <img src="images/screenshot_19.jpg" width="250"> | <img src="images/screenshot_20.jpg" width="250"> |
| <img src="images/screenshot_21.jpg" width="250"> | <img src="images/screenshot_22.jpg" width="250"> |
| <img src="images/screenshot_23.jpg" width="250"> | <img src="images/screenshot_24.jpg" width="250"> |
| <img src="images/screenshot_25.jpg" width="250"> | <img src="images/screenshot_26.jpg" width="250"> |
| <img src="images/screenshot_27.jpg" width="250"> | <img src="images/screenshot_28.jpg" width="250"> |
| <img src="images/screenshot_29.jpg" width="250"> | <img src="images/screenshot_30.jpg" width="250"> |
| <img src="images/screenshot_31.jpg" width="250"> | |

</div>




---
# User Journey Visualized:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Login     │────▶│    Home     │────▶│    Map      │
└─────────────┘     └─────────────┘     └─────────────┘
                          │                     │
                          ▼                     ▼
                    ┌─────────────┐     ┌─────────────┐
                    │   Report    │◀────│  Nearby     │
                    │ (6 Steps)   │     │  Reports    │
                    └─────────────┘     └─────────────┘
```

</div>



Legend:

· 🟢 Green Marker: Current user location
· 🔴 Red Marker: Active missing person report
· 🟡 Yellow Marker: Recently resolved case
· 🔵 Blue Marker: Community volunteer location

</div>

---

🤝 Contributing

1. Fork the repository
2. Create a feature branch (git checkout -b feature/amazing-feature)
3. Commit changes (git commit -m 'Add amazing feature')
4. Push to branch (git push origin feature/amazing-feature)
5. Open a Pull Request

Code Style Guidelines

· Follow Dart/Flutter style guide
· Use meaningful variable names
· Add comments for complex logic
· Write tests for new features

---

📞 Support

Documentation

· Flutter Documentation
· Firebase Documentation
· API Reference

Community

· GitHub Issues
· Discord Community
· Stack Overflow

---
## Contact Information

<div align="center">

[![Email](https://img.shields.io/badge/Email-aq96650@gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:aq96650@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-ashrafaliqhtan-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ashrafaliqhtan)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ashraf_Ali_Qhtan-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ashraf-ali-qhtan-877954205)
[![Facebook](https://img.shields.io/badge/Facebook-Profile-1877F2?style=for-the-badge&logo=facebook&logoColor=white)](https://www.facebook.com/share/1WL9xwUsP6/)

</div>
📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

🙏 Acknowledgments

<div align="center">

Special Thanks To

<table>
<tr>
<td align="center">
<a href="https://www.openstreetmap.org">
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQBDkwrm5ahQXFjxYOxz_WIp_CSzm7IRJI1xJx7z6qvBA&s=10" width="100" alt="OpenStreetMap">
<br>
<strong>OpenStreetMap</strong>
</a>
</td>
<td align="center">
<a href="https://firebase.google.com">
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZKrUjKc4YRQ-rDL7jV92w_OkQDg22iW0WFP6t9fCAjSA2vtKn_Qan3mwd&s=10" width="100" alt="Firebase">
<br>
<strong>Google Firebase</strong>
</a>
</td>
<td align="center">
<a href="https://flutter.dev">
<img src="https://storage.googleapis.com/cms-storage-bucket/4fd5520fe28ebf839174.svg" width="100" alt="Flutter">
<br>
<strong>Flutter</strong>
</a>
</td>
</tr>
</table>

And to every emergency responder, volunteer, and contributor who makes this project possible.

</div>

---

<div align="center">

⭐ Support The Project

If you find this project useful, please consider giving it a star! It helps more people discover Missing_Persons_Platform.



Together, we can make communities safer.

---
</div>





