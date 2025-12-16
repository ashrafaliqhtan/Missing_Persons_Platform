import 'package:flutter/material.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'p3_mp_info.dart';

class Page1Classifier extends StatefulWidget {
  const Page1Classifier({super.key});

  @override
  State<Page1Classifier> createState() => _Page1ClassifierState();
}

// shared preferences for state management
late SharedPreferences _prefs;
void clearPrefs() {
  _prefs.clear();
}

class _Page1ClassifierState extends State<Page1Classifier> {
  // local boolean variables for checkboxes
  bool? isVictimNaturalCalamity;
  bool? isMinor;
  bool? isMissing24Hours;
  bool? isVictimCrime;

  // ageFromP3
  int? ageFromMPBirthDate;
  // hoursSinceLastSeenFromP5
  int? hoursSinceLastSeenFromP5;

  /* FORMATTING STUFF */
  // responsive padding
  double get _verticalPadding => MediaQuery.of(context).size.height * 0.02;
  double get _horizontalPadding => MediaQuery.of(context).size.width * 0.05;
  
  // responsive font sizes
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.065;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.04;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.035;
  
  // colors
  final Color _primaryColor = Palette.indigo;
  final Color _accentColor = Colors.orange.shade600;
  final Color _textColor = Colors.grey.shade800;
  final Color _hintColor = Colors.grey.shade600;
  final Color _disabledColor = Colors.grey.shade400;
  final Color _cardColor = Colors.white;
  final Color _shadowColor = Colors.grey.withOpacity(0.1);
  
  // font style for the text
  TextStyle get _titleStyle => TextStyle(
    fontSize: _titleFontSize,
    fontWeight: FontWeight.w700,
    color: _textColor,
    fontFamily: 'Tajawal', // استخدام خط عربي مناسب
  );
  
  TextStyle get _bodyStyle => TextStyle(
    fontSize: _bodyFontSize,
    fontWeight: FontWeight.w500,
    color: _textColor,
    fontFamily: 'Tajawal',
    height: 1.5,
  );
  
  TextStyle get _smallStyle => TextStyle(
    fontSize: _smallFontSize,
    fontWeight: FontWeight.w400,
    color: _hintColor,
    fontFamily: 'Tajawal',
    height: 1.4,
  );
  /* END OF FORMATTING STUFF */

  /* SHARED PREFERENCE STUFF */
  // Future builder for shared preferences, initialize as false
  Future<void> getUserChoices() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      // set the state of the checkboxes
      isVictimNaturalCalamity =
          _prefs.getBool('p1_isVictimNaturalCalamity') ?? false;

      // isMinor depends on p3_mp_age
      if (_prefs.getString('p3_mp_age') == null ||
          _prefs.getString('p3_mp_age') == '') {
        isMinor = _prefs.getBool('p1_isMinor') ?? false;
      } else {
        // if p3_mp_age is not null, check if it is less than 18
        ageFromMPBirthDate = int.parse(_prefs.getString('p3_mp_age')!);
        if (ageFromMPBirthDate! < 18) {
          isMinor = true;
        } else {
          isMinor = false;
        }
        _prefs.setBool('p1_isMinor', isMinor!);
      }

      // isMissing24Hours depends on p5_totalHoursSinceLastSeen
      if (_prefs.getString('p5_totalHoursSinceLastSeen') == null ||
          _prefs.getString('p5_totalHoursSinceLastSeen') == '') {
        isMissing24Hours = _prefs.getBool('p1_isMissing24Hours') ?? false;
      } else {
        // if p5_totalHoursSinceLastSeen is not null, check if it is less than 24
        hoursSinceLastSeenFromP5 =
            int.parse(_prefs.getString('p5_totalHoursSinceLastSeen')!);
        if (hoursSinceLastSeenFromP5! >= 24) {
          isMissing24Hours = true;
        } else {
          isMissing24Hours = false;
        }
        _prefs.setBool('p1_isMissing24Hours', isMissing24Hours!);
      }

