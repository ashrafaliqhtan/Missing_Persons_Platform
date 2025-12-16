// ignore_for_file: use_build_context_synchronously

/* IMPORTS */
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'p1_classifier.dart';
import 'p2_reportee_details.dart';
import 'p3_mp_info.dart';
import 'p4_mp_description.dart';
import 'p5_incident_details.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

/* SHARED PREFERENCE */
late SharedPreferences _prefs;
void clearPrefs() async {
  _prefs = await SharedPreferences.getInstance();
  _prefs.clear();
}

class Page6AuthConfirm extends StatefulWidget {
  final VoidCallback onReportSubmissionDone;
  const Page6AuthConfirm({super.key, required this.onReportSubmissionDone});

  @override
  State<Page6AuthConfirm> createState() => _Page6AuthConfirmState();
}

class _Page6AuthConfirmState extends State<Page6AuthConfirm> {
  // تم التعديل: جعل التقرير دائماً صالح للتقديم حتى مع الحقول الفارغة
  bool REPORT_ALWAYS_VALID = true;
  bool areImageUploading = false;
  // Firebase Realtime Database initialize
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference mainUsersRef = FirebaseDatabase.instance.ref("Main Users");
  DatabaseReference reportsRef = FirebaseDatabase.instance.ref("Reports");
  DatabaseReference reportsIMG = FirebaseDatabase.instance.ref("Report Images");
  late String? reportCount = '';
  late String? reporteeFirstName = '';
  late String? reporteeLastName = '';
  late String? reporteeMiddleName = '';
  late String? reporteeQualifiers = '';
  late String? reporteeBirthDate = '';
  late String? reporteeEmail = '';
  late String? reporteePhoneNumber = '';
  late String? reporteeSex = '';
  final user = FirebaseAuth.instance.currentUser;
  String userUID = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> prefsDict = {};
  Map<String, String> prefsImageDict = {};
  bool _isUploading = false;
  
  // تم التصحيح: تهيئة prefs كمتغير قابل للNULL ثم تهيئته في initState
  SharedPreferences? _prefsInstance;

  // ألوان مخصصة للمملكة العربية السعودية
  final Color _primaryColor = Color(0xFF006400); // أخضر داكن
  final Color _accentColor = Color(0xFFCE1126); // أحمر
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _borderColor = Color(0xFFDEE2E6);
  final Color _successColor = Color(0xFF28A745);
  final Color _warningColor = Color(0xFFFFC107);
  final Color _errorColor = Color(0xFFDC3545);

  // أحجام خطوط متجاوبة
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.065;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.04;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.035;
  
  // مسافات متجاوبة
  double get _verticalPadding => MediaQuery.of(context).size.height * 0.015;
  double get _horizontalPadding => MediaQuery.of(context).size.width * 0.045;

  // أنماط النص
  TextStyle get _titleStyle => TextStyle(
    fontSize: _titleFontSize,
    fontWeight: FontWeight.w700,
    color: _textColor,
    fontFamily: 'Tajawal',
  );

  TextStyle get _bodyStyle => TextStyle(
    fontSize: _bodyFontSize,
    fontWeight: FontWeight.w500,
    color: _textColor,
    fontFamily: 'Tajawal',
    height: 1.4,
  );

  TextStyle get _smallStyle => TextStyle(
    fontSize: _smallFontSize,
    fontWeight: FontWeight.w400,
    color: _hintColor,
    fontFamily: 'Tajawal',
    height: 1.3,
  );

  TextStyle get _headingStyle => TextStyle(
    fontSize: _bodyFontSize * 1.1,
    fontWeight: FontWeight.w600,
    color: _primaryColor,
    fontFamily: 'Tajawal',
  );

  TextStyle get _requiredStyle => TextStyle(
    fontSize: _bodyFontSize * 0.9,
    fontWeight: FontWeight.w500,
    color: _accentColor,
    fontFamily: 'Tajawal',
  );

  // authorization and confirmation texts
  final String _correctInfo =
      'أقر وأشهد بصحة المعلومات المذكورة أعلاه بناءً على علمي ومعرفتي';
  final String _Missing_Persons_Platform_upload =
      'أوافق على نشر معلومات وصورة الشخص المفقود/المغيب في صفحة "الأشخاص المفقودين بالقرب مني" في تطبيق Missing_Persons_Platform بعد التحقق من التقرير من قبل الجهات المختصة';
  final String _dataPrivacyConsent =
      'أوافق على معالجة بياناتي الشخصية وفقاً لنظام حماية البيانات الشخصية، وأقر بأن المعلومات المقدمة ستستخدم فقط لأغراض حالة الشخص المفقود/المغيب';

  final Uri URL_dataPrivacy = Uri.parse('https://www.my.gov.sa/wps/portal/snp/aboutksa/DataProtectionPolicy');

  // دالة أساسية للتشخيص والطباعة
  void _debugPrint(String message) {
    print('🔍 [P6_DEBUG] $message');
    // يمكنك أيضاً إضافة إرسال إلى خدمة تحليلات إذا أردت
  }

  // دالة لفحص حالة التطبيق بشكل كامل
  Future<void> _fullSystemDiagnostic() async {
    _debugPrint('=== بدء التشخيص الشامل للنظام ===');
    
    try {
      // 1. فحص SharedPreferences
      await _ensurePrefsInitialized();
      _debugPrint('✅ SharedPreferences: جاهز');
      _debugPrint('   - عدد المفاتيح: ${_prefsInstance!.getKeys().length}');
      
      // 2. فحص Firebase Auth
      if (user != null) {
        _debugPrint('✅ Firebase Auth: المستخدم مسجل - ${user!.uid}');
        _debugPrint('   - البريد الإلكتروني: ${user!.email}');
        _debugPrint('   - وقت التسجيل: ${user!.metadata.creationTime}');
      } else {
        _debugPrint('❌ Firebase Auth: لا يوجد مستخدم مسجل');
      }
      
      // 3. فحص Firebase Database
      try {
        DatabaseEvent connectedEvent = await FirebaseDatabase.instance.ref('.info/connected').once();
        bool isConnected = connectedEvent.snapshot.value == true;
        _debugPrint('✅ Firebase Database: ${isConnected ? "متصل" : "غير متصل"}');
        
        if (isConnected) {
          // فحص قاعدة البيانات الرئيسية
          DatabaseEvent userEvent = await mainUsersRef.child(userUID).once();
          _debugPrint('   - بيانات المستخدم في DB: ${userEvent.snapshot.exists}');
        }
      } catch (e) {
        _debugPrint('❌ Firebase Database: خطأ في الاتصال - $e');
      }
      
      // 4. فحص Firebase Storage
      try {
        // اختبار بسيط للوصول إلى Storage
        final storageRef = FirebaseStorage.instance.ref();
        _debugPrint('✅ Firebase Storage: جاهز');
      } catch (e) {
        _debugPrint('❌ Firebase Storage: خطأ - $e');
      }
      
      // 5. فحص البيانات الأساسية
      _debugPrint('📊 البيانات الأساسية:');
      _debugPrint('   - reportCount: $reportCount');
      _debugPrint('   - userUID: $userUID');
      _debugPrint('   - reporteeFirstName: $reporteeFirstName');
      _debugPrint('   - reporteeLastName: $reporteeLastName');
      
      // 6. فحص الـ widgets
      _debugPrint('🎯 حالة الـ Widget:');
      _debugPrint('   - mounted: $mounted');
      _debugPrint('   - context: ${context.size}');
      
      // 7. فحص بيانات التقرير
      _debugPrint('📝 بيانات التقرير:');
      _debugPrint('   - عدد الحقول النصية: ${prefsDict.length}');
      _debugPrint('   - عدد الحقول المصورة: ${prefsImageDict.length}');
      
      // 8. فحص الحقول الحرجة
      List<String> criticalFields = [
        'p3_mp_firstName',
        'p3_mp_lastName', 
        'p2_relationshipToMP',
        'p5_lastSeenDate',
        'p5_lastSeenLoc'
      ];
      
      for (String field in criticalFields) {
        bool exists = prefsDict.containsKey(field) && 
                     prefsDict[field] != null && 
                     prefsDict[field].toString().isNotEmpty;
        _debugPrint('   - $field: ${exists ? "✅" : "❌"}');
      }
      
    } catch (e) {
      _debugPrint('💥 خطأ في التشخيص: $e');
      _debugPrint('   - StackTrace: ${e.toString()}');
    }
    
    _debugPrint('=== نهاية التشخيص الشامل ===');
  }

