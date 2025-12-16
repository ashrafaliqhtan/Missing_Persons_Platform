import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'mapDialog.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlong2;

// استيراد مكتبات OpenStreetMap مع تجنب التعارض
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;

// datepicker stuff - نفس الكود تماماً
List reformatDate(String dateTime, DateTime dateTimeBday) {
  var dateParts = dateTime.split('-');
  var month = dateParts[1];
  if (int.parse(month) % 10 != 0) {
    month = month.replaceAll('0', '');
  }
  // switch case of shame
  switch (month) {
    case '1':
      month = 'يناير';
      break;
    case '2':
      month = 'فبراير';
      break;
    case '3':
      month = 'مارس';
      break;
    case '4':
      month = 'أبريل';
      break;
    case '5':
      month = 'مايو';
      break;
    case '6':
      month = 'يونيو';
      break;
    case '7':
      month = 'يوليو';
      break;
    case '8':
      month = 'أغسطس';
      break;
    case '9':
      month = 'سبتمبر';
      break;
    case '10':
      month = 'أكتوبر';
      break;
    case '11':
      month = 'نوفمبر';
      break;
    case '12':
      month = 'ديسمبر';
      break;
  }

  var day = dateParts[2];
  var daySpaceIndex = day.indexOf(' ');
  if (daySpaceIndex >= 0) {
    day = day.substring(0, daySpaceIndex);
  }
  if (day.isNotEmpty && int.parse(day) % 10 != 0) {
    day = day.replaceAll('0', '');
  }

  var year = dateParts[0];

  var age =
      (DateTime.now().difference(dateTimeBday).inDays / 365).floor().toString();
  var returnVal = '$day $month $year';
  return [returnVal, age];
}

class Page5IncidentDetails extends StatefulWidget {
  final VoidCallback addHeightParent;
  final VoidCallback subtractHeightParent;
  final VoidCallback enhancedHeightParent;
  const Page5IncidentDetails(
      {super.key,
      required this.addHeightParent,
      required this.subtractHeightParent,
      required this.enhancedHeightParent});

  @override
  State<Page5IncidentDetails> createState() => _Page5IncidentDetailsState();
}

DateTime now = DateTime.now();
DateTime dateNow = DateTime(now.year, now.month, now.day);
String userUID = FirebaseAuth.instance.currentUser!.uid;
late SharedPreferences prefs;

class _Page5IncidentDetailsState extends State<Page5IncidentDetails> {
  String reportCount = 'NONE';

  // ألوان مخصصة للمملكة العربية السعودية - نفس الألوان تماماً
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

  // أحجام خطوط متجاوبة - نفس الأحجام تماماً
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.065;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.04;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.035;
  
  // مسافات متجاوبة - نفس المسافات تماماً
  double get _verticalPadding => MediaQuery.of(context).size.height * 0.015;
  double get _horizontalPadding => MediaQuery.of(context).size.width * 0.045;

  // أنماط النص - نفس الأنماط تماماً
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

  // local variables for text fields - نفس المتغيرات تماماً
  String? reportDate = '${dateNow.day}/${dateNow.month}/${dateNow.year}';
  String? lastSeenDate;
  String? lastSeenTime;
  String? totalHoursSinceLastSeen;
  String? lastSeenLoc;
  String? incidentDetails;
  Uint8List? locSnapshot;
  // for geocoding
  String? lastSeenLoc_lat;
  String? lastSeenLoc_lng;
  String? placeName;
  String? nearestLandmark;
  String? cityName;
  String? brgyName;
  //
  TimeOfDay? picked_time = null;

  // time
  DateTime? _selectedTime;

  // متغير للتحكم في التمرير
  final ScrollController _scrollController = ScrollController();

  // متغير لتحميل البيانات
  bool _isLoading = false;
  bool _isGeolocationSupported = true;