      isVictimCrime = _prefs.getBool('p1_isVictimCrime') ?? false;
    });
  }

  // initstate for shared preferences
  @override
  void initState() {
    super.initState();
    getUserChoices();
  }
  /* END OF SHARED PREFERENCE STUFF */

  // classifier texts
  static const String naturalCalamityText =
      'الشخص مفقود بسبب كارثة طبيعية (فيضانات، زلازل، انهيارات أرضية) أو حادث';
  static const String minorText =
      'الشخص لا يزال قاصراً (تحت سن 18 سنة)';
  static const String missing24HoursText =
      'الشخص مفقود لأكثر من 24 ساعة منذ آخر مرة شوهد فيها';
  static const String victimCrimeText =
      'الشخص ضحية جريمة مثل الاختطاف أو الاتجار بالبشر';

  // دوال مساعدة للتعامل مع التغييرات
  void _handleNaturalCalamityChange(bool? value) {
    if (value != null) {
      setState(() {
        isVictimNaturalCalamity = value;
      });
      _prefs.setBool('p1_isVictimNaturalCalamity', value);
    }
  }

  void _handleMinorChange(bool? value) {
    if (value != null && ageFromMPBirthDate == null) {
      setState(() {
        isMinor = value;
      });
      _prefs.setBool('p1_isMinor', value);
    }
  }

  void _handleMissing24HoursChange(bool? value) {
    if (value != null && hoursSinceLastSeenFromP5 == null) {
      setState(() {
        isMissing24Hours = value;
      });
      _prefs.setBool('p1_isMissing24Hours', value);
    }
  }

  void _handleVictimCrimeChange(bool? value) {
    if (value != null) {
      setState(() {
        isVictimCrime = value;
      });
      _prefs.setBool('p1_isVictimCrime', value);
    }
  }

  // بناء بطاقة الخيار
  Widget _buildOptionCard({
    required String text,
    required bool? value,
    required Function(bool?) onChanged,
    bool enabled = true,
    IconData? icon,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.5),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: enabled ? Colors.grey.shade200 : _disabledColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onChanged(!(value ?? false)) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(_horizontalPadding * 0.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: value ?? false,
                    activeColor: _primaryColor,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
                
                SizedBox(width: _horizontalPadding * 0.5),
                
                // Text and Icon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: _bodyFontSize * 1.2,
                          color: enabled ? _accentColor : _disabledColor,
                        ),
                        SizedBox(height: _verticalPadding * 0.3),
                      ],
                      Text(
                        text,
                        style: _bodyStyle.copyWith(
                          color: enabled ? _textColor : _disabledColor,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: isVictimNaturalCalamity != null
              ? SingleChildScrollView(
                  padding: EdgeInsets.all(_horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeaderSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Information Card
                      _buildInfoCard(),
                      
                      SizedBox(height: _verticalPadding * 1.5),
                      
                      // Classifiers Section
                      _buildClassifiersSection(),
                      
                      SizedBox(height: _verticalPadding * 2),
                      
                      // Footer Section
                      _buildFooterSection(),
                    ],
                  ),
                )
              : _buildLoadingIndicator(),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Indicator
        Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.12,
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
        
        SizedBox(height: _verticalPadding * 1.5),
        
        // Title
        Text(
          'التصنيفات',
          style: _titleStyle,
        ),
        
        SizedBox(height: _verticalPadding * 0.5),
        
        // Subtitle
        Text(
          'الصفحة ١ من ٦',
          style: _smallStyle.copyWith(
            color: _hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding * 0.8),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: _bodyFontSize * 1.2,
            color: _primaryColor,
          ),
          SizedBox(width: _horizontalPadding * 0.6),
          Expanded(
            child: Text(
              'يرجى تحديد جميع العبارات التي تنطبق على حالة الشخص المفقود',
              style: _smallStyle.copyWith(
                color: _primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassifiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر التصنيفات المناسبة',
          style: _bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        SizedBox(height: _verticalPadding),
        
        // Classifiers Cards
        _buildOptionCard(
          text: naturalCalamityText,
          value: isVictimNaturalCalamity,
          onChanged: _handleNaturalCalamityChange,
          icon: Icons.nature_outlined,
        ),
        
        _buildOptionCard(
          text: minorText,
          value: isMinor,
          onChanged: _handleMinorChange,
          enabled: ageFromMPBirthDate == null,
          icon: Icons.child_care_outlined,
        ),
        
        _buildOptionCard(
          text: missing24HoursText,
          value: isMissing24Hours,
          onChanged: _handleMissing24HoursChange,
          enabled: hoursSinceLastSeenFromP5 == null,
          icon: Icons.access_time_outlined,
        ),
        
        _buildOptionCard(
          text: victimCrimeText,
          value: isVictimCrime,
          onChanged: _handleVictimCrimeChange,
          icon: Icons.security_outlined,
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: EdgeInsets.all(_horizontalPadding * 0.8),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _accentColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'نهاية نموذج التصنيفات',
                  style: _smallStyle.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: _verticalPadding * 0.3),
                Text(
                  'اسحب لليسار للمتابعة',
                  style: _smallStyle.copyWith(
                    color: _hintColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          SizedBox(width: _horizontalPadding * 0.5),
          Lottie.asset(
            "assets/lottie/swipeLeft.json",
            animate: true,
            width: MediaQuery.of(context).size.width * 0.12,
            height: MediaQuery.of(context).size.width * 0.12,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitCubeGrid(
            color: _primaryColor,
            size: 50.0,
          ),
          SizedBox(height: _verticalPadding * 2),
          Text(
            'جاري تحميل البيانات...',
            style: _bodyStyle.copyWith(
              color: _hintColor,
            ),
          ),
        ],
      ),
    );
  }
}