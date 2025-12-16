import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:Missing_Persons_Platform/views/main/pages/nearby_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Missing_Persons_Platform/views/main/pages/profile_main.dart';
import 'package:Missing_Persons_Platform/views/main/pages/update_main.dart';
import 'package:Missing_Persons_Platform/views/main/pages/reports_dashboard.dart'; // استيراد شاشة إدارة التقارير
import 'package:Missing_Persons_Platform/views/main/pages/found_persons_dashboard.dart'; // استيراد شاشة إدارة الموجودين
import 'package:firebase_auth/firebase_auth.dart';

class HomeMain extends StatefulWidget {
  final VoidCallback onReportPressed;
  final VoidCallback onNearbyPressed;
  final VoidCallback onReportsManagementPressed;
  final VoidCallback onFoundPersonsManagementPressed; // المعلمة الجديدة لإدارة الموجودين
  
  const HomeMain({
    super.key,
    required this.onReportPressed,
    required this.onNearbyPressed,
    required this.onReportsManagementPressed,
    required this.onFoundPersonsManagementPressed, // إضافة المعلمة الجديدة
  });

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  final user = FirebaseAuth.instance.currentUser;
  String? displayName;
  List<String>? tokenNames;

  // ألوان التطبيق
  final Color _primaryColor = Color(0xFF006400); // أخضر داكن
  final Color _accentColor = Color(0xFFCE1126); // أحمر
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _successColor = Color(0xFF28A745);
  final Color _warningColor = Color(0xFFFFC107);
  final Color _infoColor = Color(0xFF17A2B8);

  // إحصائيات افتراضية (يمكن استبدالها ببيانات حقيقية من Firebase)
  int _activeReports = 12;
  int _resolvedCases = 8;
  int _pendingReviews = 3;
  int _foundPersonsCount = 5;

