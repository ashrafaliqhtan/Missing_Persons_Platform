
<div align="center">

# 🆘 **Missing Persons Platform** 

## **Revolutionizing Search & Rescue Operations** ✨

![Missing_Persons_Platform Logo](assets/icons/Missing_Persons_PlatformLogo.png)

### *When Every Second Counts* ⏱️

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](CONTRIBUTING.md)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-important?style=for-the-badge)](https://github.com/ashrafaliqhtan/Missing_Persons_Platform)

**Real-time missing persons reporting & tracking system** 🚨

</div>

---

## 📋 **Overview** 🌟

**Missing Persons Platform** is a cross-platform mobile application designed to revolutionize the process of reporting and tracking missing persons. By leveraging modern mobile technology and real-time data synchronization, the application aims to reduce critical response time and increase community engagement in search operations.

### 🎯 **Key Objectives** 🎖️
- **Reduce search time** ⏱️ from hours to minutes
- **Increase report accuracy** ✅ with structured data collection
- **Mobilize community** 👥 through real-time notifications
- **Provide real-time tracking** 📍 of active searches

---

## 🏗️ **Project Structure** 📂

```
Missing_Persons_Platform
├── 📁 assets
│   ├── 📁 colors
│   │   └── 📄 palette.dart
│   ├── 📁 icons
│   │   ├── 🖼️ Missing_Persons_Platform.png
│   │   └── 🖼️ Missing_Persons_PlatformLogo.png
│   ├── 📁 images
│   │   ├── 🎬 125504-customised-report.json
│   │   ├── 🖼️ Missing_Persons_PlatformLogo.png
│   │   ├── 🖼️ NearbyCont.png
│   │   ├── 🎯 currect_marker.png
│   │   ├── 🏠 home.png
│   │   ├── 🔐 login.png
│   │   ├── 🎯 mp_marker.png
│   │   ├── 🔕 no_notif.png
│   │   ├📍 position_marker.png
│   │   ├── 📝 register.png
│   │   ├── 📋 reportCont.png
│   │   ├── ✉️ verify-email.png
│   │   └── ✉️ verify-email_2.png
│   ├── 📁 lottie
│   │   ├── 🗺️ noLocation.json
│   │   ├── 🔕 noNotifications.json
│   │   ├── 📋 noReports.json
│   │   └── 👆 swipeLeft.json
│   ├── 📄 mapMPStyle.txt
│   └── 📄 map_style.json

├── 📄 cais.py
├── 📄 caisar.py
├── 📄 database.rules.json
├── 📄 firebase.json
├── 📁 functions
│   ├── 📄 index.js
│   ├── 📄 package-lock.json
│   └── 📄 package.json
├── 📄 functions.gitignore

├── 📁 lib
│   ├── 📄 Temp.dart
│   ├── 📁 assets
│   │   └── 📁 colors
│   │       └── 📄 palette.dart
│   ├── 📄 firebase_options.dart
│   ├── 📄 main.dart
│   └── 📁 views
│       ├── 📄 GmapsTest.dart
│       ├── 📁 companion
│       │   └── 📄 homepage_companion.dart
│       ├── 📄 login_view.dart
│       ├── 📁 main
│       │   ├── 📄 homepage_main.dart
│       │   ├── 📄 navigation_view_main.dart
│       │   └── 📁 pages
│       │       ├── 📄 found_persons_dashboard.dart
│       │       ├── 📄 home_main.dart
│       │       ├── 📄 nearby_main.dart
│       │       ├── 📄 notification_main.dart
│       │       ├── 📄 profile_main.dart
│       │       ├── 📄 report_main.dart
│       │       ├── 📁 report_pages
│       │       │   ├── 📄 mapDialog.dart
│       │       │   ├── 📄 p1_classifier.dart
│       │       │   ├── 📄 p2_reportee_details.dart
│       │       │   ├── 📄 p3_mp_info.dart
│       │       │   ├── 📄 p4_mp_description.dart
│       │       │   ├── 📄 p5_incident_details.dart
│       │       │   └── 📄 p6_auth_confirm.dart
│       │       ├── 📄 reports_dashboard.dart
│       │       └── 📄 update_main.dart
│       ├── 📄 register_view.dart
│       └── 📄 verify_email_view.dart

├── 📄 macos.gitignore
├── 📄 pubspec.lock
├── 📄 pubspec.yaml
```

<div align="center">

### **🏗️ Architecture Visualization**
 

<img src="images/screenshot_36.jpg" width="250">
</div>

---

## ✨ **Features** 🚀

### 🚨 **6-Step Reporting System** 📋
<div align="center">

| Step | Icon | Feature | Description |
|------|------|---------|-------------|
| **1** | 🏷️ | **Classifier** | Incident type selection |
| **2** | 👤 | **Reporter Details** | Who is reporting |
| **3** | 🔍 | **MP Information** | Missing person details |
| **4** | 🎨 | **Physical Description** | Detailed appearance |
| **5** | 📍 | **Incident Details** | When and where |
| **6** | ✅ | **Authentication & Confirmation** | Final verification |

</div>

### 🗺️ **Real-Time Map Integration** 🌍
<div align="center">

```dart
// 🗺️ Live Map Implementation Example
MarkerLayer(
  markers: [
    Marker(
      point: LatLng(40.7128, -74.0060),
      width: 80,
      height: 80,
      child: Icon(Icons.location_pin, color: Colors.red, size: 40),
    ),
  ],
),
```

</div>

**Map Features:**
- 🎯 **Live display** of nearby missing persons
- 🎨 **Custom markers** for different incident types
- 🔄 **Real-time location updates**
- 🖱️ **Interactive map** with detailed views
- 🎨 **Custom map styles** for better visibility

### 🔔 **Notification System** 📢
<div align="center">

**Notification Types:**
| Type | Icon | Description |
|------|------|-------------|
| **Emergency Alert** | 🚨 | New incidents nearby |
| **Status Update** | 🔄 | Report status changes |
| **Community Alert** | 👥 | Search operations |
| **Verification** | ✅ | Email confirmation |

</div>

### 👤 **User Management** 🔐
<div align="center">

**User Features:**
- 🔒 **Secure authentication** with email verification
- 📊 **User profiles** with reporting history
- 🎛️ **Personalized dashboard**
- ⚙️ **Customizable preferences**
- 📱 **Multi-device sync**

</div>

---

## 🛠️ **Technical Implementation** ⚙️

### **Frontend (Flutter/Dart)** 📱
<div align="center">

```dart
// 🚀 Main app structure
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🎨 Set up app theming
  runApp(
    MaterialApp(
      title: 'Missing Persons Platform',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    ),
  );
}

// 🧭 Navigation structure
class NavigationViewMain extends StatefulWidget {
  const NavigationViewMain({Key? key}) : super(key: key);

  @override
  State<NavigationViewMain> createState() => _NavigationViewMainState();
}

class _NavigationViewMainState extends State<NavigationViewMain> {
  int _selectedIndex = 0;
  
  // 📋 Navigation destinations
  final List<Widget> _pages = [
    HomeMain(),
    NearbyMain(),
    ReportMain(),
    NotificationMain(),
    ProfileMain(),
  ];
}
```

</div>

### **Backend (Firebase)** ☁️
<div align="center">

```javascript
// 🔔 Cloud Functions (functions/index.js)
exports.sendNotificationOnNewReport = functions.database
  .ref('/reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    const report = snapshot.val();
    const reportId = context.params.reportId;
    
    // 📍 Get users within radius
    const nearbyUsers = await getUsersWithinRadius(
      report.location.latitude,
      report.location.longitude,
      10 // 10km radius
    );
    
    // 📤 Send notifications
    await sendPushNotifications(nearbyUsers, report);
    
    // 📊 Log activity
    console.log(`Notification sent for report ${reportId}`);
    
    return null;
  });
```

</div>

### **Database Structure** 🗃️
<div align="center">

```json
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

</div>

---

## 🚀 **Getting Started** 🏁

### **Prerequisites** 📋
<div align="center">

| Requirement | Version | Installation |
|-------------|---------|--------------|
| **Flutter SDK** | 3.0+ | [Install Guide](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 2.19+ | Included with Flutter |
| **Firebase Account** | - | [Create Account](https://firebase.google.com) |
| **Google Maps API Key** | - | [Get API Key](https://cloud.google.com/maps-platform) |

</div>

### **Installation** 🔧

#### **1️⃣ Clone the repository** 📥
```bash
git clone https://github.com/ashrafaliqhtan/Missing_Persons_Platform.git
cd Missing_Persons_Platform
```

#### **2️⃣ Install dependencies** 📦
```bash
flutter pub get
```

#### **3️⃣ Configure Firebase** 🔥
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase
firebase init
```

#### **4️⃣ Configure Google Maps** 🗺️
- Get API key from [Google Cloud Console](https://console.cloud.google.com)
- Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```
- Add to `ios/Runner/AppDelegate.swift` for iOS

#### **5️⃣ Run the application** ▶️
```bash
# For development
flutter run

# For production build
flutter build apk --release

# For iOS build
flutter build ios --release
```

---

## 📱 **Screens & Navigation Flow** 🧭

### **Authentication Flow** 🔐
<div align="center">
<img src="images/screenshot_33.jpg" width="250">


</div>

### **Main Navigation** 🧭
<div align="center">

```
🏠 Home
├── 🗺️ Nearby (Map View)
├── 📋 Report (6-step workflow)
├── 🔔 Notifications
├── 👤 Profile
└── 📊 Updates
```

</div>

### **Reporting Workflow** 📋
<div align="center">

<img src="images/screenshot_34.jpg" width="250">

</div>

---

## 🔧 **Configuration Files** ⚙️

### **Firebase Configuration** 🔥
<div align="center">

```dart
// 📄 firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // 🌐 Platform-specific configuration
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

  // 🤖 Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
```

</div>

### **Dependencies** 📦
<div align="center">

```yaml
# 📄 pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 🔥 Firebase
  firebase_core: ^2.4.0
  firebase_auth: ^4.2.0
  firebase_database: ^10.0.0
  firebase_messaging: ^14.1.0
  
  # 🎨 UI & Maps
  flutter_map: ^5.0.0
  geolocator: ^9.0.0
  shared_preferences: ^2.0.0
  lottie: ^2.0.0
  
  # 🛠️ Utilities
  provider: ^6.0.0
  intl: ^0.18.0
  image_picker: ^0.8.0
```

</div>

---

## 🧪 **Testing** ✅

### **Unit Tests** 🧩
<div align="center">

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/report_pages_test.dart

# Run with coverage
flutter test --coverage
```

</div>

### **Integration Tests** 🔗
<div align="center">

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete report flow', (WidgetTester tester) async {
    // 🏗️ Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());
    
    // 🧭 Navigate to report screen
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // 📋 Complete 6-step process
    await _completeReportingFlow(tester);
    
    // ✅ Verify report was submitted
    expect(find.text('Report Submitted'), findsOneWidget);
  });
}
```

</div>

---

## 📊 **Database Rules** 🔒

### **Security Rules** 🛡️
<div align="center">

```json
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

