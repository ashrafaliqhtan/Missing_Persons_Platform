import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:latlong2/latlong.dart' as latlong2;

class ReportsDashboard extends StatefulWidget {
  const ReportsDashboard({super.key});

  @override
  State<ReportsDashboard> createState() => _ReportsDashboardState();
}

class _ReportsDashboardState extends State<ReportsDashboard> {
  // مراجع قاعدة البيانات
  final DatabaseReference _reportsRef = FirebaseDatabase.instance.ref().child('Reports');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('Users');
  
  // بيانات التقارير
  Map<dynamic, dynamic> _allReports = {};
  List<Map<String, dynamic>> _filteredReports = [];
  
  // حالة التحميل
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  // متغيرات الفلترة والبحث
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'الكل';
  String _sortBy = 'الأحدث';
  
  // قوائم الفلترة
  final List<String> _statusList = ['الكل', 'معلّق', 'مفعل', 'مرفوض', 'تم العثور'];
  final List<String> _sortOptions = ['الأحدث', 'الأقدم', 'اسم العائلة', 'المسافة'];
  
  // موقع الشرطة
  latlong2.LatLng? _policeLocation;
  
  // ألوان التطبيق
  final Color _primaryColor = Color(0xFF006400); // أخضر داكن
  final Color _accentColor = Color(0xFFCE1126); // أحمر
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _successColor = Color(0xFF28A745);
  final Color _warningColor = Color(0xFFFFC107);
  final Color _errorColor = Color(0xFFDC3545);
  final Color _infoColor = Color(0xFF17A2B8);

  // أحجام خطوط متجاوبة
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.055;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.04;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.035;
  
  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // تهيئة لوحة التحكم
  Future<void> _initializeDashboard() async {
    await _getPoliceLocation();
    await _loadReports();
    _setupRealtimeListener();
  }

  // الحصول على موقع الشرطة
  Future<void> _getPoliceLocation() async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      setState(() {
        _policeLocation = latlong2.LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('خطأ في الحصول على موقع الشرطة: $e');
      // استخدام موقع افتراضي
      setState(() {
        _policeLocation = latlong2.LatLng(24.7136, 46.6753); // الرياض
      });
    }
  }

  // تحميل التقارير من Firebase
  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final snapshot = await _reportsRef.once();
      final data = snapshot.snapshot.value;

      if (data != null && data is Map) {
        setState(() {
          _allReports = data;
          _applyFilters();
        });
      }
    } catch (e) {
      print('خطأ في تحميل التقارير: $e');
      _showErrorSnackBar('فشل في تحميل التقارير');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // إعداد مستمع في الوقت الحقيقي
  void _setupRealtimeListener() {
    _reportsRef.onValue.listen((event) {
      if (mounted) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          setState(() {
            _allReports = data;
            _applyFilters();
          });
        }
      }
    });
  }

  // تطبيق الفلترة والبحث
  void _applyFilters() {
    List<Map<String, dynamic>> allReportsList = [];

    // تحويل البيانات إلى قائمة
    _allReports.forEach((userId, userReports) {
      if (userReports is Map) {
        userReports.forEach((reportId, reportData) {
          if (reportData is Map) {
            final report = Map<String, dynamic>.from(reportData);
            report['userId'] = userId;
            report['reportId'] = reportId;
            allReportsList.add(report);
          }
        });
      }
    });

    // تطبيق فلترة البحث
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      allReportsList = allReportsList.where((report) {
        final firstName = (report['p3_mp_firstName'] ?? '').toString().toLowerCase();
        final lastName = (report['p3_mp_lastName'] ?? '').toString().toLowerCase();
        final nickname = (report['p3_mp_nickname'] ?? '').toString().toLowerCase();
        
        return firstName.contains(searchText) ||
               lastName.contains(searchText) ||
               nickname.contains(searchText);
      }).toList();
    }

    // تطبيق فلترة الحالة
    if (_selectedStatus != 'الكل') {
      allReportsList = allReportsList.where((report) {
        final status = report['status'] ?? 'معلّق';
        return _mapStatusToArabic(status) == _selectedStatus;
      }).toList();
    }

    // تطبيق الترتيب
    _sortReports(allReportsList);
  }

  // ترتيب التقارير
  void _sortReports(List<Map<String, dynamic>> reports) {
    switch (_sortBy) {
      case 'الأحدث':
        reports.sort((a, b) {
          final dateA = _parseDate(a['p5_reportDate'] ?? '');
          final dateB = _parseDate(b['p5_reportDate'] ?? '');
          return dateB.compareTo(dateA);
        });
        break;
      case 'الأقدم':
        reports.sort((a, b) {
          final dateA = _parseDate(a['p5_reportDate'] ?? '');
          final dateB = _parseDate(b['p5_reportDate'] ?? '');
          return dateA.compareTo(dateB);
        });
        break;
      case 'اسم العائلة':
        reports.sort((a, b) {
          final lastNameA = (a['p3_mp_lastName'] ?? '').toString();
          final lastNameB = (b['p3_mp_lastName'] ?? '').toString();
          return lastNameA.compareTo(lastNameB);
        });
        break;
      case 'المسافة':
        if (_policeLocation != null) {
          reports.sort((a, b) {
            final distanceA = _calculateDistance(a);
            final distanceB = _calculateDistance(b);
            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }

    setState(() {
      _filteredReports = reports;
    });
  }

  // تحويل الحالة إلى العربية
  String _mapStatusToArabic(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'معلّق':
        return 'معلّق';
      case 'verified':
      case 'مفعل':
        return 'مفعل';
      case 'rejected':
      case 'مرفوض':
        return 'مرفوض';
      case 'found':
      case 'تم العثور':
        return 'تم العثور';
      default:
        return 'معلّق';
    }
  }


// في ملف reports_dashboard.dart - إضافة دالة لتحويل الحالة بشكل متسق
String _getConsistentStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'معلّق':
      return 'pending';
    case 'verified':
    case 'مفعل':
    case 'مؤكد':
      return 'verified'; // استخدام 'verified' بشكل متسق
    case 'rejected':
    case 'مرفوض':
      return 'rejected';
    case 'found':
    case 'تم العثور':
      return 'found';
    default:
      return 'pending';
  }
}

