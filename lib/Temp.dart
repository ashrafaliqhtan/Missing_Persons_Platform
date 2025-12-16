import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// استيراد مكتبات OpenStreetMap
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class NearbyMain extends StatefulWidget {
  const NearbyMain({super.key});

  @override
  State<NearbyMain> createState() => _NearbyMainState();
}

class _NearbyMainState extends State<NearbyMain> {
  final MapController _mapController = MapController();
  StreamSubscription<dynamic>? _locationSubscription;
  Query dbRef = FirebaseDatabase.instance.ref().child('Reports');
  final dbRef2 = FirebaseDatabase.instance.ref().child('Reports');
  final dbFoundRef = FirebaseDatabase.instance.ref().child('FoundPersons');
  final dbNotificationsRef = FirebaseDatabase.instance.ref().child('Notifications');
  
  late dynamic _reports = {};
  late dynamic _foundPersons = {};
  int timesWidgetBuilt = 0;
  latlong2.LatLng? sourceLocation;
  latlong2.LatLng? currentLocation;

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
  final Color _infoColor = Color(0xFF17A2B8);

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

  // متغيرات للتحكم في التحميل والأذونات
  bool? locationPermission;
  bool isPermitted = false;
  bool firstLoad = true;
  bool _isLoading = true;
  bool _isGeolocationSupported = true;
  bool _isTrackingLocation = false;
  bool _showFilters = false;
  bool _showSearch = false;
  bool _showFoundPersons = true;
  bool _showReports = true;
  StreamSubscription<html.Geoposition>? _locationWatchId;

  // متغيرات الفلترة والبحث
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTypes = [];
  List<String> _selectedCities = [];
  List<String> _selectedStatuses = [];
  String _selectedTimeRange = 'جميع الفترات';
  double _radiusFilter = 50.0; // كيلومتر

  // إحصائيات
  int _totalReports = 0;
  int _verifiedReports = 0;
  int _recentReports = 0;
  int _foundPersonsCount = 0;

  // قوائم الفلترة
  final List<String> _reportTypes = ['قاصر', 'ضحية جريمة', 'ضحية كارثة', 'أكثر من 24 ساعة'];
  final List<String> _timeRanges = ['جميع الفترات', 'آخر 24 ساعة', 'آخر أسبوع', 'آخر شهر'];
  
  // Image Picker
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _foundPersonImage;
  bool _isSubmittingFoundPerson = false;

  // Text Controllers for Found Person Form
  final TextEditingController _foundPersonNameController = TextEditingController();
  final TextEditingController _foundPersonAgeController = TextEditingController();
  final TextEditingController _foundPersonDescriptionController = TextEditingController();
  final TextEditingController _foundPersonLocationController = TextEditingController();
  final TextEditingController _foundPersonContactController = TextEditingController();

  // متغيرات جديدة للقوائم المنسدلة
  bool _showReportsDropdown = false;
  bool _showFoundPersonsDropdown = false;
  final LayerLink _reportsLayerLink = LayerLink();
  final LayerLink _foundPersonsLayerLink = LayerLink();
  OverlayEntry? _reportsOverlayEntry;
  OverlayEntry? _foundPersonsOverlayEntry;

