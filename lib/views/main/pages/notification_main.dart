import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:Missing_Persons_Platform/views/main/pages/profile_main.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationMain extends StatefulWidget {
  final Map<dynamic, dynamic> reports;
  final VoidCallback missingPersonTap;
  const NotificationMain(
      {super.key, required this.reports, required this.missingPersonTap});

  @override
  State<NotificationMain> createState() => _NotificationMain();
}

class _NotificationMain extends State<NotificationMain> {
  final dbRef2 = FirebaseDatabase.instance.ref().child('Reports');
  final notificationRef = FirebaseDatabase.instance.ref('Notifications');
  final userUid = FirebaseAuth.instance.currentUser!.uid;
  dynamic hiddenReports = {};

  late dynamic _reports = {};

  // ألوان مخصصة للمظهر
  final Color _primaryColor = Color(0xFF6A1B9A);
  final Color _accentColor = Color(0xFFAB47BC);
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _successColor = Color(0xFF28A745);
  final Color _warningColor = Color(0xFFFFC107);
  final Color _errorColor = Color(0xFFDC3545);
  final Color _infoColor = Color(0xFF17A2B8);
  final Color _borderColor = Color(0xFFDEE2E6);

  // أحجام خطوط متجاوبة
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.045;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.035;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.03;
  
  // مسافات متجاوبة
  double get _verticalPadding => MediaQuery.of(context).size.height * 0.015;
  double get _horizontalPadding => MediaQuery.of(context).size.width * 0.04;

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

  Future<void> _fetchData() async {
    final snapshot = await dbRef2.once();
    setState(() {
      _reports = snapshot.snapshot.value ?? {};
    });
    if (kDebugMode) {
      print('[DATA FETCHED] تم تحميل بيانات الإشعارات بنجاح');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  List<double> extractDoubles(String input) {
    RegExp regExp = RegExp(r"[-+]?\d*\.?\d+");
    List<double> doubles = [];
    Iterable<RegExpMatch> matches = regExp.allMatches(input);
    for (RegExpMatch match in matches) {
      doubles.add(double.parse(match.group(0)!));
    }
    return doubles;
  }

  bool locationPermission = false;
  void checkLocationPermission() async {
    bool toChange = await Permission.location.isDenied;
    setState(() {
      locationPermission = toChange;
    });
  }

  @override
  Widget build(BuildContext context) {
    checkLocationPermission();
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.06),
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // الهيدر
            _buildHeader(),
            SizedBox(height: _verticalPadding),
            
            // محتوى الإشعارات
            widget.reports.isNotEmpty
                ? _buildNotificationsList()
                : _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: _verticalPadding),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الشعار
          Padding(
            padding: EdgeInsets.only(right: _horizontalPadding),
            child: Image.asset(
              'assets/images/Missing_Persons_PlatformLogo.png',
              width: 35,
            ),
          ),
          
          // العنوان
          Expanded(
            child: Text(
              'الإشعارات',
              style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.2),
              textAlign: TextAlign.center,
            ),
          ),
          