  // دالة مبسطة لفحص البيانات السريع
  Future<void> _quickDataCheck() async {
    _debugPrint('⚡ فحص سريع للبيانات');
    
    try {
      // فحص وجود بيانات أساسية
      List<String> criticalFields = [
        'p3_mp_firstName',
        'p3_mp_lastName', 
        'p2_relationshipToMP',
        'p5_lastSeenDate',
        'p5_lastSeenLoc'
      ];
      
      int foundCount = 0;
      for (String field in criticalFields) {
        bool exists = prefsDict.containsKey(field) && 
                     prefsDict[field] != null && 
                     prefsDict[field].toString().isNotEmpty;
        if (exists) foundCount++;
        _debugPrint('   - $field: ${exists ? "✅" : "❌"}');
      }
      
      _debugPrint('   - إجمالي الحقول: ${prefsDict.length}');
      _debugPrint('   - الحقول المطلوبة الموجودة: $foundCount/${criticalFields.length}');
      
      if (foundCount >= 3) {
        _debugPrint('🎯 البيانات كافية للتقديم');
      } else {
        _debugPrint('⚠️  البيانات غير كافية - تحتاج ${3 - foundCount} حقول إضافية');
      }
      
    } catch (e) {
      _debugPrint('💥 خطأ في الفحص السريع: $e');
    }
  }

  Future<void> _launchURL_dataPrivacy() async {
    if (!await launchUrl(URL_dataPrivacy)) {
      throw 'Could not launch $URL_dataPrivacy';
    }
  }

  // store user signature as Uint8List
  Uint8List? signaturePhoto;

  // save user signature to shared preferences
  Future<void> _saveSignature() async {
    _debugPrint('💾 بدء حفظ التوقيع');
    XFile? imageFile;
    if (signaturePhoto != null) {
      imageFile = XFile.fromData(signaturePhoto!);
      try {
        final bytes = await imageFile.readAsBytes();
        final file =
            File('${(await getTemporaryDirectory()).path}/image_signature.png');
        await file.writeAsBytes(bytes);
        setState(() {
          _prefsInstance!.setString('p6_reporteeSignature_PATH', file.path);
        });
        _debugPrint('✅ تم حفظ التوقيع في: ${file.path}');
      } catch (e) {
        _debugPrint('❌ خطأ في حفظ التوقيع: $e');
      }

      String signaturePhotoString = base64Encode(signaturePhoto!);
      _prefsInstance!.setString('p6_reporteeSignature', signaturePhotoString);
      _debugPrint('✅ تم حفظ التوقيع في SharedPreferences');
    } else {
      _debugPrint('⚠️  لا يوجد توقيع لحفظه');
    }
  }

  // load user signature from shared preferences
  Future<void> _loadSignature() async {
    _debugPrint('📥 بدء تحميل التوقيع');
    await _ensurePrefsInitialized();
    if (_prefsInstance!.getString('p6_reporteeSignature') != null) {
      String signaturePhotoString = _prefsInstance!.getString('p6_reporteeSignature')!;
      signaturePhoto = base64Decode(signaturePhotoString);
      _debugPrint('✅ تم تحميل التوقيع بنجاح');
    } else {
      _debugPrint('⚠️  لا يوجد توقيع محفوظ');
    }
  }

  // دالة مساعدة للتأكد من تهيئة SharedPreferences
  Future<void> _ensurePrefsInitialized() async {
    if (_prefsInstance == null) {
      _prefsInstance = await SharedPreferences.getInstance();
      _debugPrint('🔧 تم تهيئة SharedPreferences');
    }
  }