</div>

---

## 🔄 **Deployment** 🚀

### **Android** 🤖
<div align="center">

```bash
# Generate signed APK
flutter build apk --release

# Generate app bundle
flutter build appbundle --release

# Build for specific flavors
flutter build apk --flavor production --release
```

</div>

### **iOS** 🍎
<div align="center">

```bash
# Build for iOS
flutter build ios --release

# Clean build
flutter clean && flutter build ios --release

# Archive for App Store
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner archive
```

</div>

### **Web** 🌐
<div align="center">

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Deploy with specific project
firebase deploy --project your-project-id
```

</div>

---

## 📸 **Screenshots** 🖼️

<div align="center">

### **Application Screenshots Gallery** 📱

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

<div align="center">

## 🧭 **User Journey Visualized** 🗺️

<img src="images/screenshot_35.jpg" width="250">

### **🗺️ Map Legend Guide** 🎯
| Marker | Icon | Meaning | Description |
|--------|------|---------|-------------|
| **Current Location** | 🟢 | Your Location | Current user position with accuracy radius |
| **Active Report** | 🔴 | Missing Person | Active case requiring attention |
| **Recent Resolution** | 🟡 | Resolved Case | Case resolved within last 24 hours |
| **Community Volunteer** | 🔵 | Helper Location | Registered volunteers in area |
| **Historical Case** | ⚫ | Past Case | Resolved more than 24 hours ago |

</div>

---

## 🤝 **Contributing** 👥

<div align="center">

### **How to Contribute** 🔄
1. **Fork** the repository 🍴
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`) 🌿
3. **Commit** changes (`git commit -m 'Add amazing feature'`) 💾
4. **Push** to branch (`git push origin feature/amazing-feature`) 🚀
5. **Open** a Pull Request 📬