// ثم تحديث دالة تحديث الحالة





  // تحويل الحالة إلى الإنجليزية
  String _mapStatusToEnglish(String arabicStatus) {
    switch (arabicStatus) {
      case 'معلّق':
        return 'pending';
      case 'مفعل':
        return 'verified';
      case 'مرفوض':
        return 'rejected';
      case 'تم العثور':
        return 'found';
      default:
        return 'pending';
    }
  }

  // حساب المسافة بين موقع الشرطة وموقع الاختفاء
  double _calculateDistance(Map<String, dynamic> report) {
    if (_policeLocation == null) return 0.0;

    try {
      final location = report['p5_lastSeenLoc']?.toString() ?? '';
      if (location.isEmpty) return 0.0;

      final coordinates = _extractCoordinates(location);
      if (coordinates.length >= 2) {
        final reportLocation = latlong2.LatLng(coordinates[0], coordinates[1]);
        final distance = geolocator.Geolocator.distanceBetween(
          _policeLocation!.latitude,
          _policeLocation!.longitude,
          reportLocation.latitude,
          reportLocation.longitude,
        );
        return distance / 1000; // تحويل إلى كيلومتر
      }
    } catch (e) {
      print('خطأ في حساب المسافة: $e');
    }
    
    return 0.0;
  }

  // استخراج الإحداثيات من النص
  List<double> _extractCoordinates(String input) {
    try {
      List<String> parts = [];
      if (input.contains(',')) {
        parts = input.split(',');
      } else if (input.contains(' ')) {
        parts = input.split(' ');
      }

      List<double> coordinates = [];
      for (String part in parts) {
        final cleanPart = part.trim().replaceAll(RegExp(r'[^\d.-]'), '');
        if (cleanPart.isNotEmpty) {
          coordinates.add(double.parse(cleanPart));
        }
      }
      return coordinates;
    } catch (e) {
      return [];
    }
  }

  // تحليل التاريخ
  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  // تحديث حالة التقرير
  Future<void> _updateReportStatus(
  String userId, 
  String reportId, 
  String newStatus,
  {String? rejectionReason,
  String? foundDate}
) async {
  try {
    final consistentStatus = _getConsistentStatus(newStatus);
    
    final updates = {
      'status': consistentStatus, // استخدام القيمة المتسقة
      'updatedAt': ServerValue.timestamp,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    };

    if (rejectionReason != null) {
      updates['rejectionReason'] = rejectionReason;
    }

    if (foundDate != null) {
      updates['foundDate'] = foundDate;
    }

    await _reportsRef.child(userId).child(reportId).update(updates);
    
    _showSuccessSnackBar('تم تحديث حالة التقرير بنجاح');
  } catch (e) {
    print('خطأ في تحديث حالة التقرير: $e');
    _showErrorSnackBar('فشل في تحديث حالة التقرير');
  }
}

  // عرض نافذة تفاصيل التقرير
  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildReportDetailsSheet(report);
      },
    );
  }

  // بناء بطاقة التقرير
  Widget _buildReportCard(Map<String, dynamic> report) {
    final firstName = report['p3_mp_firstName'] ?? '';
    final lastName = report['p3_mp_lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final location = report['p5_lastSeenLoc'] ?? '';
    final date = report['p5_reportDate'] ?? '';
    final status = _mapStatusToArabic(report['status'] ?? 'معلّق');
    final imageUrl = report['mp_recentPhoto_LINK'];
    final isMinor = report['p1_isMinor'] ?? false;
    final isCrime = report['p1_isVictimCrime'] ?? false;
    final isCalamity = report['p1_isVictimNaturalCalamity'] ?? false;
    final distance = _calculateDistance(report);

    // حساب الساعات الإجمالية للمفقود
    final missingHours = _calculateMissingHours(report);

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة الشخص
                  _buildPersonImage(imageUrl),
                  
                  SizedBox(width: 12),
                  
                  // المعلومات الأساسية
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : 'شخص مجهول',
                          style: TextStyle(
                            fontSize: _bodyFontSize,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: 4),
                        
                        // حالة التقرير
                        _buildStatusBadge(status),
                        
                        SizedBox(height: 4),
                        
                        // الموقع والمسافة
                        if (location.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: _hintColor),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: _smallFontSize,
                                    color: _hintColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                        ],
                        
                        if (distance > 0) ...[
                          Text(
                            'المسافة: ${distance.toStringAsFixed(1)} كم',
                            style: TextStyle(
                              fontSize: _smallFontSize * 0.9,
                              color: _infoColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // العلامات التصنيفية
              if (isMinor || isCrime || isCalamity) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (isMinor)
                      _buildTag('قاصر', Colors.redAccent),
                    if (isCrime)
                      _buildTag('ضحية جريمة', Colors.deepPurple),
                    if (isCalamity)
                      _buildTag('ضحية كارثة', Colors.orange),
                  ],
                ),
                SizedBox(height: 8),
              ],
              
              // المعلومات الزمنية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الاختفاء',
                        style: TextStyle(
                          fontSize: _smallFontSize * 0.9,
                          color: _hintColor,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: _smallFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الساعات الإجمالية',
                        style: TextStyle(
                          fontSize: _smallFontSize * 0.9,
                          color: _hintColor,
                        ),
                      ),
                      Text(
                        '$missingHours ساعة',
                        style: TextStyle(
                          fontSize: _smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: _warningColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // زر تغيير الحالة
              _buildStatusDropdown(report),
            ],
          ),
        ),
      ),
    );
  }

  // بناء صورة الشخص
  Widget _buildPersonImage(String? imageUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  // بناء صورة بديلة
  Widget _buildPlaceholderImage() {
    return Container(
      color: _backgroundColor,
      child: Icon(
        Icons.person,
        color: _hintColor,
        size: 30,
      ),
    );
  }

  // بناء علامة الحالة
  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case 'مفعل':
        backgroundColor = _successColor.withOpacity(0.1);
        textColor = _successColor;
        break;
      case 'مرفوض':
        backgroundColor = _errorColor.withOpacity(0.1);
        textColor = _errorColor;
        break;
      case 'تم العثور':
        backgroundColor = _infoColor.withOpacity(0.1);
        textColor = _infoColor;
        break;
      default:
        backgroundColor = _warningColor.withOpacity(0.1);
        textColor = _warningColor;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: _smallFontSize * 0.8,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // بناء علامة تصنيف
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: _smallFontSize * 0.8,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // بناء قائمة تغيير الحالة
  Widget _buildStatusDropdown(Map<String, dynamic> report) {
    final currentStatus = _mapStatusToArabic(report['status'] ?? 'معلّق');
    final userId = report['userId'];
    final reportId = report['reportId'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButton<String>(
        value: currentStatus,
        isExpanded: true,
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
        items: _statusList.map((String status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Text(
              status,
              style: TextStyle(
                fontSize: _smallFontSize,
                color: _textColor,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newStatus) {
          if (newStatus != null && newStatus != currentStatus) {
            _handleStatusChange(userId, reportId, newStatus, report);
          }
        },
      ),
    );
  }

  // التعامل مع تغيير الحالة
  void _handleStatusChange(
    String userId, 
    String reportId, 
    String newStatus, 
    Map<String, dynamic> report
  ) {
    if (newStatus == 'مرفوض') {
      _showRejectionDialog(userId, reportId);
    } else if (newStatus == 'تم العثور') {
      _showFoundDialog(userId, reportId);
    } else {
      _updateReportStatus(userId, reportId, newStatus);
    }
  }

  // عرض نافذة إدخال أسباب الرفض
  void _showRejectionDialog(String userId, String reportId) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('رفض التقرير', style: _headingStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('يرجى إدخال سبب الرفض:', style: _bodyStyle),
              SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أدخل سبب رفض التقرير...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: _bodyStyle),
            ),
            TextButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _updateReportStatus(
                    userId, 
                    reportId, 
                    'مرفوض',
                    rejectionReason: reasonController.text.trim()
                  );
                } else {
                  _showErrorSnackBar('يرجى إدخال سبب الرفض');
                }
              },
              child: Text('تأكيد', style: _bodyStyle.copyWith(color: _errorColor)),
            ),
          ],
        );
      },
    );
  }

  // عرض نافذة تسجيل تاريخ العثور
  void _showFoundDialog(String userId, String reportId) {
    final TextEditingController dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now())
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تسجيل العثور على الشخص', style: _headingStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تاريخ العثور على الشخص:', style: _bodyStyle),
              SizedBox(height: 12),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  hintText: 'dd/MM/yyyy',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, dateController),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, dateController),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: _bodyStyle),
            ),
            TextButton(
              onPressed: () {
                if (dateController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _updateReportStatus(
                    userId, 
                    reportId, 
                    'تم العثور',
                    foundDate: dateController.text.trim()
                  );
                }
              },
              child: Text('تسجيل', style: _bodyStyle.copyWith(color: _successColor)),
            ),
          ],
        );
      },
    );
  }

  // اختيار التاريخ
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // حساب الساعات الإجمالية للمفقود
  String _calculateMissingHours(Map<String, dynamic> report) {
    try {
      final lastSeenDate = report['p5_lastSeenDate']?.toString() ?? '';
      final lastSeenTime = report['p5_lastSeenTime']?.toString() ?? '';
      
      if (lastSeenDate.isEmpty) return 'غير معروف';
      
      final dateTimeStr = '$lastSeenDate $lastSeenTime';
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final lastSeenDateTime = dateFormat.parse(dateTimeStr);
      final now = DateTime.now();
      
      final difference = now.difference(lastSeenDateTime);
      return difference.inHours.toString();
    } catch (e) {
      return 'غير معروف';
    }
  }

  // بناء ورقة تفاصيل التقرير
  Widget _buildReportDetailsSheet(Map<String, dynamic> report) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // شريط السحب
          Container(
            margin: EdgeInsets.all(12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _hintColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // العنوان
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.assignment, color: _primaryColor),
                SizedBox(width: 8),
                Text(
                  'تفاصيل التقرير',
                  style: _headingStyle.copyWith(fontSize: _titleFontSize),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المعلومات الأساسية
                  _buildDetailsSection(
                    title: 'المعلومات الأساسية',
                    children: [
                      _buildDetailRow('الاسم الأول', report['p3_mp_firstName'] ?? ''),
                      _buildDetailRow('اسم العائلة', report['p3_mp_lastName'] ?? ''),
                      _buildDetailRow('اللقب', report['p3_mp_nickname'] ?? ''),
                      _buildDetailRow('العمر', '${report['p3_mp_age'] ?? ''} سنة'),
                      _buildDetailRow('الجنس', report['p3_mp_sex'] ?? ''),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // الوصف الجسدي
                  _buildDetailsSection(
                    title: 'الوصف الجسدي',
                    children: [
                      _buildDetailRow('الطول', '${report['p4_mp_height_feet'] ?? ''}\'${report['p4_mp_height_inches'] ?? ""}\"'),
                      _buildDetailRow('الوزن', '${report['p4_mp_weight'] ?? ''} كجم'),
                      _buildDetailRow('لون الشعر', report['p4_mp_hair_color'] ?? ''),
                      _buildDetailRow('لون العينين', report['p4_mp_eye_color'] ?? ''),
                      _buildDetailRow('الندوب', report['p4_mp_scars'] ?? ''),
                      _buildDetailRow('الوشوم', report['p4_mp_tattoos'] ?? ''),
                      _buildDetailRow('الملابس الأخيرة', report['p4_mp_last_clothing'] ?? ''),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // معلومات الاختفاء
                  _buildDetailsSection(
                    title: 'معلومات الاختفاء',
                    children: [
                      _buildDetailRow('تاريخ الاختفاء', report['p5_lastSeenDate'] ?? ''),
                      _buildDetailRow('وقت الاختفاء', report['p5_lastSeenTime'] ?? ''),
                      _buildDetailRow('آخر موقع', report['p5_lastSeenLoc'] ?? ''),
                      _buildDetailRow('أقرب معلم', report['p5_nearestLandmark'] ?? ''),
                      _buildDetailRow('المدينة', report['p5_cityName'] ?? ''),
                      _buildDetailRow('اسم المكان', report['p5_placeName'] ?? ''),
                      _buildDetailRow('تفاصيل الحادث', report['p5_incidentDetails'] ?? ''),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // المعلومات الإضافية
                  _buildDetailsSection(
                    title: 'معلومات إضافية',
                    children: [
                      _buildDetailRow('تاريخ التبليغ', report['p5_reportDate'] ?? ''),
                      _buildDetailRow('الحالة', _mapStatusToArabic(report['status'] ?? 'معلّق')),
                      if (report['rejectionReason'] != null)
                        _buildDetailRow('سبب الرفض', report['rejectionReason'] ?? ''),
                      if (report['foundDate'] != null)
                        _buildDetailRow('تاريخ العثور', report['foundDate'] ?? ''),
                      _buildDetailRow('الساعات الإجمالية', '${_calculateMissingHours(report)} ساعة'),
                    ],
                  ),
                  
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء قسم التفاصيل
  Widget _buildDetailsSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
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
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // بناء صف التفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _smallFontSize,
                fontWeight: FontWeight.w600,
                color: _hintColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'غير متوفر',
              style: TextStyle(
                fontSize: _smallFontSize,
                color: _textColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // بناء واجهة التحميل
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          SizedBox(height: 16),
          Text(
            'جاري تحميل التقارير...',
            style: _bodyStyle,
          ),
        ],
      ),
    );
  }

  // بناء واجهة عدم وجود تقارير
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: _hintColor),
          SizedBox(height: 16),
          Text(
            'لا توجد تقارير متاحة',
            style: _headingStyle,
          ),
          SizedBox(height: 8),
          Text(
            'سيظهر هنا التقارير عند توفرها',
            style: _bodyStyle.copyWith(color: _hintColor),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReports,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('تحديث', style: _bodyStyle),
          ),
        ],
      ),
    );
  }

  // بناء شريط البحث والفلترة
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: _cardColor,
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _applyFilters(),
          ),
          
          SizedBox(height: 12),
          
          // الفلترة والترتيب
          Row(
            children: [
              // فلترة الحالة
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    underline: SizedBox(),
                    items: _statusList.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStatus = newValue!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // الترتيب
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    underline: SizedBox(),
                    items: _sortOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _sortBy = newValue!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // إظهار رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _bodyStyle.copyWith(color: Colors.white)),
        backgroundColor: _successColor,
      ),
    );
  }

  // إظهار رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _bodyStyle.copyWith(color: Colors.white)),
        backgroundColor: _errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('إدارة التقارير', style: _titleStyle),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isRefreshing ? Icons.refresh : Icons.refresh_outlined),
            onPressed: _isRefreshing ? null : () {
              setState(() {
                _isRefreshing = true;
              });
              _loadReports();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والفلترة
          _buildSearchAndFilterBar(),
          
          // إحصائيات سريعة
          if (_filteredReports.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي التقارير: ${_filteredReports.length}',
                    style: _bodyStyle.copyWith(color: _primaryColor),
                  ),
                  if (_policeLocation != null)
                    Text(
                      'موقع الشرطة: مفعل',
                      style: _smallStyle.copyWith(color: _successColor),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
          
          // قائمة التقارير
          Expanded(
            child: _isLoading
                ? _buildLoadingView()
                : _filteredReports.isEmpty
                    ? _buildEmptyView()
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        color: _primaryColor,
                        child: ListView.builder(
                          itemCount: _filteredReports.length,
                          itemBuilder: (context, index) {
                            return _buildReportCard(_filteredReports[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // أنماط النص
  TextStyle get _titleStyle => TextStyle(
    fontSize: _titleFontSize,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    fontFamily: 'Tajawal',
  );

  TextStyle get _headingStyle => TextStyle(
    fontSize: _bodyFontSize * 1.1,
    fontWeight: FontWeight.w600,
    color: _primaryColor,
    fontFamily: 'Tajawal',
  );

  TextStyle get _bodyStyle => TextStyle(
    fontSize: _bodyFontSize,
    fontWeight: FontWeight.w500,
    color: _textColor,
    fontFamily: 'Tajawal',
  );

  TextStyle get _smallStyle => TextStyle(
    fontSize: _smallFontSize,
    fontWeight: FontWeight.w400,
    color: _hintColor,
    fontFamily: 'Tajawal',
  );

  // لون الحدود
  final Color _borderColor = Color(0xFFDEE2E6);
}