  @override
  void initState() {
    displayName = user!.displayName;
    try {
      tokenNames = displayName?.split(' ');
      displayName = tokenNames![0];
    } catch (e) {
      print(e);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return displayName != null
            ? SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.minHeight,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.all(MediaQuery.of(context).size.width / 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // رأس الصفحة
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height / 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // زر الملف الشخصي
                              IconButton(
                                icon: Icon(Icons.account_circle_outlined, 
                                    size: 40, color: _primaryColor),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProfileMain(),
                                    ),
                                  );
                                },
                              ),
                              // شعار التطبيق
                              Image.asset('assets/images/Missing_Persons_PlatformLogo.png', width: 40),
                            ],
                          ),
                        ),
                        
                        // محتوى الصفحة
                        Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ترحيب
                              _buildWelcomeSection(),
                              
                              // صورة رئيسية
                              _buildHeroImage(),
                              
                              // شبكة البطاقات الرئيسية
                              _buildMainGrid(),
                              
                              // قسم الإحصائيات السريعة
                              _buildQuickStatsSection(),

                              // قسم التحديثات الأخيرة
                              _buildRecentUpdatesSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            :
            // إذا كانت بيانات المستخدم لا تزال قيد التحميل
            _buildLoadingView();
      }),
    );
  }

  // بناء قسم الترحيب
  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أهلاً $displayName!',
          textAlign: TextAlign.right,
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textColor,
          ),
        ),
        Text(
          'كيف يمكننا مساعدتك؟',
          textAlign: TextAlign.right,
          style: GoogleFonts.tajawal(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  // بناء الصورة الرئيسية
  Widget _buildHeroImage() {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: Image.asset('assets/images/home.png',
          height: MediaQuery.of(context).size.width * .4),
    );
  }

  // بناء شبكة البطاقات الرئيسية
  Widget _buildMainGrid() {
    return Column(
      children: [
        // الصف الأول
        Row(
          children: [
            Expanded(
              child: _buildMainCard(
                title: 'تبليغ عن مفقود',
                subtitle: 'الإبلاغ عن شخص مفقود',
                icon: Icons.add,
                color: _accentColor,
                image: 'assets/images/reportCont.png',
                onTap: widget.onReportPressed,
                isGradient: true,
                gradientColors: [
                  _accentColor.withOpacity(0.9),
                  Color(0xFFD32F2F).withOpacity(0.7),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMainCard(
                title: 'البلاغات القريبة',
                subtitle: 'عرض البلاغات بالقرب منك',
                icon: Icons.near_me,
                color: _primaryColor,
                image: 'assets/images/NearbyCont.png',
                onTap: widget.onNearbyPressed,
                isGradient: true,
                gradientColors: [
                  _primaryColor.withOpacity(0.9),
                  Color(0xFF4CAF50).withOpacity(0.7),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // الصف الثاني
        Row(
          children: [
            Expanded(
              child: _buildMainCard(
                title: 'إدارة التقارير',
                subtitle: 'عرض وإدارة جميع البلاغات',
                icon: Icons.assignment,
                color: Color(0xFF2E7D32),
                onTap: widget.onReportsManagementPressed,
                isGradient: true,
                gradientColors: [
                  Color(0xFF2E7D32).withOpacity(0.9),
                  Color(0xFF4CAF50).withOpacity(0.7),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMainCard(
                title: 'إدارة الموجودين',
                subtitle: 'الأشخاص الذين تم العثور عليهم',
                icon: Icons.person_search,
                color: Color(0xFF1976D2),
                onTap: widget.onFoundPersonsManagementPressed,
                isGradient: true,
                gradientColors: [
                  Color(0xFF1976D2).withOpacity(0.9),
                  Color(0xFF42A5F5).withOpacity(0.7),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء بطاقة رئيسية
  Widget _buildMainCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? image,
    required VoidCallback onTap,
    bool isGradient = false,
    List<Color>? gradientColors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0.0, 4.0),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // الخلفية
            if (isGradient && gradientColors != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: gradientColors,
                  ),
                ),
              )
            else if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            
            // طبقة تظليل للصور
            if (image != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      color.withOpacity(0.8),
                      color.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            
            // محتوى النص
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء قسم الإحصائيات السريعة
  Widget _buildQuickStatsSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نظرة سريعة',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: _primaryColor, size: 20),
                onPressed: _refreshStats,
                tooltip: 'تحديث الإحصائيات',
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('البلاغات النشطة', _activeReports.toString(), 
                  Icons.assignment, _primaryColor),
              _buildStatItem('تم حلها', _resolvedCases.toString(), 
                  Icons.check_circle, _successColor),
              _buildStatItem('قيد المراجعة', _pendingReviews.toString(), 
                  Icons.schedule, _warningColor),
              _buildStatItem('تم العثور', _foundPersonsCount.toString(), 
                  Icons.person_search, _infoColor),
            ],
          ),
        ],
      ),
    );
  }

  // بناء عنصر إحصائي
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: _hintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // بناء قسم التحديثات الأخيرة
  Widget _buildRecentUpdatesSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر التحديثات',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // التنقل إلى شاشة جميع التحديثات
                },
                child: Text(
                  'عرض الكل',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildUpdateItem(
            'تم العثور على شخص مفقود في الرياض',
            'منذ ساعتين',
            Icons.check_circle,
            _successColor,
            onTap: () {
              // تفاصيل التحديث
            },
          ),
          _buildUpdateItem(
            'تقرير جديد يحتاج للمراجعة',
            'منذ 4 ساعات',
            Icons.pending,
            _warningColor,
            onTap: () {
              widget.onReportsManagementPressed();
            },
          ),
          _buildUpdateItem(
            'تم تسجيل 3 أشخاص موجودين جديدين',
            'منذ 6 ساعات',
            Icons.person_search,
            _infoColor,
            onTap: () {
              widget.onFoundPersonsManagementPressed();
            },
          ),
          _buildUpdateItem(
            'تحديث في نظام الإبلاغ',
            'منذ يوم',
            Icons.update,
            _primaryColor,
            onTap: () {
              // تفاصيل التحديث
            },
          ),
        ],
      ),
    );
  }

  // بناء عنصر تحديث
  Widget _buildUpdateItem(String title, String time, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          subtitle: Text(
            time,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: _hintColor,
            ),
          ),
          trailing: Icon(Icons.chevron_left, color: _hintColor),
        ),
      ),
    );
  }

  // بناء واجهة التحميل
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitCubeGrid(
            color: _primaryColor,
            size: 40.0,
          ),
          SizedBox(height: 20),
          Text(
            'جاري تحميل البيانات...',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              color: _hintColor,
            ),
          ),
        ],
      ),
    );
  }

  // دالة تحديث الإحصائيات
  void _refreshStats() {
    setState(() {
      // محاكاة تحديث البيانات
      _activeReports = 12 + DateTime.now().second % 5;
      _resolvedCases = 8 + DateTime.now().second % 3;
      _pendingReviews = 3 + DateTime.now().second % 2;
      _foundPersonsCount = 5 + DateTime.now().second % 4;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تحديث الإحصائيات'),
        backgroundColor: _successColor,
        duration: Duration(seconds: 2),
      ),
    );
  }
}