</div>

### **Code Style Guidelines** 📏
<div align="center">

| Guideline | Description | Example |
|-----------|-------------|---------|
| **Naming** | Use meaningful variable names | `userProfile` not `up` |
| **Comments** | Add comments for complex logic | `// Calculate distance using Haversine formula` |
| **Formatting** | Follow Dart/Flutter style guide | Use `dart format` |
| **Testing** | Write tests for new features | Add unit and widget tests |

</div>

---

## 📞 **Support** 🆘

### **Documentation** 📚
- 📖 **Flutter Documentation**: [flutter.dev/docs](https://flutter.dev/docs)
- 🔥 **Firebase Documentation**: [firebase.google.com/docs](https://firebase.google.com/docs)
- 🗺️ **Google Maps API**: [developers.google.com/maps](https://developers.google.com/maps)

### **Community** 👥
- 🐙 **GitHub Issues**: [Report Issues](https://github.com/ashrafaliqhtan/Missing_Persons_Platform/issues)
- 💬 **Discord Community**: [Join Chat](https://discord.gg/missingpersons)
- 🆘 **Stack Overflow**: [Ask Questions](https://stackoverflow.com/questions/tagged/missing-persons-platform)

---

<div align="center">

## **Contact Information** 📇

[![Email](https://img.shields.io/badge/Email-aq96650@gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:aq96650@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-ashrafaliqhtan-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ashrafaliqhtan)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ashraf_Ali_Qhtan-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ashraf-ali-qhtan-877954205)
[![Facebook](https://img.shields.io/badge/Facebook-Profile-1877F2?style=for-the-badge&logo=facebook&logoColor=white)](https://www.facebook.com/share/1WL9xwUsP6/)

</div>

---

## 📄 **License** ⚖️

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

## 🙏 **Acknowledgments** 🤝

### **Special Thanks To** 🏆

<table>
<tr>
<td align="center">
<a href="https://www.openstreetmap.org">
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQBDkwrm5ahQXFjxYOxz_WIp_CSzm7IRJI1xJx7z6qvBA&s=10" width="100" alt="OpenStreetMap">
<br>
<strong>🌍 OpenStreetMap</strong>
</a>
</td>
<td align="center">
<a href="https://firebase.google.com">
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZKrUjKc4YRQ-rDL7jV92w_OkQDg22iW0WFP6t9fCAjSA2vtKn_Qan3mwd&s=10" width="100" alt="Firebase">
<br>
<strong>🔥 Google Firebase</strong>
</a>
</td>
<td align="center">
<a href="https://flutter.dev">
<img src="https://storage.googleapis.com/cms-storage-bucket/4fd5520fe28ebf839174.svg" width="100" alt="Flutter">
<br>
<strong>📱 Flutter</strong>
</a>
</td>
</tr>
</table>

### **And to every emergency responder, volunteer, and contributor who makes this project possible.** ❤️

</div>

---

<div align="center">

## ⭐ **Support The Project** 🌟

If you find this project useful, please consider giving it a star! It helps more people discover **Missing_Persons_Platform**.

[![GitHub Stars](https://img.shields.io/github/stars/ashrafaliqhtan/Missing_Persons_Platform?style=social)](https://github.com/ashrafaliqhtan/Missing_Persons_Platform/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/ashrafaliqhtan/Missing_Persons_Platform?style=social)](https://github.com/ashrafaliqhtan/Missing_Persons_Platform/network/members)

### **Together, we can make communities safer.** 🛡️

---

**"Technology Serving Humanity"** 💙  
*Missing Persons Platform - Bringing Hope Home* 🏠

**Version 2.1.0** • **Last Updated: December 2024** • **Build: #MPP-2104**

</div>