  // دالة محسنة لرفع الصور مع التعامل مع الحقول الفارغة
  Future<void> uploadImages() async {
    _debugPrint('🖼️  بدء رفع الصور');
    await _ensurePrefsInitialized();
    
    // قائمة بجميع مسارات الصور المحتملة
    List<Map<String, String>> imageConfigs = [
      {'key': 'p6_reporteeSignature_PATH', 'name': 'reportee_Signature'},
      {'key': 'p2_reporteeSelfie_PATH', 'name': 'reportee_Selfie'},
      {'key': 'p2_reportee_ID_Photo_PATH', 'name': 'reportee_ID_Photo'},
      {'key': 'p4_mp_recent_photo_PATH', 'name': 'mp_recentPhoto'},
      {'key': 'p4_mp_dental_record_photo_PATH', 'name': 'mp_dentalRecord'},
      {'key': 'p4_mp_finger_print_record_photo_PATH', 'name': 'mp_fingerPrintRecord'},
      {'key': 'p5_locSnapshot_PATH', 'name': 'mp_locationSnapshot'},
    ];

    int successCount = 0;
    int failCount = 0;

    for (var config in imageConfigs) {
      String imageKey = config['key']!;
      String namePath = config['name']!;
      
      _debugPrint('معالجة الصورة: $imageKey');
      
      String? filePath = _prefsInstance!.getString(imageKey);
      
      if (filePath == null || filePath.isEmpty) {
        _debugPrint('⚠️  لا توجد صورة لـ: $imageKey');
        _prefsInstance!.setString('${namePath}_LINK', '');
        failCount++;
        continue;
      }

      try {
        final file = File(filePath);
        
        if (!await file.exists()) {
          _debugPrint('⚠️  الملف غير موجود: $filePath');
          _prefsInstance!.setString('${namePath}_LINK', 'file_not_found');
          failCount++;
          continue;
        }

        // التحقق من حجم الملف
        final fileStat = await file.stat();
        if (fileStat.size > 10 * 1024 * 1024) { // 10MB limit
          _debugPrint('⚠️  حجم الملف كبير جداً: ${fileStat.size} bytes');
          _prefsInstance!.setString('${namePath}_LINK', 'file_too_large');
          failCount++;
          continue;
        }

        _debugPrint('جاري رفع: $imageKey');
        
        // رفع الملف إلى Firebase Storage
        final task = FirebaseStorage.instance
            .ref()
            .child('Reports')
            .child(userUID)
            .child('report_$reportCount')
            .child(namePath)
            .putFile(file);

        // متابعة تقدم الرفع
        task.snapshotEvents.listen((snapshot) {
          double progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          _debugPrint('   تقدم رفع $namePath: ${progress.toStringAsFixed(1)}%');
        });

        await task.whenComplete(() async {
          String downloadURL = await task.snapshot.ref.getDownloadURL();
          await _prefsInstance!.setString('${namePath}_LINK', downloadURL);
          _debugPrint('✅ تم رفع $namePath بنجاح');
          _debugPrint('   الرابط: $downloadURL');
          successCount++;
        });

      } catch (e) {
        _debugPrint('❌ خطأ في رفع $imageKey: $e');
        _prefsInstance!.setString('${namePath}_LINK', 'upload_error: ${e.toString()}');
        failCount++;
      }
      
      // تأخير بسيط بين كل رفع لتجنب الحمل الزائد
      await Future.delayed(Duration(milliseconds: 500));
    }

    _debugPrint('نتيجة رفع الصور: $successCount نجاح, $failCount فشل');
  }

  // getSignature Future function
  Future<void> _getSignature(image) async {
    _debugPrint('🎨 بدء تحويل التوقيع إلى صورة');
    final data = await image.toByteData(format: ImageByteFormat.png);
    final imageBytes = await data!.buffer.asUint8List();
    setState(() {
      signaturePhoto = imageBytes;
    });
    _debugPrint('✅ تم تحويل التوقيع إلى صورة');
    await _saveSignature();
  }