  @override
  void initState() {
    super.initState();
    try {
      checkLocationPermission();
    } catch (e) {
      print('[nearby init] error: $e');
    }

    _fetchData();
    _fetchFoundPersons();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _searchController.dispose();
    _foundPersonNameController.dispose();
    _foundPersonAgeController.dispose();
    _foundPersonDescriptionController.dispose();
    _foundPersonLocationController.dispose();
    _foundPersonContactController.dispose();
    _removeOverlays();
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
    }
    super.dispose();
  }

  // إعداد مستمعين في الوقت الحقيقي
  void _setupRealtimeListeners() {
    dbRef2.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _reports = event.snapshot.value ?? {};
          _calculateStatistics();
        });
      }
    });

    dbFoundRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _foundPersons = event.snapshot.value ?? {};
          _foundPersonsCount = _countFoundPersons(_foundPersons);
        });
      }
    });
  }

  // دالة لتشخيص هيكل البيانات
  void _debugDataStructure() {
    print('=== تشخيص هيكل البيانات ===');
    
    if (_reports is Map) {
      print('عدد المستخدمين: ${_reports.length}');
      
      _reports.forEach((userId, userReports) {
        print('المستخدم: $userId');
        if (userReports is Map) {
          print('  عدد تقارير المستخدم: ${userReports.length}');
          userReports.forEach((reportId, report) {
            print('  التقرير: $reportId');
            if (report is Map) {
              final status = report['status'] ?? 'غير محدد';
              final firstName = report['p3_mp_firstName'] ?? 'غير معروف';
              final location = report['p5_lastSeenLoc'] ?? 'غير محدد';
              print('    الحالة: $status, الاسم: $firstName, الموقع: $location');
            }
          });
        }
      });
    } else {
      print('البيانات ليست بصيغة Map');
    }
    
    print('=== نهاية التشخيص ===');
  }

  int _countFoundPersons(dynamic foundPersons) {
    int count = 0;
    if (foundPersons is Map) {
      foundPersons.forEach((key, value) {
        if (value is Map) {
          count += value.length;
        }
      });
    }
    return count;
  }

  Future<void> _fetchData() async {
    try {
      final snapshot = await dbRef2.once();
      setState(() {
        _reports = snapshot.snapshot.value ?? {};
        _calculateStatistics();
        _isLoading = false;
      });
      print('[DATA FETCHED] بيانات التقارير تم تحميلها بنجاح');
    } catch (e) {
      print('[DATA FETCH ERROR] خطأ في تحميل البيانات: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFoundPersons() async {
    try {
      final snapshot = await dbFoundRef.once();
      setState(() {
        _foundPersons = snapshot.snapshot.value ?? {};
        _foundPersonsCount = _countFoundPersons(_foundPersons);
      });
      print('[FOUND PERSONS FETCHED] بيانات الأشخاص الموجودين تم تحميلها بنجاح');
    } catch (e) {
      print('[FOUND PERSONS FETCH ERROR] خطأ في تحميل البيانات: $e');
    }
  }

  void _calculateStatistics() {
    int total = 0;
    int verified = 0;
    int recent = 0;
    final now = DateTime.now();
    
    if (_reports is Map) {
      _reports.forEach((key, value) {
        if (value is Map) {
          value.forEach((key, value) {
            final report = value as Map<dynamic, dynamic>;
            total++;
            
            if (report['status'] == 'Verified') {
              verified++;
            }
            
            // حساب التقارير الحديثة (آخر 7 أيام)
            final reportDate = report['p5_reportDate'];
            if (reportDate != null) {
              try {
                final date = DateFormat('dd/MM/yyyy').parse(reportDate);
                if (now.difference(date).inDays <= 7) {
                  recent++;
                }
              } catch (e) {
                print('Error parsing date: $e');
              }
            }
          });
        }
      });
    }
    
    setState(() {
      _totalReports = total;
      _verifiedReports = verified;
      _recentReports = recent;
    });
  }

  void checkLocationPermission() async {
    if (kIsWeb) {
      // في الويب، نستخدم Geolocation API مباشرة
      _checkGeolocationSupport();
      setState(() {
        isPermitted = true;
        locationPermission = true;
      });
      _getCurrentLocationWeb();
    } else {
      // للأجهزة المحمولة
      bool toChange = await Permission.location.isDenied
          .then((value) => isPermitted = !value);
      
      if (isPermitted) {
        try {
          _getCurrentLocationMobile();
        } catch (e) {
          print('[nearby location] error: $e');
        }
      }
      
      if (firstLoad) {
        Future.delayed(const Duration(seconds: 1)).then((value) => setState(() {
              locationPermission = toChange;
              firstLoad = false;
            }));
      } else {
        setState(() {
          locationPermission = toChange;
        });
      }
    }
    print('location Permission: $locationPermission');
    print('isPermitted: $isPermitted');
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

  // دالة للحصول على الموقع في الويب
  Future<void> _getCurrentLocationWeb() async {
    if (!kIsWeb) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('طلب إذن الموقع من المتصفح...');
      
      final position = await _getPosition();
      
      final lat = position.coords?.latitude;
      final lng = position.coords?.longitude;

      if (lat == null || lng == null) {
        throw Exception("لم يتم الحصول على إحداثيات صالحة");
      }

      print('تم الحصول على الإحداثيات: $lat, $lng');

      final double latDouble = lat.toDouble();
      final double lngDouble = lng.toDouble();

      setState(() {
        currentLocation = latlong2.LatLng(latDouble, lngDouble);
        sourceLocation = currentLocation;
      });

      // بدء تتبع الموقع إذا كان مدعوماً
      if (_isGeolocationSupported) {
        _startLocationTrackingWeb();
      }

    } catch (e) {
      print('Error getting location in web: $e');
      _showLocationErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة للحصول على الموقع في الأجهزة المحمولة
  Future<void> _getCurrentLocationMobile() async {
    try {
      if (kIsWeb) return;
      
      // استخدام geolocator package للأجهزة المحمولة
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      
      setState(() {
        currentLocation = latlong2.LatLng(position.latitude, position.longitude);
        sourceLocation = currentLocation;
      });
      
      // بدء تتبع الموقع
      _locationSubscription = geolocator.Geolocator.getPositionStream(
        locationSettings: geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          distanceFilter: 10, // متر
        ),
      ).listen((geolocator.Position position) {
        if (mounted) {
          setState(() {
            currentLocation = latlong2.LatLng(position.latitude, position.longitude);
            sourceLocation = currentLocation;
          });
        }
      });
      
    } catch (e) {
      print('Error getting mobile location: $e');
      // استخدام موقع افتراضي في حالة الخطأ
      setState(() {
        currentLocation = latlong2.LatLng(24.7136, 46.6753); // الرياض
        sourceLocation = currentLocation;
      });
    }
  }

  // دالة مساعدة للتعامل مع Geolocation API في الويب
  Future<html.Geoposition> _getPosition() {
    final completer = Completer<html.Geoposition>();
    
    final geolocation = html.window.navigator.geolocation;
    
    geolocation?.getCurrentPosition(
      enableHighAccuracy: true,
    ).then(
      (html.Geoposition position) {
        print('تم الحصول على الموقع بنجاح');
        completer.complete(position);
      },
      onError: (error) {
        String errorMessage;
        switch (error.code) {
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
            errorMessage = 'حدث خطأ غير معروف: ${error.message}';
        }
        print('Geolocation error: $errorMessage');
        completer.completeError(Exception(errorMessage));
      },
    );
    
    return completer.future;
  }

  // بدء تتبع الموقع في الويب
  void _startLocationTrackingWeb() {
    if (!kIsWeb || !_isGeolocationSupported) return;

    final geolocation = html.window.navigator.geolocation;
    
    _locationWatchId = geolocation?.watchPosition(
      enableHighAccuracy: true,
    ).listen(
      (html.Geoposition position) {
        final lat = position.coords?.latitude;
        final lng = position.coords?.longitude;
        
        if (lat != null && lng != null) {
          if (mounted) {
            setState(() {
              currentLocation = latlong2.LatLng(lat.toDouble(), lng.toDouble());
              sourceLocation = currentLocation;
            });
          }
        }
      },
      onError: (error) {
        print('Location tracking error: ${error}');
      },
      cancelOnError: true,
    );
    
    setState(() {
      _isTrackingLocation = true;
    });
  }

  // إيقاف تتبع الموقع
  void _stopLocationTracking() {
    if (_locationWatchId != null) {
      _locationWatchId?.cancel();
      _locationWatchId = null;
    }
    
    if (_locationSubscription != null) {
      _locationSubscription?.cancel();
      _locationSubscription = null;
    }
    
    setState(() {
      _isTrackingLocation = false;
    });
  }

  void recenterToUser() {
    if (currentLocation != null) {
      _mapController.move(currentLocation!, 14.25);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  // استخراج الإحداثيات من النص - الإصدار المحسن
  List<double> extractDoubles(String input) {
    if (input.isEmpty) return [];
    
    print('استخراج الإحداثيات من: $input');
    
    try {
      // محاولة تقسيم النص باستخدام فواصل شائعة
      List<String> parts = [];
      
      if (input.contains(',')) {
        parts = input.split(',');
      } else if (input.contains(' ')) {
        parts = input.split(' ');
      } else if (input.contains(';')) {
        parts = input.split(';');
      }
      
      // تنظيف الأجزاء وإزالة المسافات الزائدة
      parts = parts.map((part) => part.trim()).toList();
      
      List<double> doubles = [];
      for (String part in parts) {
        try {
          // إزالة أي أحرف غير رقمية باستثناء النقطة والعلامة السالبة
          String cleanPart = part.replaceAll(RegExp(r'[^\d.-]'), '');
          if (cleanPart.isNotEmpty) {
            double value = double.parse(cleanPart);
            doubles.add(value);
          }
        } catch (e) {
          print('خطأ في تحويل الجزء: $part');
        }
      }
      
      print('الإحداثيات المستخرجة: $doubles');
      return doubles;
    } catch (e) {
      print('خطأ في استخراج الإحداثيات: $e');
      return [];
    }
  }

  // حساب المسافة بين نقطتين
  double _calculateDistance(latlong2.LatLng point1, latlong2.LatLng point2) {
    final latlong2.Distance distance = latlong2.Distance();
    return distance(point1, point2) / 1000; // تحويل إلى كيلومتر
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
          ],
        );
      },
    );
  }

  // ========== الوظائف الجديدة للقوائم المنسدلة ==========

  // إزالة القوائم المنسدلة
  void _removeOverlays() {
    _reportsOverlayEntry?.remove();
    _foundPersonsOverlayEntry?.remove();
    _reportsOverlayEntry = null;
    _foundPersonsOverlayEntry = null;
    setState(() {
      _showReportsDropdown = false;
      _showFoundPersonsDropdown = false;
    });
  }

  // عرض قائمة التقارير المنسدلة
  void _showReportsDropdownMenu() {
    _removeOverlays();
    
    _reportsOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width * 0.9,
        top: 150, // تعديل حسب موقع الزر في الهيدر
        left: MediaQuery.of(context).size.width * 0.05,
        child: CompositedTransformFollower(
          link: _reportsLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                children: [
                  // رأس القائمة
                  Container(
                    padding: EdgeInsets.all(_horizontalPadding * 0.6),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'قائمة التقارير (${_getFilteredReports().length})',
                            style: _bodyStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _removeOverlays,
                        ),
                      ],
                    ),
                  ),
                  
                  // محتوى القائمة
                  Expanded(
                    child: _buildReportsList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_reportsOverlayEntry!);
    setState(() {
      _showReportsDropdown = true;
    });
  }

  // عرض قائمة الأشخاص الموجودين المنسدلة
  void _showFoundPersonsDropdownMenu() {
    _removeOverlays();
    
    _foundPersonsOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width * 0.9,
        top: 150, // تعديل حسب موقع الزر في الهيدر
        left: MediaQuery.of(context).size.width * 0.05,
        child: CompositedTransformFollower(
          link: _foundPersonsLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                children: [
                  // رأس القائمة
                  Container(
                    padding: EdgeInsets.all(_horizontalPadding * 0.6),
                    decoration: BoxDecoration(
                      color: _successColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_search, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'قائمة الأشخاص الموجودين (${_getFilteredFoundPersons().length})',
                            style: _bodyStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _removeOverlays,
                        ),
                      ],
                    ),
                  ),
                  
                  // محتوى القائمة
                  Expanded(
                    child: _buildFoundPersonsList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_foundPersonsOverlayEntry!);
    setState(() {
      _showFoundPersonsDropdown = true;
    });
  }

  // بناء قائمة التقارير
  Widget _buildReportsList() {
    final filteredReports = _getFilteredReports();
    
    if (filteredReports.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(_horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 50, color: _hintColor),
              SizedBox(height: _verticalPadding),
              Text(
                'لا توجد تقارير متاحة',
                style: _bodyStyle.copyWith(color: _hintColor),
              ),
              Text(
                'جاري تحميل التقارير أو لا توجد تقارير تطابق الفلاتر',
                style: _smallStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        final firstName = report['p3_mp_firstName'] ?? '';
        final lastName = report['p3_mp_lastName'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        final location = report['p5_lastSeenLoc'] ?? '';
        final date = report['p5_reportDate'] ?? '';
        final status = report['status'] ?? '';
        final isVerified = status == 'Verified' || status == 'مؤكد';
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person_pin,
                  color: _accentColor,
                ),
              ),
              title: Text(
                fullName.isNotEmpty ? fullName : 'شخص مجهول',
                style: _bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: _bodyFontSize * 0.9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.isNotEmpty ? location : 'موقع غير معروف',
                    style: _smallStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (date.isNotEmpty)
                    Text(
                      'التاريخ: $date',
                      style: _smallStyle.copyWith(
                        fontSize: _smallFontSize * 0.8,
                        color: _hintColor,
                      ),
                    ),
                ],
              ),
              trailing: isVerified
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _successColor),
                      ),
                      child: Text(
                        'مؤكد',
                        style: _smallStyle.copyWith(
                          color: _successColor,
                          fontSize: _smallFontSize * 0.7,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                _removeOverlays();
                _showReportDetails(report, fullName.isNotEmpty ? fullName : 'شخص مجهول', 'report_$index');
              },
            ),
          ),
        );
      },
    );
  }

  // بناء قائمة الأشخاص الموجودين
  Widget _buildFoundPersonsList() {
    final filteredFoundPersons = _getFilteredFoundPersons();
    
    if (filteredFoundPersons.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(_horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search_outlined, size: 50, color: _hintColor),
              SizedBox(height: _verticalPadding),
              Text(
                'لا توجد أشخاص موجودين',
                style: _bodyStyle.copyWith(color: _hintColor),
              ),
              Text(
                'جاري تحميل البيانات أو لا توجد أشخاص تطابق الفلاتر',
                style: _smallStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredFoundPersons.length,
      itemBuilder: (context, index) {
        final foundPerson = filteredFoundPersons[index];
        final name = foundPerson['name'] ?? 'شخص مجهول';
        final location = foundPerson['locationName'] ?? foundPerson['location'] ?? '';
        final date = foundPerson['dateFound'] ?? '';
        final age = foundPerson['age'] ?? '';
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person_search,
                  color: _successColor,
                ),
              ),
              title: Text(
                name,
                style: _bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: _bodyFontSize * 0.9,
                  color: _successColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.isNotEmpty ? location : 'موقع غير معروف',
                    style: _smallStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (date.isNotEmpty)
                    Text(
                      'تم العثور: $date',
                      style: _smallStyle.copyWith(
                        fontSize: _smallFontSize * 0.8,
                        color: _hintColor,
                      ),
                    ),
                  if (age.isNotEmpty)
                    Text(
                      'العمر: $age سنة',
                      style: _smallStyle.copyWith(
                        fontSize: _smallFontSize * 0.8,
                        color: _hintColor,
                      ),
                    ),
                ],
              ),
              trailing: Icon(Icons.check_circle, color: _successColor),
              onTap: () {
                _removeOverlays();
                _showFoundPersonDetails(foundPerson, name, 'found_$index');
              },
            ),
          ),
        );
      },
    );
  }

  // الحصول على التقارير المفلترة
  List<Map<dynamic, dynamic>> _getFilteredReports() {
    List<Map<dynamic, dynamic>> filteredReports = [];
    
    if (_reports is Map) {
      _reports.forEach((userId, userReports) {
        if (userReports is Map) {
          userReports.forEach((reportId, reportData) {
            if (reportData is Map) {
              final report = Map<dynamic, dynamic>.from(reportData);
              if (_passesFilters(report)) {
                filteredReports.add(report);
              }
            }
          });
        }
      });
    }
    
    return filteredReports;
  }

  // الحصول على الأشخاص الموجودين المفلترين
  List<Map<dynamic, dynamic>> _getFilteredFoundPersons() {
    List<Map<dynamic, dynamic>> filteredFoundPersons = [];
    
    if (_foundPersons is Map) {
      _foundPersons.forEach((userId, userFoundPersons) {
        if (userFoundPersons is Map) {
          userFoundPersons.forEach((foundId, foundData) {
            if (foundData is Map) {
              final foundPerson = Map<dynamic, dynamic>.from(foundData);
              if (_passesFoundPersonFilters(foundPerson)) {
                filteredFoundPersons.add(foundPerson);
              }
            }
          });
        }
      });
    }
    
    return filteredFoundPersons;
  }

  // ========== نهاية الوظائف الجديدة ==========

  // دالة مساعدة لبناء زر
  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPrimary = true,
    bool isEnabled = true,
    double? width,
    bool isLoading = false,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? (isPrimary ? _primaryColor : _cardColor),
          foregroundColor: textColor ?? (isPrimary ? Colors.white : _primaryColor),
          padding: EdgeInsets.symmetric(vertical: _verticalPadding * 0.8, horizontal: _horizontalPadding * 0.6),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: _bodyFontSize * 0.9),
                    SizedBox(width: _horizontalPadding * 0.3),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: _bodyStyle.copyWith(
                        color: textColor ?? (isPrimary ? Colors.white : _primaryColor),
                        fontSize: _bodyFontSize * 0.9,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // دالة مساعدة لبناء بطاقة معلومات
  Widget _buildInfoCard(String message, {Color? color, IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(_horizontalPadding * 0.6),
        decoration: BoxDecoration(
          color: color ?? _accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? _accentColor).withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? Icons.info_outline_rounded, size: _bodyFontSize * 1.2, color: color ?? _accentColor),
            SizedBox(width: _horizontalPadding * 0.4),
            Expanded(
              child: Text(
                message,
                style: _smallStyle.copyWith(
                  color: color ?? _accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء بطاقة الإحصائيات
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: _bodyStyle.copyWith(
                fontSize: _bodyFontSize * 1.1,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              title,
              style: _smallStyle.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmail(var pnp_contactEmail) {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: pnp_contactEmail,
      queryParameters: {'subject': 'Report\tInformation\tUpdate'},
    );
    launchUrl(emailLaunchUri);
  }

  // دالة مشاركة التقرير
  void _shareReport(String reportId, String name) {
    final String shareText = 'تفاصيل تقرير عن $name - تطبيق Missing_Persons_Platform';
    final String shareUrl = 'https://yourapp.com/reports/$reportId';
    
    _shareContent(shareText, shareUrl);
  }

  // دالة مشاركة المحتوى
  void _shareContent(String text, String url) {
    if (kIsWeb) {
      // استخدام Web Share API بشكل صحيح
      if (html.window.navigator.share != null) {
        html.window.navigator.share!({
          "title": "تطبيق Missing_Persons_Platform",
          "text": text,
          "url": url,
        });
      } else {
        // إذا Web Share API غير مدعوم، نستخدم نسخ الرابط
        _copyToClipboard('$text\n$url');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نسخ الرابط إلى الحافظة', style: _bodyStyle.copyWith(color: Colors.white)),
            backgroundColor: _successColor,
          ),
        );
      }
    } else {
      // للأجهزة المحمولة - نسخ الرابط
      _copyToClipboard('$text\n$url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ الرابط إلى الحافظة', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _successColor,
        ),
      );
    }
  }

  // دالة نسخ النص إلى الحافظة
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
    });
    _fetchData();
    _fetchFoundPersons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header محسّن
            Container(
              padding: EdgeInsets.all(_horizontalPadding * 0.8),
              decoration: BoxDecoration(
                color: _cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.map_outlined, color: _primaryColor, size: _titleFontSize * 0.8),
                      SizedBox(width: _horizontalPadding * 0.4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الخرائط التفاعلية',
                              style: _titleStyle.copyWith(fontSize: _titleFontSize * 0.8),
                            ),
                            Text(
                              'عرض التقارير والأشخاص الموجودين بالقرب منك',
                              style: _smallStyle.copyWith(
                                color: _hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // أزرار التحكم
                      Row(
                        children: [
                          _buildIconButton(
                            Icons.refresh,
                            'تحديث',
                            _refreshData,
                            color: _infoColor,
                          ),
                          SizedBox(width: 8),
                          _buildIconButton(
                            _showSearch ? Icons.close : Icons.search,
                            'بحث',
                            () => setState(() => _showSearch = !_showSearch),
                            color: _infoColor,
                          ),
                          SizedBox(width: 8),
                          _buildIconButton(
                            _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
                            'فلاتر',
                            () => setState(() => _showFilters = !_showFilters),
                            color: _infoColor,
                          ),
                          if (kIsWeb) SizedBox(width: 8),
                          if (kIsWeb) _buildWebLocationInfo(),
                        ],
                      ),
                    ],
                  ),
                  
                  // شريط البحث
                  if (_showSearch) ...[
                    SizedBox(height: _verticalPadding),
                    _buildSearchBar(),
                  ],
                  
                  // الفلاتر
                  if (_showFilters) ...[
                    SizedBox(height: _verticalPadding),
                    _buildFiltersPanel(),
                  ],
                  
                  // إحصائيات سريعة
                  SizedBox(height: _verticalPadding),
                  _buildStatisticsRow(),

                  // تبديل عرض التقارير والأشخاص الموجودين + أزرار القوائم المنسدلة
                  SizedBox(height: _verticalPadding * 0.5),
                  _buildToggleButtonsWithDropdowns(),
                ],
              ),
            ),
            
            // محتوى رئيسي
            Expanded(
              child: locationPermission != null
                  ? !locationPermission!
                      ? _buildNoPermissionView()
                      : (_reports.isEmpty || _reports == null || _isLoading)
                          ? _buildLoadingView()
                          : _buildMapView()
                  : _buildLoadingView(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  // بناء زر أيقونة صغير
  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onPressed, {Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? _primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color ?? _primaryColor),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.all(6),
        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  // بناء شريط البحث
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، المدينة، أو الوصف...',
                hintStyle: _smallStyle,
                border: InputBorder.none,
                icon: Icon(Icons.search, color: _hintColor),
              ),
              style: _bodyStyle,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: _hintColor),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  // بناء لوحة الفلاتر
  Widget _buildFiltersPanel() {
    return Container(
      padding: EdgeInsets.all(_horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الفلاتر', style: _headingStyle),
          SizedBox(height: _verticalPadding * 0.5),
          
          // فلترة النوع
          Text('نوع التقرير:', style: _bodyStyle.copyWith(fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _reportTypes.map((type) {
              final isSelected = _selectedTypes.contains(type);
              return FilterChip(
                label: Text(type, style: _smallStyle),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                },
                backgroundColor: _cardColor,
                selectedColor: _primaryColor.withOpacity(0.2),
                checkmarkColor: _primaryColor,
              );
            }).toList(),
          ),
          
          SizedBox(height: _verticalPadding * 0.5),
          
          // فلترة نصف القطر
          Text('نصف القطر: ${_radiusFilter.round()} كم', style: _bodyStyle.copyWith(fontWeight: FontWeight.w600)),
          Slider(
            value: _radiusFilter,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _radiusFilter = value;
              });
            },
            activeColor: _primaryColor,
            inactiveColor: _borderColor,
          ),
          
          SizedBox(height: _verticalPadding * 0.5),
          
          // أزرار التحكم
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  text: 'تطبيق الفلاتر',
                  onPressed: () {
                    setState(() {});
                  },
                  isPrimary: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildButton(
                  text: 'إعادة تعيين',
                  onPressed: () {
                    setState(() {
                      _selectedTypes.clear();
                      _radiusFilter = 50.0;
                      _searchController.clear();
                    });
                  },
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء صف الإحصائيات
  Widget _buildStatisticsRow() {
    return Row(
      children: [
        _buildStatCard('التقارير', _totalReports.toString(), _primaryColor, Icons.assignment),
        _buildStatCard('مؤكدة', _verifiedReports.toString(), _successColor, Icons.verified),
        _buildStatCard('حديثة', _recentReports.toString(), _infoColor, Icons.new_releases),
        _buildStatCard('موجودين', _foundPersonsCount.toString(), _warningColor, Icons.person_search),
      ],
    );
  }

  // بناء أزرار التبديل مع القوائم المنسدلة
  Widget _buildToggleButtonsWithDropdowns() {
    return Row(
      children: [
        // زر التقارير مع القائمة المنسدلة
        Expanded(
          child: CompositedTransformTarget(
            link: _reportsLayerLink,
            child: _buildDropdownButton(
              'التقارير',
              _showReports,
              Icons.assignment,
              _showReportsDropdown,
              () {
                if (_showReportsDropdown) {
                  _removeOverlays();
                } else {
                  _showReportsDropdownMenu();
                }
              },
              () => setState(() => _showReports = !_showReports),
            ),
          ),
        ),
        SizedBox(width: 8),
        // زر الأشخاص الموجودين مع القائمة المنسدلة
        Expanded(
          child: CompositedTransformTarget(
            link: _foundPersonsLayerLink,
            child: _buildDropdownButton(
              'الأشخاص الموجودين',
              _showFoundPersons,
              Icons.person_search,
              _showFoundPersonsDropdown,
              () {
                if (_showFoundPersonsDropdown) {
                  _removeOverlays();
                } else {
                  _showFoundPersonsDropdownMenu();
                }
              },
              () => setState(() => _showFoundPersons = !_showFoundPersons),
            ),
          ),
        ),
      ],
    );
  }

  // بناء زر مع قائمة منسدلة
  Widget _buildDropdownButton(
    String text,
    bool isActive,
    IconData icon,
    bool isDropdownOpen,
    VoidCallback onDropdownTap,
    VoidCallback onToggleTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _primaryColor : _borderColor,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isDropdownOpen)
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // زر التبديل الأساسي
          ListTile(
            dense: true,
            leading: Icon(
              icon,
              size: 20,
              color: isActive ? _primaryColor : _hintColor,
            ),
            title: Text(
              text,
              style: _smallStyle.copyWith(
                color: isActive ? _primaryColor : _hintColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isActive ? _primaryColor : _hintColor,
                ),
                Icon(
                  isActive ? Icons.visibility : Icons.visibility_off,
                  size: 16,
                  color: isActive ? _primaryColor : _hintColor,
                ),
              ],
            ),
            onTap: onToggleTap,
          ),
          
          // زر القائمة المنسدلة المنفصل
          Container(
            height: 32,
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
              ),
              onPressed: onDropdownTap,
              child: Text(
                'عرض القائمة',
                style: _smallStyle.copyWith(
                  fontSize: _smallFontSize * 0.8,
                  color: isActive ? _primaryColor : _hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء واجهة عدم وجود إذن
  Widget _buildNoPermissionView() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * .75,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              lottie.Lottie.asset("assets/lottie/noLocation.json",
                  animate: true,
                  width: MediaQuery.of(context).size.width * 0.9),
              const SizedBox(height: 10),
              Text('الوصول إلى الموقع غير مفعل',
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                '\nهذا التطبيق يتطلب الوصول إلى موقعك لعرض التقارير المؤكدة على الخريطة بالقرب منك.',
                textScaleFactor: 0.8,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text.rich(
                textAlign: TextAlign.center,
                textScaleFactor: 0.8,
                TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                        text:
                            'تأكد من تفعيل إذن الموقع وأنه '),
                    TextSpan(
                      text: 'مضبوط على الدقة العالية',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              _buildButton(
                text: 'الذهاب إلى إعدادات التطبيق',
                onPressed: () {
                  openAppSettings();
                },
                isPrimary: true,
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء واجهة التحميل
  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
            child: Text('جاري تحميل الخرائط...',
                style: _bodyStyle.copyWith(
                    fontWeight: FontWeight.w500))),
        const SizedBox(height: 10),
        Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 15.0),
            child: Text(
              'جاري تحميل أحدث التقارير...',
              textAlign: TextAlign.center,
              style: _smallStyle,
            ),
          ),
        ),
        Center(
          child: SpinKitCubeGrid(
            color: _primaryColor,
            size: 25.0,
          ),
        )
      ],
    );
  }

  // بناء واجهة الخريطة
  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentLocation ?? latlong2.LatLng(24.7136, 46.6753),
            initialZoom: 14.25,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              print('الخريطة جاهزة للاستخدام');
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.Missing_Persons_Platform',
            ),
            MarkerLayer(
              markers: _buildFilteredMarkers(),
            ),
            if (currentLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentLocation!,
                    color: _primaryColor.withOpacity(0.3),
                    borderColor: _primaryColor,
                    borderStrokeWidth: 2,
                    radius: 20,
                  ),
                ],
              ),
            // دائرة نصف القطر
            if (currentLocation != null && _radiusFilter < 100)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentLocation!,
                    color: _primaryColor.withOpacity(0.1),
                    borderColor: _primaryColor,
                    borderStrokeWidth: 1,
                    radius: _radiusFilter * 1000, // تحويل كم إلى متر
                  ),
                ],
              ),
          ],
        ),
        
        // أزرار التحكم في الخريطة
        Positioned(
          bottom: _verticalPadding * 2,
          left: _horizontalPadding,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoomIn',
                backgroundColor: _primaryColor,
                elevation: 30,
                onPressed: _zoomIn,
                mini: true,
                child: Icon(Icons.add, color: Colors.white),
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoomOut',
                backgroundColor: _primaryColor,
                elevation: 30,
                onPressed: _zoomOut,
                mini: true,
                child: Icon(Icons.remove, color: Colors.white),
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'nearbyMain',
                backgroundColor: _primaryColor,
                elevation: 30,
                onPressed: recenterToUser,
                child: Icon(Icons.my_location, color: Colors.white),
              ),
            ],
          ),
        ),
        
        // معلومات التتبع
        if (_isTrackingLocation)
          Positioned(
            top: _verticalPadding,
            left: _horizontalPadding,
            right: _horizontalPadding,
            child: _buildInfoCard(
              'جاري تتبع موقعك...',
              color: _successColor,
              icon: Icons.location_searching,
            ),
          ),
        
        // زر التحكم في التتبع
        if (kIsWeb && _isGeolocationSupported)
          Positioned(
            top: _verticalPadding,
            right: _horizontalPadding,
            child: FloatingActionButton(
              heroTag: 'trackingToggle',
              backgroundColor: _isTrackingLocation ? _accentColor : _primaryColor,
              elevation: 20,
              onPressed: () {
                if (_isTrackingLocation) {
                  _stopLocationTracking();
                } else {
                  _startLocationTrackingWeb();
                }
              },
              mini: true,
              child: Icon(
                _isTrackingLocation ? Icons.location_off : Icons.location_searching,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

        // زر التشخيص (للتطوير فقط)
     //   if (kDebugMode) _buildDebugButton(),
      ],
    );
  }

  // بناء أزرار العائمة الإضافية
  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // زر الإبلاغ عن شخص موجود
        FloatingActionButton(
          heroTag: 'foundPerson',
          backgroundColor: _successColor,
          elevation: 20,
          onPressed: () {
            _showFoundPersonForm();
          },
          child: Icon(Icons.person_add, color: Colors.white),
        ),
        SizedBox(height: 8),
        // زر المشاركة
        FloatingActionButton(
          heroTag: 'share',
          backgroundColor: _infoColor,
          elevation: 20,
          onPressed: () {
            _showShareDialog();
          },
          mini: true,
          child: Icon(Icons.share, color: Colors.white),
        ),
        SizedBox(height: 8),
        // زر المساعدة
        FloatingActionButton(
          heroTag: 'help',
          backgroundColor: _warningColor,
          elevation: 20,
          onPressed: () {
            _showHelpDialog();
          },
          mini: true,
          child: Icon(Icons.help, color: Colors.white),
        ),
      ],
    );
  }

  // بناء العلامات مع الفلترة
  List<Marker> _buildFilteredMarkers() {
    final List<Marker> markers = [];
    
    print('=== بدء بناء العلامات ===');
    print('عرض التقارير: $_showReports');
    print('عرض الأشخاص الموجودين: $_showFoundPersons');
    
    // إضافة علامة الموقع الحالي
    if (currentLocation != null) {
      markers.add(
        Marker(
          point: currentLocation!,
          width: 40.0,
          height: 40.0,
          child: Icon(
            Icons.location_on,
            color: _primaryColor,
            size: 40,
          ),
        ),
      );
    }
    
    // إضافة علامات التقارير مع الفلترة
    if (_showReports && _reports is Map) {
      int reportCount = 0;
      int displayedCount = 0;
      
      _reports.forEach((userId, userReports) {
        if (userReports is Map) {
          userReports.forEach((reportId, reportData) {
            reportCount++;
            
            if (reportData is Map) {
              final report = Map<dynamic, dynamic>.from(reportData);
              
              // التحقق من الحالة والفلترة
              final status = report['status']?.toString() ?? '';
              final isVerified = status == 'Verified' || status == 'مؤكد' || status == 'مفعل';
              
              if ((isVerified || status.isEmpty) && _passesFilters(report)) {
                try {
                  final firstName = report['p3_mp_firstName'] ?? '';
                  final lastName = report['p3_mp_lastName'] ?? '';
                  final fullName = '$firstName $lastName'.trim();
                  final reportID = '${userId}_$reportId';
                  final location = report['p5_lastSeenLoc']?.toString() ?? '';
                  
                  print('معالجة التقرير: $fullName, الموقع: $location');
                  
                  if (location.isNotEmpty) {
                    final coordinates = extractDoubles(location);
                    
                    if (coordinates.length >= 2) {
                      final reportLocation = latlong2.LatLng(coordinates[0], coordinates[1]);
                      
                      // التحقق من المسافة إذا كان هناك فلترة بنصف قطر
                      bool withinRadius = true;
                      if (currentLocation != null && _radiusFilter < 100) {
                        final distance = _calculateDistance(currentLocation!, reportLocation);
                        withinRadius = distance <= _radiusFilter;
                        print('المسافة: ${distance.toStringAsFixed(2)} كم, ضمن النطاق: $withinRadius');
                      }
                      
                      if (withinRadius) {
                        final marker = Marker(
                          point: reportLocation,
                          width: 40.0,
                          height: 40.0,
                          child: GestureDetector(
                            onTap: () {
                              _showReportDetails(report, fullName.isNotEmpty ? fullName : 'شخص مجهول', reportID);
                            },
                            child: _buildCustomMarker(report, isFoundPerson: false),
                          ),
                        );
                        markers.add(marker);
                        displayedCount++;
                      }
                    } else {
                      print('إحداثيات غير صالحة: $coordinates');
                    }
                  } else {
                    print('لا يوجد موقع للتقرير');
                  }
                } catch (e) {
                  print('[خطأ في معالجة التقرير] $e');
                }
              }
            }
          });
        }
      });
      
      print('إجمالي التقارير: $reportCount, المعروض: $displayedCount');
    }
    
    // إضافة علامات الأشخاص الموجودين
    if (_showFoundPersons && _foundPersons is Map) {
      int foundCount = 0;
      int displayedFoundCount = 0;
      
      _foundPersons.forEach((userId, userFoundPersons) {
        if (userFoundPersons is Map) {
          userFoundPersons.forEach((foundId, foundData) {
            foundCount++;
            
            if (foundData is Map) {
              final foundPerson = Map<dynamic, dynamic>.from(foundData);
              
              if (_passesFoundPersonFilters(foundPerson)) {
                try {
                  final name = foundPerson['name'] ?? 'شخص مجهول';
                  final location = foundPerson['location']?.toString() ?? '';
                  
                  print('معالجة شخص موجود: $name, الموقع: $location');
                  
                  if (location.isNotEmpty) {
                    final coordinates = extractDoubles(location);
                    
                    if (coordinates.length >= 2) {
                      final foundPersonLocation = latlong2.LatLng(coordinates[0], coordinates[1]);
                      
                      // التحقق من المسافة
                      bool withinRadius = true;
                      if (currentLocation != null && _radiusFilter < 100) {
                        final distance = _calculateDistance(currentLocation!, foundPersonLocation);
                        withinRadius = distance <= _radiusFilter;
                      }
                      
                      if (withinRadius) {
                        final marker = Marker(
                          point: foundPersonLocation,
                          width: 40.0,
                          height: 40.0,
                          child: GestureDetector(
                            onTap: () {
                              _showFoundPersonDetails(foundPerson, name, '${userId}_$foundId');
                            },
                            child: _buildCustomMarker(foundPerson, isFoundPerson: true),
                          ),
                        );
                        markers.add(marker);
                        displayedFoundCount++;
                      }
                    }
                  }
                } catch (e) {
                  print('[خطأ في معالجة الشخص الموجود] $e');
                }
              }
            }
          });
        }
      });
      
      print('إجمالي الأشخاص الموجودين: $foundCount, المعروض: $displayedFoundCount');
    }
    
    print('إجمالي العلامات على الخريطة: ${markers.length}');
    print('=== انتهاء بناء العلامات ===');
    
    return markers;
  }

  // بناء علامة مخصصة بناءً على نوع التقرير
  Widget _buildCustomMarker(Map<dynamic, dynamic> data, {required bool isFoundPerson}) {
    Color markerColor;
    IconData markerIcon;
    String tooltip;
    
    if (isFoundPerson) {
      markerColor = _successColor; // أخضر للأشخاص الموجودين
      markerIcon = Icons.person_search;
      tooltip = 'شخص موجود';
    } else {
      bool minor = data['p1_isMinor'] ?? false;
      bool crime = data['p1_isVictimCrime'] ?? false;
      bool calamity = data['p1_isVictimNaturalCalamity'] ?? false;
      
      markerColor = _accentColor; // أحمر للأشخاص المفقودين
      markerIcon = Icons.person_pin;
      tooltip = 'شخص مفقود';
      
      if (minor) {
        markerColor = Colors.redAccent;
        markerIcon = Icons.child_care;
        tooltip = 'قاصر مفقود';
      } else if (crime) {
        markerColor = Colors.deepPurple;
        markerIcon = Icons.security;
        tooltip = 'ضحية جريمة';
      } else if (calamity) {
        markerColor = Colors.orangeAccent;
        markerIcon = Icons.warning;
        tooltip = 'ضحية كارثة';
      }
    }
    
    return Tooltip(
      message: tooltip,
      child: Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_pin,
              color: markerColor,
              size: 35,
            ),
            Icon(
              markerIcon,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // التحقق من مرور التقرير عبر الفلاتر - الإصدار الأكثر مرونة
  bool _passesFilters(Map<dynamic, dynamic> report) {
    // إذا لم يكن هناك تقرير، تخطى
    if (report.isEmpty) return false;
    
    // فلترة النص
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      final firstName = (report['p3_mp_firstName'] ?? '').toString().toLowerCase();
      final lastName = (report['p3_mp_lastName'] ?? '').toString().toLowerCase();
      final city = (report['p5_cityName'] ?? '').toString().toLowerCase();
      final description = (report['p5_incidentDetails'] ?? '').toString().toLowerCase();
      final nickname = (report['p3_mp_nickname'] ?? '').toString().toLowerCase();
      
      bool matchesSearch = firstName.contains(searchText) ||
          lastName.contains(searchText) ||
          city.contains(searchText) ||
          description.contains(searchText) ||
          nickname.contains(searchText);
      
      if (!matchesSearch) {
        return false;
      }
    }
    
    // فلترة النوع - أكثر مرونة
    if (_selectedTypes.isNotEmpty) {
      bool hasSelectedType = false;
      
      // قاصر
      if (_selectedTypes.contains('قاصر')) {
        final isMinor = report['p1_isMinor'] ?? false;
        final age = int.tryParse(report['p3_mp_age']?.toString() ?? '') ?? 0;
        if (isMinor == true || age < 18) {
          hasSelectedType = true;
        }
      }
      
      // ضحية جريمة
      if (_selectedTypes.contains('ضحية جريمة') && !hasSelectedType) {
        final isCrime = report['p1_isVictimCrime'] ?? false;
        if (isCrime == true) {
          hasSelectedType = true;
        }
      }
      
      // ضحية كارثة
      if (_selectedTypes.contains('ضحية كارثة') && !hasSelectedType) {
        final isCalamity = report['p1_isVictimNaturalCalamity'] ?? false;
        if (isCalamity == true) {
          hasSelectedType = true;
        }
      }
      
      // أكثر من 24 ساعة
      if (_selectedTypes.contains('أكثر من 24 ساعة') && !hasSelectedType) {
        final isOver24 = report['p1_isMissing24Hours'] ?? false;
        if (isOver24 == true) {
          hasSelectedType = true;
        }
      }
      
      if (!hasSelectedType) {
        return false;
      }
    }
    
    return true;
  }

  // التحقق من مرور الشخص الموجود عبر الفلاتر
  bool _passesFoundPersonFilters(Map<dynamic, dynamic> foundPerson) {
    // فلترة النص
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      final name = (foundPerson['name'] ?? '').toString().toLowerCase();
      final description = (foundPerson['description'] ?? '').toString().toLowerCase();
      final location = (foundPerson['locationName'] ?? '').toString().toLowerCase();
      
      if (!name.contains(searchText) &&
          !description.contains(searchText) &&
          !location.contains(searchText)) {
        return false;
      }
    }
    
    return true;
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('مشاركة التطبيق', style: _headingStyle),
          content: Text(
            'ساعد في نشر التطبيق لمساعدة المزيد من الأشخاص. شارك الرابط مع أصدقائك وعائلتك.',
            style: _bodyStyle,
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: _bodyStyle),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareApp();
              },
              child: Text('مشاركة', style: _bodyStyle.copyWith(color: _primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(_horizontalPadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('دليل استخدام الخرائط', style: _headingStyle.copyWith(fontSize: _titleFontSize * 0.7)),
                  SizedBox(height: _verticalPadding),
                  
                  _buildHelpItem(Icons.location_on, 'الموقع الحالي', 'يظهر موقعك الحالي بدائرة زرقاء'),
                  _buildHelpItem(Icons.location_pin, 'التقارير', 'كل علامة حمراء تمثل تقرير مؤكد'),
                  _buildHelpItem(Icons.person_search, 'الأشخاص الموجودين', 'كل علامة خضراء تمثل شخص تم العثور عليه'),
                  _buildHelpItem(Icons.filter_alt, 'الفلاتر', 'استخدم الفلاتر لتصفية التقارير حسب النوع والمسافة'),
                  _buildHelpItem(Icons.search, 'البحث', 'ابحث بالاسم، المدينة، أو وصف الحادث'),
                  _buildHelpItem(Icons.person_add, 'الإبلاغ', 'أبلغ عن شخص موجود لمساعدة الآخرين'),
                  _buildHelpItem(Icons.share, 'المشاركة', 'شارك التقارير المهمة مع الآخرين'),
                  
                  SizedBox(height: _verticalPadding),
                  _buildButton(
                    text: 'فهمت',
                    onPressed: () => Navigator.of(context).pop(),
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding * 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _bodyStyle.copyWith(fontWeight: FontWeight.w600)),
                Text(description, style: _smallStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    final String shareText = 'تطبيق Missing_Persons_Platform - نظام الإبلاغ عن المفقودين والمساعدة في حالات الطوارئ';
    final String shareUrl = 'https://yourapp.com';
    
    _shareContent(shareText, shareUrl);
  }

  // بناء معلومات الموقع للويب
  Widget _buildWebLocationInfo() {
    if (kIsWeb) {
      final isSupported = _isGeolocationSupported;
      
      return Container(
        padding: EdgeInsets.all(_horizontalPadding * 0.4),
        decoration: BoxDecoration(
          color: isSupported ? _primaryColor.withOpacity(0.1) : _warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSupported ? _primaryColor.withOpacity(0.3) : _warningColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSupported ? Icons.location_on : Icons.warning,
              size: 16,
              color: isSupported ? _primaryColor : _warningColor,
            ),
            SizedBox(width: 4),
            Text(
              isSupported ? 'OpenStreetMap' : 'تحذير',
              style: _smallStyle.copyWith(
                color: isSupported ? _primaryColor : _warningColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  // دالة عرض تفاصيل التقرير
  void _showReportDetails(Map<dynamic, dynamic> report, String name, String reportID) {
    // استخراج البيانات من التقرير
    final firstName = report['p3_mp_firstName'] ?? '';
    final lastName = report['p3_mp_lastName'] ?? '';
    final description = report['p5_incidentDetails'] ?? '';
    final dateReported = report['p5_reportDate'] ?? '';
    final lastSeenLoc = report['p5_nearestLandmark'] ?? '';
    final pnp_contactNumber = report['pnp_contactNumber'] ?? '';
    final pnp_contactEmail = report['pnp_contactEmail'] ?? '';
    final mp_recentPhoto_LINK = report['mp_recentPhoto_LINK'];
    final heightFeet = report['p4_mp_height_inches'] ?? '';
    final heightInches = report['p4_mp_height_feet'] ?? '';
    final sex = report['p3_mp_sex'] ?? '';
    final age = report['p3_mp_age'] ?? '';
    final weight = report['p4_mp_weight'] ?? '';
    final scars = report['p4_mp_scars'] ?? '';
    final marks = report['p4_mp_marks'] ?? '';
    final tattoos = report['p4_mp_tattoos'] ?? '';
    final hairColor = report['p4_mp_hair_color'] ?? '';
    final eyeColor = report['p4_mp_eye_color'] ?? '';
    final prosthetics = report['p4_mp_prosthetics'] ?? '';
    final birthDefects = report['p4_mp_birth_defects'] ?? '';
    final clothingAccessories = report['p4_mp_last_clothing'] ?? '';
    final lastSeenDate = report['p5_lastSeenDate'] ?? '';
    final lastSeenTime = report['p5_lastSeenTime'] ?? '';
    final cityName = report['p5_cityName'] ?? '';
    final placeName = report['p5_placeName'] ?? '';

    bool minor = report['p1_isMinor'] ?? false;
    bool crime = report['p1_isVictimCrime'] ?? false;
    bool calamity = report['p1_isVictimNaturalCalamity'] ?? false;
    bool over24Hours = report['p1_isMissing24Hours'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          snap: true,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Header قابل للسحب
                  Container(
                    margin: EdgeInsets.all(_verticalPadding),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _hintColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // عنوان البطاقة مع زر المشاركة
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                    child: Row(
                      children: [
                        Icon(Icons.report_problem, color: _primaryColor),
                        SizedBox(width: _horizontalPadding * 0.4),
                        Expanded(
                          child: Text(
                            'تفاصيل التقرير',
                            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.1),
                          ),
                        ),
                        // زر الإبلاغ عن وجود الشخص
                        _buildIconButton(
                          Icons.person_add,
                          'الإبلاغ عن وجود هذا الشخص',
                          () => _showFoundPersonFromReport(report),
                          color: _successColor,
                        ),
                        SizedBox(width: 8),
                        // زر المشاركة
                        _buildIconButton(
                          Icons.share,
                          'مشاركة التقرير',
                          () => _shareReport(reportID, '$firstName $lastName'),
                          color: _infoColor,
                        ),
                        SizedBox(width: 8),
                        // زر الإغلاق
                        _buildIconButton(
                          Icons.close,
                          'إغلاق',
                          () => Navigator.of(context).pop(),
                          color: _hintColor,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: _verticalPadding),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: EdgeInsets.all(_horizontalPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // معلومات الأساسية
                            _buildInfoSection(
                              title: 'المعلومات الأساسية',
                              children: [
                                Row(
                                  children: [
                                    // صورة الملف الشخصي
                                    if (mp_recentPhoto_LINK != null && mp_recentPhoto_LINK.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          _showImageDialog(mp_recentPhoto_LINK);
                                        },
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: _borderColor),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  mp_recentPhoto_LINK,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: _hintColor.withOpacity(0.1),
                                                      child: Icon(Icons.person, color: _hintColor, size: 40),
                                                    );
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      color: _hintColor.withOpacity(0.1),
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(Icons.search_outlined, size: 12, color: _primaryColor),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: _hintColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _borderColor),
                                        ),
                                        child: Icon(Icons.person, color: _hintColor, size: 40),
                                      ),
                                    
                                    SizedBox(width: _horizontalPadding * 0.6),
                                    
                                    // المعلومات الأساسية
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$firstName $lastName',
                                            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.2),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: _verticalPadding * 0.2),
                                          Text(
                                            'تم التبليغ: $dateReported',
                                            style: _smallStyle,
                                          ),
                                          if (cityName.isNotEmpty) ...[
                                            SizedBox(height: _verticalPadding * 0.1),
                                            Text(
                                              'المدينة: $cityName',
                                              style: _smallStyle,
                                            ),
                                          ],
                                          
                                          // العلامات
                                          if (minor || crime || calamity || over24Hours) ...[
                                            SizedBox(height: _verticalPadding * 0.3),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: [
                                                if (crime)
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      color: Colors.deepPurple,
                                                    ),
                                                    child: Text(
                                                      'ضحية جريمة',
                                                      style: _smallStyle.copyWith(
                                                        color: Colors.white,
                                                        fontSize: _smallFontSize * 0.8,
                                                      ),
                                                    ),
                                                  ),
                                                if (calamity)
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      color: Colors.orangeAccent,
                                                    ),
                                                    child: Text(
                                                      'ضحية كارثة',
                                                      style: _smallStyle.copyWith(
                                                        color: Colors.white,
                                                        fontSize: _smallFontSize * 0.8,
                                                      ),
                                                    ),
                                                  ),
                                                if (over24Hours)
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      color: Colors.green,
                                                    ),
                                                    child: Text(
                                                      'أكثر من 24 ساعة',
                                                      style: _smallStyle.copyWith(
                                                        color: Colors.white,
                                                        fontSize: _smallFontSize * 0.8,
                                                      ),
                                                    ),
                                                  ),
                                                if (minor)
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      color: Colors.redAccent,
                                                    ),
                                                    child: Text(
                                                      'قاصر',
                                                      style: _smallStyle.copyWith(
                                                        color: Colors.white,
                                                        fontSize: _smallFontSize * 0.8,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            SizedBox(height: _verticalPadding),
                            
                            // آخر مشاهدة
                            _buildInfoSection(
                              title: 'آخر مشاهدة',
                              children: [
                                _buildInfoRow('التاريخ', lastSeenDate),
                                _buildInfoRow('الوقت', lastSeenTime),
                                if (placeName.isNotEmpty) _buildInfoRow('اسم المكان', placeName),
                                _buildInfoRow('المكان', lastSeenLoc),
                                if (cityName.isNotEmpty) _buildInfoRow('المدينة', cityName),
                              ],
                            ),
                            
                            SizedBox(height: _verticalPadding),
                            
                            // الوصف الجسدي
                            _buildInfoSection(
                              title: 'الوصف الجسدي',
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoRow('الطول', "$heightFeet'$heightInches")),
                                    SizedBox(width: _horizontalPadding * 0.3),
                                    Expanded(child: _buildInfoRow('الوزن', '$weight كجم')),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoRow('الجنس', sex)),
                                    SizedBox(width: _horizontalPadding * 0.3),
                                    Expanded(child: _buildInfoRow('العمر', '$age سنة')),
                                  ],
                                ),
                                if (scars.isNotEmpty) _buildInfoRow('الندوب', scars),
                                if (marks.isNotEmpty) _buildInfoRow('العلامات', marks),
                                if (tattoos.isNotEmpty) _buildInfoRow('الوشوم', tattoos),
                                if (hairColor.isNotEmpty) _buildInfoRow('لون الشعر', hairColor),
                                if (eyeColor.isNotEmpty) _buildInfoRow('لون العينين', eyeColor),
                                if (prosthetics.isNotEmpty) _buildInfoRow('الأطراف الاصطناعية', prosthetics),
                                if (birthDefects.isNotEmpty) _buildInfoRow('العيوب الخلقية', birthDefects),
                                if (clothingAccessories.isNotEmpty) _buildInfoRow('الملابس والإكسسوارات', clothingAccessories),
                              ],
                            ),
                            
                            SizedBox(height: _verticalPadding),
                            
                            // تفاصيل الحادث
                            _buildInfoSection(
                              title: 'تفاصيل الحادث',
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(_horizontalPadding * 0.6),
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: Text(
                                    description.isNotEmpty ? description : 'لا توجد تفاصيل إضافية',
                                    style: _bodyStyle.copyWith(fontSize: _bodyFontSize * 0.9),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: _verticalPadding),
                            
                            // جهات الاتصال
                            _buildInfoSection(
                              title: 'جهات الاتصال',
                              children: [
                                _buildInfoCard(
                                  'إذا كان لديك أي معلومات عن هذا الشخص، يرجى الاتصال بالشرطة فوراً',
                                  color: _primaryColor,
                                  icon: Icons.warning_amber_outlined,
                                ),
                                SizedBox(height: _verticalPadding * 0.5),
                                
                                // معلومات الاتصال
                                if (pnp_contactNumber.isNotEmpty || pnp_contactEmail.isNotEmpty) ...[
                                  if (pnp_contactNumber.isNotEmpty)
                                    _buildContactInfo('رقم الهاتف', pnp_contactNumber, Icons.phone),
                                  if (pnp_contactEmail.isNotEmpty)
                                    _buildContactInfo('البريد الإلكتروني', pnp_contactEmail, Icons.email),
                                  SizedBox(height: _verticalPadding * 0.5),
                                ],
                                
                                Row(
                                  children: [
                                    if (pnp_contactNumber.isNotEmpty)
                                      Expanded(
                                        child: _buildButton(
                                          text: 'اتصال بالشرطة',
                                          onPressed: () async {
                                            await _callPolice(pnp_contactNumber);
                                          },
                                          icon: Icons.phone,
                                        ),
                                      ),
                                    if (pnp_contactNumber.isNotEmpty && pnp_contactEmail.isNotEmpty)
                                      SizedBox(width: _horizontalPadding * 0.3),
                                    if (pnp_contactEmail.isNotEmpty)
                                      Expanded(
                                        child: _buildButton(
                                          text: 'إرسال بريد إلكتروني',
                                          onPressed: () {
                                            _sendEmail(pnp_contactEmail);
                                          },
                                          isPrimary: false,
                                          icon: Icons.email,
                                        ),
                                      ),
                                  ],
                                ),
                                
                                // زر نسخ المعلومات
                                SizedBox(height: _verticalPadding * 0.5),
                                _buildButton(
                                  text: 'نسخ معلومات التقرير',
                                  onPressed: () {
                                    _copyReportInfo(report, name);
                                  },
                                  isPrimary: false,
                                  icon: Icons.content_copy,
                                ),
                              ],
                            ),
                            
                            SizedBox(height: MediaQuery.of(context).padding.bottom + _verticalPadding),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // دالة لعرض تفاصيل الشخص الموجود
  void _showFoundPersonDetails(Map<dynamic, dynamic> foundPerson, String name, String foundPersonID) {
    final description = foundPerson['description'] ?? '';
    final dateFound = foundPerson['dateFound'] ?? '';
    final location = foundPerson['locationName'] ?? '';
    final contact = foundPerson['contact'] ?? '';
    final imageUrl = foundPerson['imageUrl'];
    final age = foundPerson['age'] ?? '';
    final condition = foundPerson['condition'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          snap: true,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Header قابل للسحب
                  Container(
                    margin: EdgeInsets.all(_verticalPadding),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _hintColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // عنوان البطاقة
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                    child: Row(
                      children: [
                        Icon(Icons.person_search, color: _successColor),
                        SizedBox(width: _horizontalPadding * 0.4),
                        Expanded(
                          child: Text(
                            'شخص تم العثور عليه',
                            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.1, color: _successColor),
                          ),
                        ),
                        // زر المشاركة
                        _buildIconButton(
                          Icons.share,
                          'مشاركة',
                          () => _shareFoundPerson(foundPersonID, name),
                          color: _infoColor,
                        ),
                        SizedBox(width: 8),
                        // زر الإغلاق
                        _buildIconButton(
                          Icons.close,
                          'إغلاق',
                          () => Navigator.of(context).pop(),
                          color: _hintColor,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: _verticalPadding),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: EdgeInsets.all(_horizontalPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // معلومات الأساسية
                            _buildInfoSection(
                              title: 'المعلومات الأساسية',
                              children: [
                                Row(
                                  children: [
                                    // صورة الشخص
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          _showImageDialog(imageUrl);
                                        },
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: _borderColor),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: _hintColor.withOpacity(0.1),
                                                      child: Icon(Icons.person, color: _hintColor, size: 40),
                                                    );
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      color: _hintColor.withOpacity(0.1),
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(Icons.search_outlined, size: 12, color: _successColor),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: _hintColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _borderColor),
                                        ),
                                        child: Icon(Icons.person, color: _hintColor, size: 40),
                                      ),
                                    
                                    SizedBox(width: _horizontalPadding * 0.6),
                                    
                                    // المعلومات الأساسية
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.2, color: _successColor),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: _verticalPadding * 0.2),
                                          Text(
                                            'تم العثور عليه: $dateFound',
                                            style: _smallStyle,
                                          ),
                                          if (age.isNotEmpty) ...[
                                            SizedBox(height: _verticalPadding * 0.1),
                                            Text(
                                              'العمر التقريبي: $age سنة',
                                              style: _smallStyle,
                                            ),
                                          ],
                                          if (condition.isNotEmpty) ...[
                                            SizedBox(height: _verticalPadding * 0.1),
                                            Text(
                                              'الحالة: $condition',
                                              style: _smallStyle,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            SizedBox(height: _verticalPadding),
                            
                            // موقع العثور
                            _buildInfoSection(
                              title: 'موقع العثور',
                              children: [
                                _buildInfoRow('المكان', location),
                                _buildInfoRow('التاريخ', dateFound),
                              ],
                            ),
                            
                            SizedBox(height: _verticalPadding),
                            
                            // الوصف
                            _buildInfoSection(
                              title: 'الوصف',
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(_horizontalPadding * 0.6),
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: Text(
                                    description.isNotEmpty ? description : 'لا توجد تفاصيل إضافية',
                                    style: _bodyStyle.copyWith(fontSize: _bodyFontSize * 0.9),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: _verticalPadding),
                            
                            // جهات الاتصال
                            _buildInfoSection(
                              title: 'جهات الاتصال',
                              children: [
                                _buildInfoCard(
                                  'إذا كنت تعرف هذا الشخص أو تحتاج إلى معلومات إضافية',
                                  color: _successColor,
                                  icon: Icons.info_outline,
                                ),
                                SizedBox(height: _verticalPadding * 0.5),
                                
                                if (contact.isNotEmpty) ...[
                                  _buildContactInfo('جهة الاتصال', contact, Icons.contact_phone),
                                  SizedBox(height: _verticalPadding * 0.5),
                                ],
                                
                                _buildButton(
                                  text: 'الاتصال بالسلطات',
                                  onPressed: () {
                                    _contactAuthorities();
                                  },
                                  icon: Icons.security,
                                ),
                              ],
                            ),
                            
                            SizedBox(height: MediaQuery.of(context).padding.bottom + _verticalPadding),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // دالة مشاركة الشخص الموجود
  void _shareFoundPerson(String foundPersonID, String name) {
    final String shareText = 'شخص تم العثور عليه - $name - تطبيق Missing_Persons_Platform';
    final String shareUrl = 'https://yourapp.com/found/$foundPersonID';
    
    _shareContent(shareText, shareUrl);
  }

  // دالة لعرض نموذج الإبلاغ عن شخص موجود
  void _showFoundPersonForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Header قابل للسحب
                  Container(
                    margin: EdgeInsets.all(_verticalPadding),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _hintColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // عنوان النموذج
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                    child: Row(
                      children: [
                        Icon(Icons.person_add, color: _successColor),
                        SizedBox(width: _horizontalPadding * 0.4),
                        Expanded(
                          child: Text(
                            'الإبلاغ عن شخص موجود',
                            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.1, color: _successColor),
                          ),
                        ),
                        _buildIconButton(
                          Icons.close,
                          'إغلاق',
                          () => Navigator.of(context).pop(),
                          color: _hintColor,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: _verticalPadding),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(_horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(
                            'يرجى تقديم معلومات دقيقة عن الشخص الموجود لمساعدة أسرته وأحبائه في العثور عليه.',
                            color: _successColor,
                            icon: Icons.info_outline,
                          ),
                          
                          SizedBox(height: _verticalPadding),
                          
                          // صورة الشخص
                          _buildImageUploadSection(setState),
                          
                          SizedBox(height: _verticalPadding),
                          
                          // معلومات الشخص
                          _buildInfoSection(
                            title: 'معلومات الشخص',
                            children: [
                              _buildFormField(
                                controller: _foundPersonNameController,
                                label: 'اسم الشخص (إن أمكن)',
                                hint: 'أدخل اسم الشخص إذا كان معروفاً',
                              ),
                              _buildFormField(
                                controller: _foundPersonAgeController,
                                label: 'العمر التقريبي',
                                hint: 'أدخل العمر التقريبي',
                                keyboardType: TextInputType.number,
                              ),
                              _buildFormField(
                                controller: _foundPersonDescriptionController,
                                label: 'الوصف',
                                hint: 'صف حالة الشخص، ملابسه، وأي معلومات أخرى',
                                maxLines: 4,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: _verticalPadding),
                          
                          // موقع العثور
                          _buildInfoSection(
                            title: 'موقع العثور',
                            children: [
                              _buildFormField(
                                controller: _foundPersonLocationController,
                                label: 'موقع العثور',
                                hint: 'أدخل العنوان أو المكان الذي تم العثور فيه على الشخص',
                              ),
                              SizedBox(height: _verticalPadding * 0.5),
                              _buildButton(
                                text: 'استخدام موقعي الحالي',
                                onPressed: () {
                                  if (currentLocation != null) {
                                    _foundPersonLocationController.text = 
                                        '${currentLocation!.latitude}, ${currentLocation!.longitude}';
                                    setState(() {});
                                  }
                                },
                                isPrimary: false,
                                icon: Icons.my_location,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: _verticalPadding),
                          
                          // معلومات الاتصال
                          _buildInfoSection(
                            title: 'معلومات الاتصال',
                            children: [
                              _buildFormField(
                                controller: _foundPersonContactController,
                                label: 'رقم الاتصال',
                                hint: 'أدخل رقم هاتف للتواصل',
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: _verticalPadding * 0.5),
                              _buildInfoCard(
                                'سيتم استخدام معلومات الاتصال للتواصل معك في حالة الحاجة لمزيد من المعلومات',
                                color: _infoColor,
                                icon: Icons.phone,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: _verticalPadding),
                          
                          // زر الإرسال
                          _buildButton(
                            text: 'إرسال التقرير',
                            onPressed: _isSubmittingFoundPerson ? null : () => _submitFoundPersonReport(setState),
                            isLoading: _isSubmittingFoundPerson,
                            icon: Icons.send,
                          ),
                          
                          SizedBox(height: MediaQuery.of(context).padding.bottom + _verticalPadding),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // بناء قسم رفع الصورة
  Widget _buildImageUploadSection(StateSetter setState) {
    return _buildInfoSection(
      title: 'صورة الشخص',
      children: [
        GestureDetector(
          onTap: () => _pickFoundPersonImage(setState),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _foundPersonImage != null ? _successColor : _borderColor,
                width: _foundPersonImage != null ? 2 : 1,
              ),
            ),
            child: _foundPersonImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _foundPersonImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50, color: _hintColor),
                      SizedBox(height: _verticalPadding * 0.5),
                      Text('انقر لاختيار صورة', style: _bodyStyle.copyWith(color: _hintColor)),
                      Text('(اختياري)', style: _smallStyle.copyWith(color: _hintColor)),
                    ],
                  ),
          ),
        ),
        if (_foundPersonImage != null) ...[
          SizedBox(height: _verticalPadding * 0.5),
          _buildButton(
            text: 'إزالة الصورة',
            onPressed: () {
              setState(() {
                _foundPersonImage = null;
              });
            },
            isPrimary: false,
            icon: Icons.delete,
          ),
        ],
      ],
    );
  }

  // بناء حقل النموذج
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: _bodyFontSize * 0.9,
            ),
          ),
          SizedBox(height: _verticalPadding * 0.2),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _smallStyle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              filled: true,
              fillColor: _cardColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _horizontalPadding * 0.6,
                vertical: _verticalPadding * 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // اختيار صورة الشخص الموجود
  Future<void> _pickFoundPersonImage(StateSetter setState) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _foundPersonImage = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في اختيار الصورة', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  // إرسال تقرير الشخص الموجود
  Future<void> _submitFoundPersonReport(StateSetter setState) async {
    if (_foundPersonNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال اسم الشخص', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _errorColor,
        ),
      );
      return;
    }

    if (_foundPersonLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال موقع العثور', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingFoundPerson = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      String? imageUrl;
      if (_foundPersonImage != null) {
        // رفع الصورة إلى Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('found_persons')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        final uploadTask = storageRef.putData(
          _foundPersonImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        await uploadTask.whenComplete(() {});
        imageUrl = await storageRef.getDownloadURL();
      }

      // حفظ البيانات في Firebase
      final foundPersonData = {
        'name': _foundPersonNameController.text,
        'age': _foundPersonAgeController.text,
        'description': _foundPersonDescriptionController.text,
        'location': _foundPersonLocationController.text,
        'locationName': _foundPersonLocationController.text, // يمكن تحسين هذا لاستخدام Geocoding
        'contact': _foundPersonContactController.text,
        'imageUrl': imageUrl,
        'dateFound': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'reportedBy': user.uid,
        'reportedAt': ServerValue.timestamp,
        'status': 'active',
      };

      await dbFoundRef.child(user.uid).push().set(foundPersonData);

      // إرسال إشعارات للمستخدمين المهتمين
      await _sendFoundPersonNotifications(foundPersonData);

      // إعادة تعيين النموذج
      _resetFoundPersonForm(setState);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال التقرير بنجاح', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _successColor,
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      print('Error submitting found person report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في إرسال التقرير', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingFoundPerson = false;
      });
    }
  }

  // إعادة تعيين نموذج الشخص الموجود
  void _resetFoundPersonForm(StateSetter setState) {
    _foundPersonNameController.clear();
    _foundPersonAgeController.clear();
    _foundPersonDescriptionController.clear();
    _foundPersonLocationController.clear();
    _foundPersonContactController.clear();
    setState(() {
      _foundPersonImage = null;
    });
  }

  // إرسال إشعارات عند العثور على شخص
  Future<void> _sendFoundPersonNotifications(Map<String, dynamic> foundPersonData) async {
    try {
      // هنا يمكن إضافة منطق إرسال الإشعارات للمستخدمين المهتمين
      // أو للجهات المختصة
      
      final notificationData = {
        'type': 'found_person',
        'title': 'تم الإبلاغ عن شخص موجود',
        'message': 'تم الإبلاغ عن شخص باسم ${foundPersonData['name']}',
        'data': foundPersonData,
        'timestamp': ServerValue.timestamp,
      };

      await dbNotificationsRef.push().set(notificationData);

      print('تم إرسال الإشعارات بنجاح');
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  // عرض نموذج الإبلاغ عن شخص موجود من تقرير
  void _showFoundPersonFromReport(Map<dynamic, dynamic> report) {
    final firstName = report['p3_mp_firstName'] ?? '';
    final lastName = report['p3_mp_lastName'] ?? '';
    final age = report['p3_mp_age'] ?? '';
    
    _foundPersonNameController.text = '$firstName $lastName';
    if (age.isNotEmpty) {
      _foundPersonAgeController.text = age;
    }
    
    _showFoundPersonForm();
  }

  // دالة لعرض الصورة في dialog
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Stack(
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: InteractiveViewer(
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.1,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _hintColor.withOpacity(0.1),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: _hintColor, size: 50),
                              SizedBox(height: 10),
                              Text('تعذر تحميل الصورة', style: _bodyStyle),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: _hintColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.download, color: Colors.white),
                    onPressed: () {
                      _downloadImage(imageUrl);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // دالة لتحميل الصورة
  void _downloadImage(String imageUrl) {
    // في الويب، نفتح الصورة في تبويب جديد للتحميل
    if (kIsWeb) {
      html.window.open(imageUrl, '_blank');
    } else {
      // للأجهزة المحمولة، يمكن استخدام package مثل image_downloader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري تحميل الصورة...', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _infoColor,
        ),
      );
    }
  }

  // دالة للاتصال بالشرطة
  Future<void> _callPolice(String phoneNumber) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await FlutterPhoneDirectCaller.callNumber(phoneNumber);
      } else {
        final url = Uri.parse('tel:$phoneNumber');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      print('Error calling police: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر الاتصال بالرقم: $phoneNumber', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  // دالة للاتصال بالسلطات
  Future<void> _contactAuthorities() async {
    const emergencyNumber = '911'; // رقم الطوارئ
    await _callPolice(emergencyNumber);
  }

  // دالة لنسخ معلومات التقرير
  void _copyReportInfo(Map<dynamic, dynamic> report, String name) {
    final firstName = report['p3_mp_firstName'] ?? '';
    final lastName = report['p3_mp_lastName'] ?? '';
    final description = report['p5_incidentDetails'] ?? '';
    final lastSeenDate = report['p5_lastSeenDate'] ?? '';
    final lastSeenTime = report['p5_lastSeenTime'] ?? '';
    final lastSeenLoc = report['p5_nearestLandmark'] ?? '';
    final age = report['p3_mp_age'] ?? '';
    final sex = report['p3_mp_sex'] ?? '';
    
    String reportInfo = '''
معلومات التقرير - تطبيق Missing_Persons_Platform

الاسم: $firstName $lastName
العمر: $age سنة
الجنس: $sex
آخر مشاهدة: $lastSeenDate - $lastSeenTime
المكان: $lastSeenLoc

تفاصيل الحادث:
$description

يرجى التواصل مع الشرطة إذا كان لديك أي معلومات.
''';

    _copyToClipboard(reportInfo);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ معلومات التقرير إلى الحافظة', style: _bodyStyle.copyWith(color: Colors.white)),
        backgroundColor: _successColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // دالة لبناء معلومات الاتصال
  Widget _buildContactInfo(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding * 0.3),
      padding: EdgeInsets.all(_horizontalPadding * 0.5),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primaryColor),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _smallStyle.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                SelectableText(
                  value,
                  style: _bodyStyle.copyWith(fontSize: _bodyFontSize * 0.8),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.content_copy, size: 16),
            onPressed: () {
              _copyToClipboard(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم نسخ $title إلى الحافظة', style: _smallStyle.copyWith(color: Colors.white)),
                  backgroundColor: _successColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء قسم المعلومات
  Widget _buildInfoSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding * 0.8),
      decoration: BoxDecoration(
        color: _cardColor,
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
            style: _headingStyle.copyWith(fontSize: _bodyFontSize),
          ),
          SizedBox(height: _verticalPadding * 0.5),
          ...children,
        ],
      ),
    );
  }

  // دالة مساعدة لبناء صف معلومات
  Widget _buildInfoRow(String label, String value) {
    final textStyle = _bodyStyle.copyWith(fontSize: _bodyFontSize * 0.9);

    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: _hintColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: _horizontalPadding * 0.3),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'غير متوفر',
              style: textStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}