  // نفس الدوال تماماً مع تعديلات بسيطة للخرائط
  retrieveUserData() async {
    prefs = await SharedPreferences.getInstance();
    await FirebaseDatabase.instance
        .ref("Main Users")
        .child(userUID)
        .get()
        .then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> userDict = snapshot.value as Map<dynamic, dynamic>;
      print('${userDict['firstName']} ${userDict['lastName']}');
      reportCount = userDict['reportCount'];
    });
    print('[REPORT COUNT] report count: $reportCount');
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: _primaryColor,
            colorScheme: ColorScheme.light(primary: _primaryColor),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime =
            DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        lastSeenTime = DateFormat('hh:mm a', 'ar').format(_selectedTime!);
        _writeToPrefs('p5_lastSeenTime', lastSeenTime!);
        _calculateHoursSinceLastSeen();
      });
    }
  }

  /* SHARED PREF EMPTY CHECKER AND SAVER FUNCTION*/
  Future<void> _writeToPrefs(String key, String value) async {
    if (value != '') {
      prefs.setString(key, value);
    } else {
      prefs.remove(key);
    }
  }

  Future<void> getSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      widget.enhancedHeightParent();
      prefs.setString('p5_reportDate', reportDate!);
      lastSeenDate = prefs.getString('p5_lastSeenDate');
      lastSeenTime = prefs.getString('p5_lastSeenTime');
      totalHoursSinceLastSeen = prefs.getString('p5_totalHoursSinceLastSeen');

      prefs.containsKey('p5_lastSeenDate') ? widget.addHeightParent() : null;
      prefs.containsKey('p5_lastSeenTime') ? widget.addHeightParent() : null;
      prefs.containsKey('p5_totalHoursSinceLastSeen')
          ? widget.addHeightParent()
          : null;

      lastSeenLoc = prefs.getString('p5_lastSeenLoc');
      incidentDetails = prefs.getString('p5_incidentDetails');
      String? locSnapshotString = prefs.getString('p5_locSnapshot');
      if (locSnapshotString != null) {
        locSnapshot = base64Decode(locSnapshotString);
      } else {
        print('[p5] No location snapshot');
      }
      // for geocoding
      placeName = prefs.getString('p5_placeName');
      nearestLandmark = prefs.getString('p5_nearestLandmark');
      cityName = prefs.getString('p5_cityName');
      brgyName = prefs.getString('p5_brgyName');
    });
  }

  void _calculateHoursSinceLastSeen() {
    if (lastSeenDate != null && lastSeenTime != null) {
      try {
        DateFormat inputFormat = DateFormat('d MMMM y hh:mm a', 'ar');
        DateTime lastSeenDateAndTime = inputFormat.parse('$lastSeenDate $lastSeenTime');
        DateTime currentDateAndTime = DateTime.now();
        Duration timeDifference = currentDateAndTime.difference(lastSeenDateAndTime);
        int hoursSinceLastSeen = timeDifference.inHours;
        
        setState(() {
          totalHoursSinceLastSeen = hoursSinceLastSeen.toString();
          _writeToPrefs('p5_totalHoursSinceLastSeen', totalHoursSinceLastSeen!);
        });
      } catch (e) {
        print('Error calculating hours: $e');
      }
    }
  }

  /* FUNCTIONS FOR GEOCODING - تم التعديل لاستخدام OSM */
  Future<void> _getAddress() async {
    if (kIsWeb) {
      // استخدام Nominatim Geocoding API للويب
      await _getAddressFromOSMAPI();
    } else {
      // استخدام Nominatim للأجهزة المحمولة
      await _getAddressFromOSMAPI();
    }
  }

  // دالة جديدة للحصول على العنوان باستخدام Nominatim (OpenStreetMap)
  Future<void> _getAddressFromOSMAPI() async {
    try {
      final lat = lastSeenLoc_lat;
      final lng = lastSeenLoc_lng;
      
      if (lat == null || lng == null) return;
      
      // استخدام خدمة Nominatim للعكس Geocoding
      final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=ar'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['address'] != null) {
          final address = data['address'];
          
          setState(() {
            placeName = data['display_name'] ?? 'لم يتم العثور على المكان';
            _writeToPrefs('p5_placeName', placeName!);
            
            cityName = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? 'غير معروف';
            _writeToPrefs('p5_cityName', cityName!);
            
            brgyName = address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? 'غير معروف';
            _writeToPrefs('p5_brgyName', brgyName!);
            
            nearestLandmark = address['road'] ?? address['amenity'] ?? address['building'] ?? 'غير معروف';
            _writeToPrefs('p5_nearestLandmark', nearestLandmark!);
          });
        }
      } else {
        throw Exception('Failed to get address from OSM');
      }
    } catch (e) {
      print('Error getting address from OSM: $e');
      // استخدام قيم افتراضية في حالة الخطأ
      setState(() {
        placeName = 'تم تحديد الموقع ولكن لا يمكن الحصول على العنوان';
        cityName = 'غير معروف';
        brgyName = 'غير معروف';
        nearestLandmark = 'غير معروف';
        
        _writeToPrefs('p5_placeName', placeName!);
        _writeToPrefs('p5_cityName', cityName!);
        _writeToPrefs('p5_brgyName', brgyName!);
        _writeToPrefs('p5_nearestLandmark', nearestLandmark!);
      });
    }
  }

  @override
  void initState() {
    checkLocationPermission();
    getSharedPrefs();
    try {
      print(prefs.getKeys());
    } catch (e) {
      print('[P5] prefs not initialized yet');
    }
    
    // التحقق من دعم Geolocation في الويب
    if (kIsWeb) {
      _checkGeolocationSupport();
    }
    
    super.initState();
    retrieveUserData();
  }

  bool isPermitted = false;
  void checkLocationPermission() async {
    if (kIsWeb) {
      // في الويب، نستخدم Geolocation API مباشرة
      setState(() {
        isPermitted = true; // نعتمد على متصفح المستخدم
      });
    } else {
      // للأجهزة المحمولة
      bool toChange = await Permission.location.isDenied
          .then((value) => isPermitted = !value);
      print('isloading: $isPermitted');
    }
  }

  // دالة للتحقق من دعم Geolocation في المتصفح
  void _checkGeolocationSupport() {
    if (!kIsWeb) return;
    
    final geolocation = html.window.navigator.geolocation;
    final isHttps = html.window.location.protocol == 'https:';
    
    setState(() {
      _isGeolocationSupported = (geolocation != null && isHttps);
    });
    
    print('Geolocation supported: $_isGeolocationSupported');
    print('Using HTTPS: $isHttps');
  }

  // دالة منفصلة للتعامل مع تحديد الموقع في الويب - تم التصحيح
  Future<void> _getCurrentLocationWeb() async {
    if (!kIsWeb) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('طلب إذن الموقع من المتصفح...');
      
      // استخدام HTML5 Geolocation API بشكل أكثر أماناً
      final geolocation = html.window.navigator.geolocation;
      if (geolocation == null) {
        throw Exception("Geolocation API غير متوفر في هذا المتصفح");
      }

      // استخدام Future للتعامل مع الـ Promise بشكل صحيح
      final position = await _getPosition();
      
      // التحقق من وجود الإحداثيات بشكل آمن
      final lat = position.coords?.latitude;
      final lng = position.coords?.longitude;

      if (lat == null || lng == null) {
        throw Exception("لم يتم الحصول على إحداثيات صالحة");
      }

      print('تم الحصول على الإحداثيات: $lat, $lng');

      // تحويل num إلى double بشكل صريح وآمن
      final double latDouble = lat.toDouble();
      final double lngDouble = lng.toDouble();

      setState(() {
        lastSeenLoc = '$latDouble, $lngDouble';
        lastSeenLoc_lat = latDouble.toString();
        lastSeenLoc_lng = lngDouble.toString();

        _writeToPrefs('p5_lastSeenLoc', lastSeenLoc!);
      });

      // الحصول على العنوان
      print('جاري الحصول على العنوان...');
      await _getAddress();

      // إنشاء صورة الخريطة
      print('جاري إنشاء صورة الخريطة...');
      final snapshot = await _createMapSnapshot(latDouble, lngDouble);
      if (snapshot != null) {
        setState(() {
          locSnapshot = snapshot;
          _writeToPrefs('p5_locSnapshot', base64Encode(snapshot));
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديد الموقع بنجاح',
            style: _bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: _successColor,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print('Error getting location in web: $e');
      _showLocationErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة مساعدة للتعامل مع Geolocation API - تم التصحيح
  Future<html.Geoposition> _getPosition() {
    final completer = Completer<html.Geoposition>();
    
    final geolocation = html.window.navigator.geolocation;
    
    // استخدام الـ Promise بشكل صحيح
    geolocation?.getCurrentPosition().then(
      (html.Geoposition position) {
        print('تم الحصول على الموقع بنجاح');
        completer.complete(position);
      },
      onError: (error) {
        String errorMessage;
        switch (error) {
          case 1:
            errorMessage = 'تم رفض الإذن للوصول إلى الموقع. يرجى السماح بالإذن في المتصفح.';
            break;
          case 2:
            errorMessage = 'معلومات الموقع غير متوفرة. تأكد من اتصال الإنترنت.';
            break;
          case 3:
            errorMessage = 'انتهت المهلة في الحصول على الموقع. حاول مرة أخرى.';
            break;
          default:
            errorMessage = 'حدث خطأ غير معروف: $error';
        }
        print('Geolocation error: $errorMessage');
        completer.completeError(Exception(errorMessage));
      }
    );
    
    return completer.future;
  }

  // دالة لإنشاء صورة الخريطة
  Future<Uint8List?> _createMapSnapshot(double lat, double lng) async {
    try {
      // في الإصدار الحقيقي، يمكنك استخدام RepaintBoundary و screenshot
      // لكن للتبسيط سنستخدم صورة ثابتة من خدمة الخرائط
      final zoom = 16;
      final x = ((lng + 180.0) / 360.0 * pow(2, zoom)).floor();
      final y = ((1.0 - log(tan(lat * pi / 180.0) + 1.0 / cos(lat * pi / 180.0)) / pi) / 2.0 * pow(2, zoom)).floor();
      
      final response = await http.get(Uri.parse(
        'https://tile.openstreetmap.org/$zoom/$x/$y.png'
      ));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error creating map snapshot: $e');
    }
    return null;
  }

  void _showLocationErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'خطأ في تحديد الموقع',
            style: _headingStyle,
            textAlign: TextAlign.right,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorMessage,
                  style: _bodyStyle,
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: _verticalPadding),
                Text(
                  'يرجى التأكد من:\n\n'
                  '1. أنك تستخدم HTTPS\n'
                  '2. الموافقة على طلب صلاحية الموقع\n'
                  '3. تفعيل JavaScript في المتصفح\n'
                  '4. أن المتصفح يدعم Geolocation API',
                  style: _smallStyle,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'حسناً',
                style: _bodyStyle.copyWith(color: _primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectLocationManually(); // فتح الخريطة للاختيار اليدوي
              },
              child: Text(
                'اختيار موقع يدوياً',
                style: _bodyStyle.copyWith(color: _accentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // دالة بديلة لاختيار الموقع يدوياً على الخريطة
  Future<void> _selectLocationManually() async {
    if (kIsWeb) {
      // في الويب، نفتح خريطة للاختيار اليدوي
      await _openMapForManualSelection();
    } else {
      // للأجهزة المحمولة، استخدام MapDialog
      await _handleMobileLocationSelection();
    }
  }

  // فتح خريطة للاختيار اليدوي في الويب
  Future<void> _openMapForManualSelection() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.map, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'اختر الموقع يدوياً',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
                // التعليمات
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.amber[50],
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'انقر على الخريطة لتحديد موقع آخر مشاهدة',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 14,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: latlong2.LatLng(24.7136, 46.6753), // مركز الرياض
                      initialZoom: 10.0,
                      onTap: (tapPosition, point) {
                        Navigator.of(context).pop({
                          'location': point,
                          'image': null,
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.Missing_Persons_Platform',
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(fontFamily: 'Tajawal'),
                        ),
                      ),
                      Text(
                        'انقر على الخريطة لتحديد الموقع',
                        style: _smallStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      latlong2.LatLng location = result['location'];
      setState(() {
        lastSeenLoc = '${location.latitude}, ${location.longitude}';
        lastSeenLoc_lat = location.latitude.toString();
        lastSeenLoc_lng = location.longitude.toString();
        _writeToPrefs('p5_lastSeenLoc', lastSeenLoc!);
        _getAddress();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديد الموقع يدوياً بنجاح',
            style: _bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: _successColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // دالة مساعدة لبناء حقل النموذج - نفس الدالة تماماً
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function(String)? onChanged,
    bool enabled = true,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: _bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                      fontSize: _bodyFontSize * 0.9,
                    ),
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: _requiredStyle,
                  ),
              ],
            ),
            SizedBox(height: _verticalPadding * 0.2),
          ],
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            maxLines: maxLines,
            enabled: enabled,
            readOnly: readOnly,
            textAlign: TextAlign.right,
            onTap: onTap,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: _smallStyle.copyWith(color: _hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor.withOpacity(0.5)),
              ),
              filled: true,
              fillColor: enabled ? _cardColor : Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _horizontalPadding * 0.6,
                vertical: _verticalPadding * 0.6,
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء قسم - نفس الدالة تماماً
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

  // دالة مساعدة لبناء زر - نفس الدالة تماماً
  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPrimary = true,
    bool isEnabled = true,
    double? width,
    bool isLoading = false,
  }) {
    return Container(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? _primaryColor : _cardColor,
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

  // دالة مساعدة لبناء بطاقة معلومات - نفس الدالة تماماً
  Widget _buildInfoCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: _bodyFontSize * 1.2, color: _accentColor),
          SizedBox(width: _horizontalPadding * 0.4),
          Expanded(
            child: Text(
              message,
              style: _smallStyle.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء معاينة الموقع - تم التحديث لاستخدام FlutterMap مع الإصدار 8.x
  Widget _buildLocationPreview() {
    if (lastSeenLoc_lat != null && lastSeenLoc_lng != null) {
      final lat = double.tryParse(lastSeenLoc_lat!);
      final lng = double.tryParse(lastSeenLoc_lng!);
      
      if (lat != null && lng != null) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
            color: _cardColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: latlong2.LatLng(lat, lng), // استخدام initialCenter بدلاً من center
                initialZoom: 16.0,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.none), // جعل الخريطة غير تفاعلية للمعاينة
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.Missing_Persons_Platform',
                ),
                
fmap.MarkerLayer(
  markers: [
    fmap.Marker(
      width: 40.0,
      height: 40.0,
      point: latlong2.LatLng(lat, lng),
      child: Icon(
        Icons.location_on,
        color: _accentColor,
        size: 40,
      ),
    ),
  ],
),
              ],
            ),
          ),
        );
      }
    }
    
    // إذا لم يكن هناك موقع محدد
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        color: _cardColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 60,
            color: _hintColor,
          ),
          SizedBox(height: _verticalPadding * 0.5),
          Text(
            'لم يتم تحديد الموقع',
            style: _smallStyle.copyWith(color: _hintColor),
          ),
        ],
      ),
    );
  }

  // بناء معلومات الموقع للويب - تم التحديث
  Widget _buildWebLocationInfo() {
    if (kIsWeb) {
      final geolocation = html.window.navigator.geolocation;
      final isHttps = html.window.location.protocol == 'https:';
      final isSupported = (geolocation != null && isHttps);
      
      return Container(
        padding: EdgeInsets.all(_horizontalPadding * 0.6),
        decoration: BoxDecoration(
          color: isSupported ? _primaryColor.withOpacity(0.1) : _warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSupported ? _primaryColor.withOpacity(0.3) : _warningColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSupported ? Icons.info_outline : Icons.warning,
                  size: 16,
                  color: isSupported ? _primaryColor : _warningColor,
                ),
                SizedBox(width: 8),
                Text(
                  isSupported 
                      ? 'تحديد الموقع باستخدام OpenStreetMap'
                      : 'تحذير: مشكلة في تحديد الموقع',
                  style: _smallStyle.copyWith(
                    color: isSupported ? _primaryColor : _warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              isSupported
                  ? 'يستخدم التطبيق خرائط OpenStreetMap المجانية. سيطلب منك المتصفح الإذن للوصول إلى موقعك.'
                  : 'Geolocation غير مدعوم أو أنك لا تستخدم HTTPS. استخدم الزر "اختيار موقع يدوياً".',
              style: _smallStyle.copyWith(
                color: isSupported ? _primaryColor : _warningColor,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  // دالة منفصلة للتعامل مع تحديد الموقع في الأجهزة المحمولة
  Future<void> _handleMobileLocationSelection() async {
    Map<String, dynamic>? result;
    if (reportCount != 'NONE') {
      result = await showDialog<Map<String, dynamic>?>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return MapDialog(
            uid: userUID,
            reportCount: reportCount,
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'جاري تحميل بيانات المستخدم',
            style: _bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: _warningColor,
        ),
      );
      return;
    }
    
    if (result != null) {
      latlong2.LatLng location = result['location'];
      Uint8List? image;
      try {
        image = result['image'];
      } catch (e) {
        print(e);
      }

      print('Selected location: ${location.latitude}, ${location.longitude}');
      setState(() {
        locSnapshot = image;
        lastSeenLoc = '${location.latitude}, ${location.longitude}';
        _writeToPrefs('p5_lastSeenLoc', lastSeenLoc!);
        lastSeenLoc_lat = location.latitude.toString();
        lastSeenLoc_lng = location.longitude.toString();
        _getAddress();
      });
    }
  }

  // دالة رئيسية للتعامل مع تحديد الموقع
  Future<void> _handleLocationSelection() async {
    if (kIsWeb) {
      // في الويب، نعطي خيارين: التحديد التلقائي أو اليدوي
      if (_isGeolocationSupported) {
        await _getCurrentLocationWeb();
      } else {
        await _selectLocationManually();
      }
    } else {
      // للأجهزة المحمولة
      await _handleMobileLocationSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header ثابت - نفس التصميم تماماً
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
                        width: MediaQuery.of(context).size.width * 0.5,
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
                              'تفاصيل الحادث',
                              style: _titleStyle.copyWith(fontSize: _titleFontSize * 0.9),
                            ),
                            SizedBox(height: _verticalPadding * 0.2),
                            Text(
                              'الصفحة ٥ من ٦',
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
            
            // محتوى قابل للتمرير - نفس التصميم تماماً
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                          ),
                          SizedBox(height: _verticalPadding),
                          Text(
                            'جاري تحديد الموقع...',
                            style: _bodyStyle,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(_horizontalPadding * 0.8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: _verticalPadding * 0.5),
                          
                          // Information Card
                          _buildInfoCard('الحقول التي تحمل علامة (*) مطلوبة. باقي الحقول يتم تعبئتها تلقائياً'),
                          
                          SizedBox(height: _verticalPadding),
                          
                          // Report Date Section
                          _buildSection(
                            title: 'تاريخ التبليغ',
                            backgroundColor: _backgroundColor,
                            children: [
                              _buildFormField(
                                controller: TextEditingController(text: reportDate),
                                label: 'تاريخ التبليغ',
                                hint: reportDate ?? '',
                                enabled: false,
                                readOnly: true,
                              ),
                              SizedBox(height: _verticalPadding * 0.3),
                              Text(
                                'يتم تعبئة تاريخ التبليغ تلقائياً بتاريخ اليوم',
                                style: _smallStyle.copyWith(color: _hintColor),
                              ),
                            ],
                          ),
                          
                          // Last Seen Section
                          _buildSection(
                            title: 'آخر مرة شوهد فيها',
                            children: [
                              _buildFormField(
                                controller: TextEditingController(text: lastSeenDate),
                                label: 'تاريخ آخر مشاهدة *',
                                hint: 'انقر لاختيار التاريخ',
                                isRequired: true,
                                readOnly: true,
                                onTap: () async {
                                  var result = await showCalendarDatePicker2Dialog(
                                    dialogSize: const Size(325, 400),
                                    context: context,
                                    config: CalendarDatePicker2WithActionButtonsConfig(
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      selectedDayHighlightColor: _primaryColor,
                                      controlsHeight: 50,
                                    ),
                                    value: [DateTime.now()],
                                    borderRadius: BorderRadius.circular(16),
                                  );
                                  if (result != null && result.isNotEmpty) {
                                    var date = result[0];
                                    var dateFormatted = DateFormat('yyyy-MM-dd').format(date!);
                                    var dateReformatted = reformatDate(dateFormatted, date);
                                    
                                    setState(() {
                                      lastSeenDate = dateReformatted[0];
                                      _writeToPrefs('p5_lastSeenDate', lastSeenDate!);
                                      _calculateHoursSinceLastSeen();
                                    });
                                    widget.addHeightParent();
                                  }
                                },
                              ),
                              
                              if (lastSeenDate != null) ...[
                                _buildFormField(
                                  controller: TextEditingController(text: lastSeenTime),
                                  label: 'وقت آخر مشاهدة *',
                                  hint: 'انقر لاختيار الوقت',
                                  isRequired: true,
                                  readOnly: true,
                                  onTap: _selectTime,
                                ),
                                
                                SizedBox(height: _verticalPadding * 0.3),
                                Text(
                                  'يمكنك تقدير الوقت إذا لم تكن متأكداً من التوقيت الدقيق',
                                  style: _smallStyle.copyWith(color: _hintColor),
                                ),
                              ],
                              
                              if (lastSeenDate != null && lastSeenTime != null) ...[
                                SizedBox(height: _verticalPadding * 0.5),
                                _buildFormField(
                                  controller: TextEditingController(text: totalHoursSinceLastSeen),
                                  label: 'عدد الساعات منذ آخر مشاهدة',
                                  hint: 'يتم حسابها تلقائياً',
                                  enabled: false,
                                  readOnly: true,
                                ),
                              ],
                            ],
                          ),
                          
                          // Location Section
                          _buildSection(
                            title: 'موقع آخر مشاهدة',
                            children: [
                              // Location Map Preview - تم التحديث
                              _buildLocationPreview(),
                              
                              SizedBox(height: _verticalPadding),
                              
                              // معلومات الموقع للويب - تم التحديث
                              _buildWebLocationInfo(),
                              
                              SizedBox(height: _verticalPadding),
                              
                              // أزرار تحديد الموقع
                              if (kIsWeb && _isGeolocationSupported) ...[
                                Column(
                                  children: [
                                    _buildButton(
                                      text: 'تحديد موقعي الحالي تلقائياً',
                                      onPressed: isPermitted ? _getCurrentLocationWeb : null,
                                      isEnabled: isPermitted,
                                      isLoading: _isLoading,
                                    ),
                                    SizedBox(height: _verticalPadding * 0.5),
                                    _buildButton(
                                      text: 'اختيار موقع يدوياً على الخريطة',
                                      onPressed: _selectLocationManually,
                                      isPrimary: false,
                                    ),
                                  ],
                                ),
                              ] else if (kIsWeb) ...[
                                _buildButton(
                                  text: 'اختيار موقع على الخريطة',
                                  onPressed: _selectLocationManually,
                                  isPrimary: true,
                                ),
                              ] else ...[
                                _buildButton(
                                  text: 'تحديد الموقع على الخريطة',
                                  onPressed: isPermitted ? _handleLocationSelection : null,
                                  isEnabled: isPermitted,
                                  isLoading: _isLoading,
                                ),
                              ],
                              
                              if (!isPermitted && !kIsWeb) ...[
                                SizedBox(height: _verticalPadding * 0.5),
                                Container(
                                  padding: EdgeInsets.all(_horizontalPadding * 0.5),
                                  decoration: BoxDecoration(
                                    color: _warningColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _warningColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 16, color: _warningColor),
                                      SizedBox(width: _horizontalPadding * 0.3),
                                      Expanded(
                                        child: Text(
                                          'صلاحية الموقع الدقيق غير مفعلة',
                                          style: _smallStyle.copyWith(color: _warningColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              SizedBox(height: _verticalPadding),
                              
                              // Location Details
                              Text(
                                'تفاصيل الموقع',
                                style: _headingStyle.copyWith(fontSize: _bodyFontSize),
                              ),
                              SizedBox(height: _verticalPadding * 0.5),
                              
                              _buildFormField(
                                controller: TextEditingController(text: placeName),
                                label: 'اسم المكان',
                                hint: 'سيتم تعبئته تلقائياً',
                                enabled: false,
                                readOnly: true,
                              ),
                              
                              _buildFormField(
                                controller: TextEditingController(text: nearestLandmark),
                                label: 'أقرب معلم',
                                hint: 'سيتم تعبئته تلقائياً',
                                enabled: false,
                                readOnly: true,
                              ),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFormField(
                                      controller: TextEditingController(text: cityName),
                                      label: 'المدينة',
                                      hint: 'سيتم تعبئته تلقائياً',
                                      enabled: false,
                                      readOnly: true,
                                    ),
                                  ),
                                  SizedBox(width: _horizontalPadding * 0.3),
                                  Expanded(
                                    child: _buildFormField(
                                      controller: TextEditingController(text: brgyName),
                                      label: 'الحي/المنطقة',
                                      hint: 'سيتم تعبئته تلقائياً',
                                      enabled: false,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Incident Details Section
                          _buildSection(
                            title: 'تفاصيل الحادث',
                            children: [
                              Text(
                                'يرجى تقديم أكبر قدر ممكن من التفاصيل. الإجابة على أسئلة "من، ماذا، متى، أين، لماذا، وكيف" ستساعدنا في فهم الحادث بشكل أفضل.',
                                style: _smallStyle.copyWith(color: _hintColor),
                              ),
                              
                              SizedBox(height: _verticalPadding * 0.5),
                              
                              _buildFormField(
                                controller: TextEditingController(text: incidentDetails),
                                label: 'تفاصيل الحادث *',
                                hint: 'صف ما حدث بالتفصيل...',
                                isRequired: true,
                                maxLines: 6,
                                maxLength: 500,
                                onChanged: (value) {
                                  incidentDetails = value;
                                  _writeToPrefs('p5_incidentDetails', incidentDetails!);
                                },
                              ),
                              
                              SizedBox(height: _verticalPadding * 0.3),
                              
                              Container(
                                padding: EdgeInsets.all(_horizontalPadding * 0.6),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _primaryColor.withOpacity(0.1)),
                                ),
                                child: Text(
                                  'ملاحظة: إذا كان الحادث يتعلق بـ "ضحية جريمة" أو "ضحية كارثة أو حادث"، يرجى تقديم تفاصيل محددة حول الجريمة أو الكارثة/الحادث.',
                                  style: _smallStyle.copyWith(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: _verticalPadding),
                          
                          // Footer Section
                          Container(
                            padding: EdgeInsets.all(_horizontalPadding * 0.8),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _accentColor.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Lottie.asset(
                                  "assets/lottie/swipeLeft.json",
                                  animate: true,
                                  width: MediaQuery.of(context).size.width * 0.1,
                                  height: MediaQuery.of(context).size.width * 0.1,
                                ),
                                SizedBox(width: _horizontalPadding * 0.4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'نهاية نموذج تفاصيل الحادث',
                                        style: _smallStyle.copyWith(
                                          color: _accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: _verticalPadding * 0.2),
                                      Text(
                                        'اسحب لليسار للمتابعة',
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