  // initialize shared preferences
  @override
  void initState() {
    super.initState();
    _debugPrint('🚀 initState - بدء تهيئة الشاشة السادسة');
    
    // تشغيل التهيئة بعد تأخير بسيط لضمان اكتمال بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugPrint('🎯 PostFrameCallback - اكتمل بناء الواجهة');
      _initializeApp();
    });
  }

  // دالة التهيئة الرئيسية
  Future<void> _initializeApp() async {
    _debugPrint('🔧 بدء التهيئة الرئيسية للتطبيق');
    
    try {
      // 1. تشخيص النظام أولاً
      await _fullSystemDiagnostic();
      
      // 2. تهيئة SharedPreferences
      await _ensurePrefsInitialized();
      _debugPrint('✅ تم تهيئة SharedPreferences');
      
      // 3. تحميل التوقيع
      await _loadSignature();
      _debugPrint('✅ تم تحميل التوقيع');
      
      // 4. تحميل بيانات التقرير
      await retrievePrefsData();
      _debugPrint('✅ تم تحميل بيانات التقرير');
      
      // 5. تحميل بيانات المستخدم
      await retrieveUserData();
      _debugPrint('✅ تم تحميل بيانات المستخدم');
      
      // 6. فحص سريع للبيانات
      await _quickDataCheck();
      
      _debugPrint('🎉 اكتملت التهيئة بنجاح');
      
    } catch (e) {
      _debugPrint('💥 فشل في التهيئة: $e');
      _showErrorSnackbar('خطأ في تحميل البيانات: ${e.toString()}');
    }
  }

  // دالة لعرض رسائل الخطأ
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _errorColor,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // دالة لعرض رسائل النجاح
  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _successColor,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // دالة لفحص صلاحيات المستخدم
  Future<bool> _checkUserPermissions() async {
    _debugPrint('🔐 فحص صلاحيات المستخدم');
    try {
      DatabaseEvent event = await mainUsersRef.child(user!.uid).once();
      bool exists = event.snapshot.exists;
      _debugPrint('   صلاحيات المستخدم: ${exists ? "✅" : "❌"}');
      return exists;
    } catch (e) {
      _debugPrint('❌ فشل في التحقق من صلاحيات المستخدم: $e');
      return false;
    }
  }

  // دالة لفحص اتصال Firebase
  Future<bool> _checkFirebaseConnection() async {
    _debugPrint('🌐 فحص اتصال Firebase');
    try {
      DatabaseEvent event = await FirebaseDatabase.instance.ref('.info/connected').once()
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('انتهت مهلة الاتصال');
      });
      bool isConnected = event.snapshot.value == true;
      _debugPrint('   اتصال Firebase: ${isConnected ? "✅" : "❌"}');
      return isConnected;
    } catch (e) {
      _debugPrint('❌ فشل في الاتصال بـ Firebase: $e');
      return false;
    }
  }

  // دالة لاسترجاع بيانات المستخدم
  Future<void> retrieveUserData() async {
    _debugPrint('👤 بدء استرجاع بيانات المستخدم');
    await _ensurePrefsInitialized();
    try {
      DatabaseEvent event = await mainUsersRef.child(user!.uid).once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> userDict = event.snapshot.value as Map<dynamic, dynamic>;
        _debugPrint('✅ تم العثور على بيانات المستخدم');
        reportCount = userDict['reportCount']?.toString() ?? '0';
        reporteeFirstName = userDict['firstName']?.toString() ?? '';
        reporteeLastName = userDict['lastName']?.toString() ?? '';
        reporteeMiddleName = userDict['middleName']?.toString() ?? '';
        reporteePhoneNumber = userDict['phoneNumber']?.toString() ?? '';
        reporteeQualifiers = userDict['qualifiers']?.toString() ?? '';
        reporteeEmail = userDict['email']?.toString() ?? '';
        reporteeBirthDate = userDict['birthDate']?.toString() ?? '';
        reporteeSex = userDict['sex']?.toString() ?? '';
        
        _debugPrint('   - reportCount: $reportCount');
        _debugPrint('   - الاسم: $reporteeFirstName $reporteeLastName');
      } else {
        _debugPrint('⚠️  لا توجد بيانات للمستخدم');
        reportCount = '0';
      }
    } catch (e) {
      _debugPrint('❌ خطأ في استرجاع بيانات المستخدم: $e');
      reportCount = '0';
    }
    _debugPrint('[REPORT COUNT] عدد التقارير: $reportCount');
  }

  // دالة محسنة لاسترجاع البيانات مع التعامل مع الحقول الفارغة
  Future<void> retrievePrefsData() async {
    _debugPrint('📥 بدء استرجاع بيانات التقرير');
    await _ensurePrefsInitialized();
    
    // تهيئة جميع الحقول المطلوبة بقيم افتراضية إذا كانت فارغة
    await _initializeAllFields();
    
    List<String> keyList = _prefsInstance!.getKeys().toList();
    List<String> imagesList = [
      'p2_reportee_ID_Photo',
      'p2_reporteeSelfie',
      'p4_mp_recent_photo',
      'p5_locSnapshot',
      'p6_reporteeSignature',
      'p4_mp_dental_record_photo',
      'p4_mp_finger_print_record_photo',
    ];

    _debugPrint('[keylist in retrieve] ${keyList.length} مفاتيح');

    // تنظيف القواميس قبل التعبئة
    prefsDict.clear();
    prefsImageDict.clear();

    for (String key in keyList) {
      if (imagesList.contains(key)) {
        String? valueImg = _prefsInstance!.getString(key);
        if (valueImg != null && valueImg.isNotEmpty) {
          prefsImageDict[key] = valueImg;
        } else {
          prefsImageDict[key] = ''; // حفظ قيمة فارغة للمفاتيح الفارغة
        }
      } else {
        try {
          String? value = _prefsInstance!.getString(key);
          if (value != null) {
            prefsDict[key] = value;
          } else {
            // محاولة الحصول على قيمة منطقية إذا لم تكن نصية
            bool? boolValue = _prefsInstance!.getBool(key);
            if (boolValue != null) {
              prefsDict[key] = boolValue;
            } else {
              prefsDict[key] = ''; // حفظ قيمة فارغة للحقول النصية الفارغة
            }
          }
        } catch (e) {
          _debugPrint('⚠️  خطأ في قراءة المفتاح $key: $e');
          prefsDict[key] = ''; // قيمة افتراضية في حالة الخطأ
        }
      }
    }

    _debugPrint('✅ تم تحميل ${prefsDict.length} حقل نصي');
    _debugPrint('✅ تم تحميل ${prefsImageDict.length} حقل صورة');
  }

  // دالة جديدة لتهيئة جميع الحقول المطلوبة
  Future<void> _initializeAllFields() async {
    _debugPrint('🔧 بدء تهيئة الحقول المطلوبة');
    await _ensurePrefsInitialized();
    
    // قائمة بجميع المفاتيح المطلوبة في التقرير
    List<String> allRequiredKeys = [
      // الصفحة 1
      'p1_reportType',
      'p1_reportCategory',
      
      // الصفحة 2
      'p2_citizenship',
      'p2_civil_status',
      'p2_region',
      'p2_province', 
      'p2_townCity',
      'p2_barangay',
      'p2_streetHouseNum',
      'p2_reportee_ID_Photo',
      'p2_relationshipToMP',
      'p2_reporteeSelfie',
      'p2_homePhone',
      'p2_mobilePhone',
      'p2_email',
      
      // الصفحة 3
      'p3_mp_lastName',
      'p3_mp_firstName', 
      'p3_mp_civilStatus',
      'p3_mp_sex',
      'p3_mp_birthDate',
      'p3_mp_age',
      'p3_mp_nationalityEthnicity',
      'p3_mp_citizenship',
      'p3_mp_address_region',
      'p3_mp_address_province',
      'p3_mp_address_city',
      'p3_mp_address_barangay',
      'p3_mp_address_streetHouseNum',
      'p3_mp_contact_homePhone',
      'p3_mp_contact_mobilePhone',
      'p3_mp_contact_email',
      
      // الصفحة 4
      'p4_mp_scars',
      'p4_mp_marks',
      'p4_mp_tattoos', 
      'p4_mp_hair_color',
      'p4_mp_eye_color',
      'p4_mp_prosthetics',
      'p4_mp_birth_defects',
      'p4_mp_last_clothing',
      'p4_mp_height_feet',
      'p4_mp_height_inches', 
      'p4_mp_weight',
      'p4_mp_blood_type',
      'p4_mp_medications',
      'p4_mp_socmed_facebook_username',
      'p4_mp_socmed_twitter_username',
      'p4_mp_socmed_instagram_username',
      'p4_mp_recent_photo',
      'p4_mp_dental_record_photo',
      'p4_mp_finger_print_record_photo',
      
      // الصفحة 5
      'p5_reportDate',
      'p5_lastSeenDate',
      'p5_lastSeenTime', 
      'p5_lastSeenLoc',
      'p5_incidentDetails',
      'p5_locSnapshot',
      
      // الصفحة 6
      'p6_reporteeSignature',
      
      // الحقول الإضافية
      'pnp_rejectReason',
      'pnp_dateFound',
      'pnp_contactNumber',
      'pnp_contactEmail',
    ];

    int initializedCount = 0;
    for (String key in allRequiredKeys) {
      if (!_prefsInstance!.containsKey(key)) {
        // إذا لم يكن المفتاح موجوداً، نقوم بتهيئته بقيمة فارغة
        await _prefsInstance!.setString(key, '');
        initializedCount++;
      }
    }

    _debugPrint('✅ تم تهيئة $initializedCount حقل فارغ');
  }

  void popAndShowSnackbar(context) {
    _debugPrint('🎊 عرض رسالة النجاح');
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تقديم التقرير بنجاح!',
          style: _bodyStyle.copyWith(color: Colors.white),
        ),
        backgroundColor: _successColor,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // دالة مساعدة لبناء قسم
  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.5),
      padding: EdgeInsets.all(_horizontalPadding * 0.8),
      decoration: BoxDecoration(
        color: backgroundColor ?? _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.05),
          ),
          SizedBox(height: _verticalPadding * 0.5),
          ...children,
        ],
      ),
    );
  }

  // دالة مساعدة لبناء زر
  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPrimary = true,
    bool isEnabled = true,
    double? width,
    Color? backgroundColor,
    bool isLoading = false,
  }) {
    return Container(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? (isPrimary ? _primaryColor : _cardColor),
          foregroundColor: isPrimary ? Colors.white : _primaryColor,
          padding: EdgeInsets.symmetric(vertical: _verticalPadding * 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary ? BorderSide.none : BorderSide(color: _primaryColor),
          ),
          elevation: 2,
        ),
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.white : _primaryColor,
                  ),
                ),
              )
            : Text(
                text,
                style: _bodyStyle.copyWith(
                  color: isPrimary ? Colors.white : _primaryColor,
                  fontSize: _bodyFontSize * 0.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // دالة مساعدة لبناء بطاقة معلومات
  Widget _buildInfoCard(String message, {Color? backgroundColor, Color? textColor}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: backgroundColor ?? _accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: _bodyFontSize * 1.2, color: textColor ?? _accentColor),
          SizedBox(width: _horizontalPadding * 0.4),
          Expanded(
            child: Text(
              message,
              style: _smallStyle.copyWith(
                color: textColor ?? _accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة محسنة لفحص وتصحيح المفاتيح في SharedPreferences
  Future<void> _debugPrefs() async {
    _debugPrint('🔍 فحص SharedPreferences');
    await _ensurePrefsInitialized();
    List<String> keys = _prefsInstance!.getKeys().toList();
    
    _debugPrint('عدد المفاتيح: ${keys.length}');
    
    // فحص القيم الفارغة أو غير الصالحة
    int emptyCount = 0;
    int validCount = 0;
    
    for (String key in keys) {
      String? value = _prefsInstance!.getString(key);
      if (value == null || value.isEmpty) {
        _debugPrint('⚠️  المفتاح "$key" به قيمة فارغة');
        emptyCount++;
      } else {
        _debugPrint('✅ المفتاح "$key": ${value.length} حرف');
        validCount++;
      }
    }
    
    _debugPrint('النتيجة: $validCount مفاتيح صالحة، $emptyCount مفاتيح فارغة');
  }

  List<String> dialogMessage = [];

  // تم التعديل: دالة دائماً تعيد true لتسمح بحفظ التقرير حتى مع الحقول الفارغة
  bool checkReportValidity(bool removeReportValidtyCheck) {
    _debugPrint('✅ فحص اكتمال التقرير - التقرير مقبول دائماً');
    return true;
  }

  String formErrorMessage() {
    return 'التقرير جاهز للتقديم';
  }

  // دالة مساعدة لبناء عنصر اتفاقية
  Widget _buildAgreementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: _successColor,
          size: _bodyFontSize * 1.1,
        ),
        SizedBox(width: _horizontalPadding * 0.4),
        Expanded(
          child: Text(
            text,
            style: _bodyStyle.copyWith(
              fontSize: _bodyFontSize * 0.9,
            ),
          ),
        ),
      ],
    );
  }

  // دالة مساعدة لبناء عنصر اتفاقية مع رابط
  Widget _buildAgreementItemWithLink(String text, String linkText, Function onTap) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: _successColor,
          size: _bodyFontSize * 1.1,
        ),
        SizedBox(width: _horizontalPadding * 0.4),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: text,
                  style: _bodyStyle.copyWith(
                    fontSize: _bodyFontSize * 0.9,
                    color: _textColor,
                  ),
                ),
                TextSpan(
                  text: linkText,
                  style: _bodyStyle.copyWith(
                    fontSize: _bodyFontSize * 0.9,
                    color: _primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onTap as void Function()?,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // دالة مساعدة للتحقق من الحد الأدنى للبيانات المطلوبة
  bool _hasMinimumRequiredData(Map<String, dynamic> data) {
    _debugPrint('🔍 التحقق من الحد الأدنى للبيانات');
    
    // قائمة بالحقول الأساسية التي يجب أن تكون موجودة
    List<String> requiredFields = [
      'p3_mp_firstName',
      'p3_mp_lastName', 
      'p2_relationshipToMP',
      'p5_lastSeenDate',
      'p5_lastSeenLoc'
    ];

    int foundFields = 0;
    List<String> missingFields = [];
    
    for (String field in requiredFields) {
      if (data.containsKey(field) && 
          data[field] != null && 
          data[field].toString().isNotEmpty) {
        foundFields++;
      } else {
        missingFields.add(field);
      }
    }

    _debugPrint('   - الحقول المطلوبة: ${requiredFields.length}');
    _debugPrint('   - الحقول الموجودة: $foundFields');
    _debugPrint('   - الحقول المفقودة: $missingFields');
    
    // نطلب وجود 3 على الأقل من الحقول المطلوبة
    bool isValid = foundFields >= 3;
    
    if (!isValid) {
      _debugPrint('❌ البيانات غير كافية. الحقول المفقودة: $missingFields');
    } else {
      _debugPrint('✅ البيانات كافية للمتابعة');
    }
    
    return isValid;
  }

  // دالة للحصول على رسالة خطأ مفهومة للمستخدم
  String _getUserFriendlyErrorMessage(dynamic error) {
    _debugPrint('💬 تحويل الخطأ إلى رسالة مفهومة');
    String errorString = error.toString();
    
    if (errorString.contains('انتهت المهلة')) {
      return 'انتهت المهلة في الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية لتقديم التقارير. يرجى التواصل مع الدعم.';
        case 'network-error':
          return 'فشل في الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.';
        default:
          return 'حدث خطأ في الخادم: ${error.message}';
      }
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else {
      return 'عذراً، حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  // دالة مساعدة لتنظيف البيانات المحلية بعد النجاح
  Future<void> _clearLocalDataAfterSuccess() async {
    _debugPrint('🧹 بدء تنظيف البيانات المحلية');
    try {
      await _ensurePrefsInitialized();
      
      // قائمة بجميع المفاتيح التي نريد حذفها
      List<String> keysToRemove = _prefsInstance!.getKeys().where((key) => 
        key.startsWith('p1_') || 
        key.startsWith('p2_') || 
        key.startsWith('p3_') || 
        key.startsWith('p4_') || 
        key.startsWith('p5_') || 
        key.startsWith('p6_') ||
        key.endsWith('_LINK') ||
        key.endsWith('_PATH')
      ).toList();

      for (String key in keysToRemove) {
        await _prefsInstance!.remove(key);
      }
      
      _debugPrint('✅ تم تنظيف ${keysToRemove.length} مفتاح محلي');
    } catch (e) {
      _debugPrint('⚠️  فشل في تنظيف البيانات المحلية: $e');
    }
  }

  // دالة لتشخيص الأخطاء بالتفصيل
  Future<void> _diagnoseError(dynamic error) async {
    _debugPrint('🔧 === تشخيص الخطأ ===');
    
    if (error is FirebaseException) {
      _debugPrint('🔥 خطأ Firebase:');
      _debugPrint('   - الكود: ${error.code}');
      _debugPrint('   - الرسالة: ${error.message}');
      _debugPrint('   - التفاصيل: ${error.stackTrace}');
      
      switch (error.code) {
        case 'permission-denied':
          _debugPrint('   📝 السبب: عدم وجود صلاحيات للكتابة في قاعدة البيانات');
          _debugPrint('   💡 الحل: تحقق من قواعد الأمان في Firebase Console');
          break;
        case 'disconnected':
          _debugPrint('   📝 السبب: فقدان الاتصال بالإنترنت');
          _debugPrint('   💡 الحل: تحقق من اتصال الإنترنت');
          break;
        case 'network-error':
          _debugPrint('   📝 السبب: خطأ في الشبكة');
          _debugPrint('   💡 الحل: حاول مرة أخرى لاحقاً');
          break;
        default:
          _debugPrint('   📝 السبب: خطأ غير معروف في Firebase');
          _debugPrint('   💡 الحل: تحقق من تكوين Firebase');
      }
    } else if (error is Exception) {
      _debugPrint('⚠️  خطأ تطبيق: ${error.toString()}');
    } else {
      _debugPrint('❓ خطأ غير معروف: $error');
    }
    
    // فحص حالة الاتصال
    try {
      bool isConnected = await _checkFirebaseConnection();
      _debugPrint('📡 حالة الاتصال: ${isConnected ? "متصل" : "غير متصل"}');
    } catch (e) {
      _debugPrint('📡 فشل في فحص الاتصال: $e');
    }
    
    _debugPrint('🔧 === نهاية التشخيص ===');
  }

  // دالة لاختبار الحفظ البسيط
  Future<void> _testSimpleSave() async {
    _debugPrint('🧪 بدء اختبار الحفظ البسيط');
    
    try {
      // 1. التحقق من المستخدم
      if (user == null) {
        _debugPrint('❌ لا يوجد مستخدم مسجل');
        _showErrorSnackbar('يجب تسجيل الدخول أولاً');
        return;
      }

      // 2. إنشاء بيانات اختبار بسيطة
      Map<String, dynamic> testData = {
        'test_name': 'تقرير اختبار',
        'test_date': DateTime.now().toIso8601String(),
        'test_number': 12345,
        'user_id': userUID,
      };

      _debugPrint('📝 بيانات الاختبار: $testData');

      // 3. محاولة الحفظ في Firebase
      _debugPrint('💾 محاولة الحفظ في Firebase...');
      
      await reportsRef.child(userUID).child('test_report').set(testData)
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('انتهت مهلة الاختبار');
      });

      _debugPrint('✅ نجح اختبار الحفظ!');
      _showSuccessSnackbar('نجح اختبار الحفظ! يمكنك متابعة التقرير');

      // 4. تنظيف بيانات الاختبار
      await reportsRef.child(userUID).child('test_report').remove();
      _debugPrint('🧹 تم تنظيف بيانات الاختبار');

    } catch (e) {
      _debugPrint('❌ فشل اختبار الحفظ: $e');
      _showErrorSnackbar('فشل اختبار الحفظ: ${e.toString()}');
    }
  }

  // دالة محسنة تماماً لتقديم التقرير مع تشخيص شامل للأخطاء
  Future<void> submitReport() async {
    _debugPrint('🚀 === بدء عملية تقديم التقرير ===');
    await _ensurePrefsInitialized();
    
    setState(() {
      areImageUploading = true;
    });

    try {
      // تشخيص البيانات قبل البدء
      await _fullSystemDiagnostic();
      
      // 1. التحقق من البيانات الأساسية
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      if (reportCount == null || reportCount!.isEmpty) {
        throw Exception('رقم التقرير غير متوفر أو غير صالح');
      }

      // 2. التحقق من صلاحيات المستخدم
      bool hasPermission = await _checkUserPermissions();
      if (!hasPermission) {
        throw Exception('ليس لديك صلاحية لتقديم التقارير. يرجى التواصل مع الدعم.');
      }

      String reportChildName = "report_${reportCount!}";
      _debugPrint('📋 اسم التقرير: $reportChildName');
      
      // 3. إعداد البيانات الأساسية
      Map<String, dynamic> reportData = Map.from(prefsDict);
      
      // إضافة الحقول الأساسية مع قيم افتراضية
      reportData['status'] = 'Pending';
      reportData['reportee_firstName'] = reporteeFirstName ?? 'غير معروف';
      reportData['reportee_lastName'] = reporteeLastName ?? 'غير معروف';
      reportData['reportee_middleName'] = reporteeMiddleName ?? '';
      reportData['reportee_phoneNumber'] = reporteePhoneNumber ?? '';
      reportData['reportee_email'] = reporteeEmail ?? '';
      reportData['reportee_birthDate'] = reporteeBirthDate ?? '';
      reportData['reportee_sex'] = reporteeSex ?? '';
      reportData['reportee_qualifiers'] = reporteeQualifiers ?? '';
      reportData['submission_date'] = DateTime.now().toIso8601String();
      reportData['report_id'] = reportChildName;
      reportData['user_uid'] = userUID;
      reportData['created_at'] = ServerValue.timestamp;
      
      // 4. تنظيف البيانات - إزالة الحقول الفارغة أو غير الصالحة
      reportData.removeWhere((key, value) {
        if (value == null) return true;
        if (value is String && value.isEmpty) return true;
        if (value.toString() == 'null') return true;
        return false;
      });

      _debugPrint('🧹 عدد الحقول بعد التنظيف: ${reportData.length}');
      
      // 5. التحقق من الحد الأدنى للبيانات المطلوبة
      if (!_hasMinimumRequiredData(reportData)) {
        throw Exception('البيانات غير كافية لتقديم التقرير. يرجى تعبئة الحقول الأساسية.');
      }

      // 6. رفع الصور (بشكل اختياري - لا توقف العملية إذا فشلت)
      try {
        _debugPrint('🖼️  بدء رفع الصور...');
        await uploadImages();
        _debugPrint('✅ تم رفع الصور بنجاح');
      } catch (e) {
        _debugPrint('⚠️  تحذير: فشل في رفع بعض الصور: $e');
        // نستمر في العملية حتى لو فشل رفع الصور
      }

      // 7. تحديث البيانات بعد رفع الصور
      await retrievePrefsData();
      
      // 8. إضافة روابط الصور إلى البيانات
      List<String> imageLinks = [
        'reportee_Selfie_LINK',
        'reportee_ID_Photo_LINK', 
        'mp_recentPhoto_LINK',
        'mp_dentalRecord_LINK',
        'mp_fingerPrintRecord_LINK',
        'mp_locationSnapshot_LINK',
        'reportee_Signature_LINK'
      ];

      for (String linkKey in imageLinks) {
        String? link = _prefsInstance!.getString(linkKey);
        if (link != null && link.isNotEmpty && link != 'file_not_found') {
          reportData[linkKey] = link;
        }
      }

      // 9. حفظ التقرير في Firebase
      _debugPrint('💾 جاري حفظ التقرير في قاعدة البيانات...');
      
      try {
        // اختبار الكتابة أولاً
        await reportsRef.child(userUID).child('test_write').set({'test': DateTime.now().toIso8601String()})
            .timeout(Duration(seconds: 10), onTimeout: () {
          throw Exception('انتهت المهلة في اختبار الكتابة');
        });
        
        // حذف الاختبار
        await reportsRef.child(userUID).child('test_write').remove();
        
        _debugPrint('✅ اختبار الكتابة ناجح');
      } catch (e) {
        _debugPrint('❌ فشل اختبار الكتابة: $e');
        throw Exception('فشل في الاتصال بقاعدة البيانات: $e');
      }

      // حفظ التقرير الفعلي
      await reportsRef.child(userUID).child(reportChildName).set(reportData)
          .timeout(Duration(seconds: 30), onTimeout: () {
        throw Exception('انتهت المهلة في حفظ التقرير');
      });

      _debugPrint('✅ تم حفظ التقرير في Firebase');

      // 10. تحديث عداد التقارير
      _debugPrint('🔢 جاري تحديث عداد التقارير...');
      int reportsRefInt = int.tryParse(reportCount!) ?? 0;
      reportsRefInt += 1;
      
      await mainUsersRef.child(userUID).update({
        'reportCount': reportsRefInt.toString(),
        'lastReportDate': DateTime.now().toIso8601String(),
      }).timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('انتهت المهلة في تحديث العداد');
      });

      _debugPrint('🎉 === تم تقديم التقرير بنجاح! ===');
      _debugPrint('📊 رقم التقرير: $reportCount');
      _debugPrint('📝 عدد الحقول المحفوظة: ${reportData.length}');
      _debugPrint('👤 معرف المستخدم: $userUID');

      // 11. تنظيف البيانات المحلية بعد النجاح
      await _clearLocalDataAfterSuccess();

      // 12. إشعار النجاح
      widget.onReportSubmissionDone();

    } catch (e) {
      _debugPrint('💥 === فشل في تقديم التقرير ===');
      _debugPrint('❌ الخطأ: $e');
      _debugPrint('🔍 نوع الخطأ: ${e.runtimeType}');
      
      // تشخيص مفصل للخطأ
      await _diagnoseError(e);
      
      // تحليل نوع الخطأ لعرض رسالة مناسبة
      String errorMessage = _getUserFriendlyErrorMessage(e);
      
      // إعادة رمي الخطأ مع رسالة واضحة
      throw Exception(errorMessage);
    } finally {
      setState(() {
        areImageUploading = false;
      });
    }
  }

  // دالة لعرض dialog التأكيد
  void _showConfirmationDialog() {
    _debugPrint('💬 عرض نافذة التأكيد');
    
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'تأكيد التقديم',
            style: _headingStyle,
            textAlign: TextAlign.center,
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في تقديم هذا التقرير؟\n\nملاحظة: يمكن تقديم التقرير حتى مع وجود بعض الحقول فارغة.',
            style: _bodyStyle,
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(left: 10, right: 20),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: areImageUploading
                              ? null
                              : () {
                                  _debugPrint('❌ تم إلغاء التقديم');
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            'إلغاء',
                            style: _bodyStyle.copyWith(
                              color: _hintColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: _horizontalPadding * 0.3),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: areImageUploading
                              ? null
                              : () async {
                                  _debugPrint('✅ تم تأكيد التقديم');
                                  setState(() {
                                    areImageUploading = true;
                                  });
                                  try {
                                    await submitReport().then((value) =>
                                        popAndShowSnackbar(context));
                                  } catch (e) {
                                    _debugPrint('💥 خطأ في التقديم: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: _errorColor,
                                          content: Text(
                                            'عذراً، حدث خطأ أثناء تقديم التقرير. يرجى المحاولة مرة أخرى.',
                                            style: _bodyStyle.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    setState(() {
                                      areImageUploading = false;
                                    });
                                  }
                                },
                          child: areImageUploading
                              ? SizedBox(
                                  height: 24.0,
                                  width: 50.0,
                                  child: SpinKitThreeBounce(
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'تأكيد',
                                  style: _bodyStyle.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<SfSignaturePadState> signaturePadKey = GlobalKey();
    _debugPrint('🎨 بناء واجهة الشاشة السادسة');

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header ثابت
            Container(
              padding: EdgeInsets.all(_horizontalPadding * 0.8),
              decoration: BoxDecoration(
                color: _cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Indicator
                  Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.83,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: _verticalPadding),
                  
                  // Title and Subtitle
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'التأكيد والتفويض',
                              style: _titleStyle.copyWith(fontSize: _titleFontSize * 0.9),
                            ),
                            SizedBox(height: _verticalPadding * 0.2),
                            Text(
                              'الصفحة ٦ من ٦',
                              style: _smallStyle.copyWith(
                                color: _hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // محتوى قابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_horizontalPadding * 0.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: _verticalPadding * 0.5),
                    
                    // Information Card
                    _buildInfoCard('يرجى قراءة الشروط والأحكام بعناية قبل المتابعة'),
                    
                    SizedBox(height: _verticalPadding),
                    
                    // Authorization Section
                    _buildSection(
                      title: 'التفويض والموافقة',
                      backgroundColor: _backgroundColor,
                      children: [
                        Text(
                          'بالتوقيع أدناه، أوافق على ما يلي:',
                          style: _bodyStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                        
                        SizedBox(height: _verticalPadding * 0.8),
                        
                        // Agreement Items
                        _buildAgreementItem(_correctInfo),
                        SizedBox(height: _verticalPadding * 0.5),
                        
                        _buildAgreementItem(_Missing_Persons_Platform_upload),
                        SizedBox(height: _verticalPadding * 0.5),
                        
                        _buildAgreementItemWithLink(
                          'أوافق على معالجة بياناتي الشخصية وفقاً لنظام حماية البيانات الشخصية في المملكة العربية السعودية. للمزيد من التفاصيل، يرجى الاطلاع على ',
                          'نظام حماية البيانات الشخصية',
                          _launchURL_dataPrivacy,
                        ),
                      ],
                    ),
                    
                    // Signature Section
                    _buildSection(
                      title: 'التوقيع',
                      children: [
                        Text(
                          'ارسم توقيعك في المساحة أدناه:',
                          style: _bodyStyle.copyWith(
                            fontSize: _bodyFontSize * 0.9,
                            color: _hintColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        SizedBox(height: _verticalPadding * 0.8),
                        
                        // Signature Pad
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                            color: Color.fromARGB(255, 250, 250, 250),
                          ),
                          child: Stack(
                            children: [
                              SfSignaturePad(
                                key: signaturePadKey,
                                minimumStrokeWidth: 2,
                                maximumStrokeWidth: 2,
                                strokeColor: _primaryColor,
                                backgroundColor: Colors.transparent,
                              ),
                              _isUploading
                                  ? Container(
                                      color: Colors.black.withOpacity(0.3),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SpinKitCubeGrid(
                                            color: _primaryColor, 
                                            size: 50
                                          ),
                                          SizedBox(height: _verticalPadding * 0.5),
                                          Text(
                                            'جاري حفظ التوقيع...',
                                            style: _smallStyle.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: _verticalPadding * 0.8),
                        
                        // Signature Actions
                        Row(
                          children: [
                            Expanded(
                              child: _buildButton(
                                text: 'مسح',
                                onPressed: () {
                                  _debugPrint('🧹 مسح التوقيع');
                                  signaturePadKey.currentState!.clear();
                                },
                                isPrimary: false,
                                backgroundColor: _hintColor.withOpacity(0.1),
                              ),
                            ),
                            SizedBox(width: _horizontalPadding * 0.4),
                            Expanded(
                              child: _buildButton(
                                text: 'حفظ التوقيع',
                                onPressed: () async {
                                  _debugPrint('💾 حفظ التوقيع');
                                  if (signaturePadKey.currentState != null) {
                                    setState(() {
                                      _isUploading = true;
                                    });
                                    
                                    try {
                                      ui.Image image = await signaturePadKey
                                          .currentState!
                                          .toImage();
                                      await _getSignature(image);
                                      await _saveSignature();
                                      await retrievePrefsData();
                                      
                                      // Show preview dialog
                                      await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                              'معاينة التوقيع',
                                              style: _headingStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                            content: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: _borderColor),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Image.memory(signaturePhoto!),
                                            ),
                                            actions: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text(
                                                        'إغلاق',
                                                        style: _bodyStyle.copyWith(
                                                          color: _hintColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: TextButton(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: _errorColor,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          signaturePhoto = null;
                                                          try {
                                                            _prefsInstance!.remove('p6_reporteeSignature');
                                                            _prefsInstance!.remove('p6_reporteeSignature_PATH');
                                                          } catch (e) {
                                                            _debugPrint('خطأ في حذف التوقيع: $e');
                                                          }
                                                        });
                                                        Navigator.of(context).pop();
                                                        signaturePadKey.currentState!.clear();
                                                      },
                                                      child: Text(
                                                        'حذف التوقيع',
                                                        style: _bodyStyle.copyWith(
                                                          color: _errorColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } catch (e) {
                                      _debugPrint('Error saving signature: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'حدث خطأ أثناء حفظ التوقيع',
                                            style: _bodyStyle.copyWith(color: Colors.white),
                                          ),
                                          backgroundColor: _errorColor,
                                        ),
                                      );
                                    } finally {
                                      setState(() {
                                        _isUploading = false;
                                      });
                                    }
                                  }
                                },
                                isPrimary: true,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: _verticalPadding * 0.8),
                        
                        // Saved Signature Preview
                        if (_prefsInstance != null && _prefsInstance!.getString('p6_reporteeSignature') != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(_horizontalPadding * 0.6),
                            decoration: BoxDecoration(
                              color: _successColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _successColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: _successColor,
                                  size: _bodyFontSize * 1.2,
                                ),
                                SizedBox(width: _horizontalPadding * 0.4),
                                Expanded(
                                  child: Text(
                                    'تم حفظ التوقيع بنجاح',
                                    style: _smallStyle.copyWith(
                                      color: _successColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    _debugPrint('👀 عرض التوقيع المحفوظ');
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                            'معاينة التوقيع المحفوظ',
                                            style: _headingStyle,
                                            textAlign: TextAlign.center,
                                          ),
                                          content: Container(
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: _borderColor),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: signaturePhoto != null
                                                ? Image.memory(signaturePhoto!)
                                                : Text(
                                                    'لا يوجد توقيع محفوظ',
                                                    style: _bodyStyle,
                                                    textAlign: TextAlign.center,
                                                  ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'إغلاق',
                                                style: _bodyStyle,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    'عرض',
                                    style: _smallStyle.copyWith(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(_horizontalPadding * 0.6),
                            decoration: BoxDecoration(
                              color: _warningColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _warningColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: _warningColor,
                                  size: _bodyFontSize * 1.2,
                                ),
                                SizedBox(width: _horizontalPadding * 0.4),
                                Expanded(
                                  child: Text(
                                    'لم يتم حفظ التوقيع بعد',
                                    style: _smallStyle.copyWith(
                                      color: _warningColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: _verticalPadding),
                    
                    // Submit Section
                    _buildSection(
                      title: 'تقديم التقرير',
                      children: [
                        Text(
                          'يمكنك تقديم التقرير حتى مع وجود بعض الحقول فارغة',
                          style: _smallStyle.copyWith(
                            color: _hintColor,
                          ),
                        ),
                        
                        SizedBox(height: _verticalPadding * 0.8),
                        
                        // أزرار التشخيص
                        Column(
                          children: [
                            // زر الفحص السريع
                            _buildButton(
                              text: 'فحص سريع للبيانات',
                              onPressed: () async {
                                _debugPrint('👆 تم النقر على زر الفحص السريع');
                                await _quickDataCheck();
                                _showSuccessSnackbar('تم الفحص السريع - راجع الكونسول');
                              },
                              isPrimary: false,
                              backgroundColor: _primaryColor.withOpacity(0.1),
                            ),
                            
                            SizedBox(height: _verticalPadding * 0.3),
                            
                            // زر التشخيص الشامل
                            _buildButton(
                              text: 'تشخيص شامل للنظام',
                              onPressed: () async {
                                _debugPrint('👆 تم النقر على زر التشخيص الشامل');
                                await _fullSystemDiagnostic();
                                _showSuccessSnackbar('تم التشخيص الشامل - راجع الكونسول');
                              },
                              isPrimary: false,
                              backgroundColor: _warningColor.withOpacity(0.1),
                            ),
                            
                            SizedBox(height: _verticalPadding * 0.3),
                            
                            // زر اختبار الحفظ
                            _buildButton(
                              text: 'اختبار حفظ بسيط',
                              onPressed: () async {
                                _debugPrint('👆 تم النقر على زر الاختبار البسيط');
                                await _testSimpleSave();
                              },
                              isPrimary: false,
                              backgroundColor: _successColor.withOpacity(0.1),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: _verticalPadding * 0.8),
                        
                        // زر تقديم التقرير الرئيسي
                        _buildButton(
                          text: 'تقديم التقرير',
                          onPressed: () async {
                            _debugPrint('👆 تم النقر على زر تقديم التقرير');
                            bool isValid = checkReportValidity(REPORT_ALWAYS_VALID);
                            
                            if (isValid) {
                              _showConfirmationDialog();
                            }
                          },
                          isPrimary: true,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: _verticalPadding),
                    
                    // Footer Section
                    Container(
                      padding: EdgeInsets.all(_horizontalPadding * 0.8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primaryColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: _primaryColor,
                            size: _bodyFontSize * 1.2,
                          ),
                          SizedBox(width: _horizontalPadding * 0.4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نهاية نموذج التقرير',
                                  style: _smallStyle.copyWith(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: _verticalPadding * 0.2),
                                Text(
                                  'شكراً لاستخدامك تطبيق Missing_Persons_Platform',
                                  style: _smallStyle.copyWith(
                                    color: _hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // مسافة إضافية في الأسفل
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}