          // زر البروفايل
          Container(
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.account_circle_outlined, size: 24, color: _primaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileMain(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      width: double.infinity,
      child: ListView.builder(
        itemCount: widget.reports.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(int index) {
    dynamic currentReportValues = widget.reports[widget.reports.keys.elementAt(index)];
    dynamic currentReportKey = widget.reports.keys.elementAt(index);

    bool minor = currentReportValues['p1_isMinor'] ?? false;
    bool crime = currentReportValues['p1_isVictimCrime'] ?? false;
    bool calamity = currentReportValues['p1_isVictimNaturalCalamity'] ?? false;
    bool over24hours = currentReportValues['p1_isMissing24Hours'] ?? false;

    final lastSeendate = currentReportValues['p5_lastSeenDate'] ?? '';
    final lastSeenTime = currentReportValues['p5_lastSeenTime'] ?? '';
    final firstName = currentReportValues['p3_mp_firstName'] ?? '';
    final lastName = currentReportValues['p3_mp_lastName'] ?? '';
    final mp_recentPhoto_LINK = currentReportValues['mp_recentPhoto_LINK'] ?? 
        'https://images.squarespace-cdn.com/content/v1/5b8709309f87706a308b674a/1630432472107-419TL4L1S480Z0LIVRYA/Missing.jpg';
    final lastSeenLoc = currentReportValues['p5_nearestLandmark'] ?? '';
    final dateReported = currentReportValues['p5_reportDate'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: ListTile(
          contentPadding: EdgeInsets.all(_horizontalPadding * 0.8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _primaryColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                mp_recentPhoto_LINK,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _hintColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: _hintColor),
                  );
                },
              ),
            ),
          ),
          trailing: _buildNotificationActions(index, currentReportKey),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$firstName $lastName',
                style: _bodyStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: _bodyFontSize * 1.1,
                ),
              ),
              SizedBox(height: _verticalPadding * 0.3),
              Text(
                'آخر مشاهدة: $lastSeendate, $lastSeenTime في $lastSeenLoc',
                style: _smallStyle,
              ),
              SizedBox(height: _verticalPadding * 0.2),
              Text(
                'تاريخ التبليغ: $dateReported',
                style: _smallStyle.copyWith(fontSize: _smallFontSize * 0.9),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: _verticalPadding * 0.5),
              _buildStatusTags(minor, crime, calamity, over24hours),
              SizedBox(height: _verticalPadding * 0.5),
              Row(
                children: [
                  Icon(Icons.touch_app, size: 14, color: _primaryColor),
                  SizedBox(width: 6),
                  Text(
                    'انقر لعرض التفاصيل في التقارير القريبة',
                    style: _smallStyle.copyWith(
                      fontSize: _smallFontSize * 0.9,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _showNavigationDialog(),
        ),
      ),
    );
  }

  Widget _buildNotificationActions(int index, dynamic currentReportKey) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: _hintColor),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'hide',
          child: Row(
            children: [
              Icon(Icons.visibility_off, size: 18, color: _hintColor),
              SizedBox(width: 8),
              Text('إخفاء الإشعار', style: _smallStyle),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.map, size: 18, color: _primaryColor),
              SizedBox(width: 8),
              Text('عرض على الخريطة', style: _smallStyle),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'hide') {
          _showHideConfirmationDialog(index, currentReportKey);
        } else if (value == 'view') {
          widget.missingPersonTap();
        }
      },
    );
  }

  Widget _buildStatusTags(bool minor, bool crime, bool calamity, bool over24hours) {
    return Visibility(
      visible: minor || crime || calamity || over24hours,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (crime)
            _buildStatusTag('ضحية جريمة', Colors.deepPurple),
          if (calamity)
            _buildStatusTag('ضحية كارثة', Colors.orangeAccent),
          if (over24hours)
            _buildStatusTag('أكثر من 24 ساعة', Colors.green),
          if (minor)
            _buildStatusTag('قاصر', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: _smallStyle.copyWith(
          color: Colors.white,
          fontSize: _smallFontSize * 0.8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          Column(
            children: [
              Text(
                'استراحة قصيرة',
                style: _headingStyle.copyWith(fontSize: _titleFontSize),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: _verticalPadding * 0.5),
              Text(
                'لا توجد إشعارات جديدة!',
                style: _bodyStyle.copyWith(color: _hintColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: _verticalPadding * 2),
              Lottie.asset(
                "assets/lottie/noNotifications.json",
                animate: true,
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ],
          ),
          SizedBox(height: _verticalPadding * 2),
          if (locationPermission)
            Container(
              padding: EdgeInsets.all(_horizontalPadding * 0.8),
              decoration: BoxDecoration(
                color: _infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _infoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _infoColor, size: 20),
                  SizedBox(width: _horizontalPadding * 0.5),
                  Expanded(
                    child: Text(
                      'قم بتفعيل صلاحية الموقع الدقيق لتلقي إشعارات التقارير القريبة منك.',
                      style: _smallStyle.copyWith(color: _infoColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showHideConfirmationDialog(int index, dynamic currentReportKey) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(_horizontalPadding),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_off, size: 50, color: _warningColor),
              SizedBox(height: _verticalPadding),
              Text(
                'إخفاء الإشعار',
                style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.2),
              ),
              SizedBox(height: _verticalPadding * 0.5),
              Text(
                'هل أنت متأكد أنك تريد إخفاء هذا الإشعار؟',
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: _verticalPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _hintColor,
                        side: BorderSide(color: _hintColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('إلغاء', style: _bodyStyle),
                    ),
                  ),
                  SizedBox(width: _horizontalPadding * 0.5),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await FirebaseDatabase.instance
                            .ref('Notifications')
                            .child(userUid)
                            .child(currentReportKey.toString())
                            .set('hidden')
                            .then((_) {
                          if (kDebugMode) {
                            print('[NOTIFICATIONS] تم إخفاء الإشعار');
                          }
                        });
                      },
                      child: Text('تأكيد', style: _bodyStyle.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNavigationDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(_horizontalPadding),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 50, color: _primaryColor),
              SizedBox(height: _verticalPadding),
              Text(
                'الانتقال إلى التقارير القريبة؟',
                style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.2),
              ),
              SizedBox(height: _verticalPadding * 0.5),
              Text(
                'هل تريد الانتقال إلى خريطة التقارير القريبة لعرض التفاصيل؟',
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: _verticalPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _hintColor,
                        side: BorderSide(color: _hintColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('إلغاء', style: _bodyStyle),
                    ),
                  ),
                  SizedBox(width: _horizontalPadding * 0.5),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        widget.missingPersonTap();
                        Navigator.of(context).pop();
                      },
                      child: Text('تأكيد', style: _bodyStyle.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}