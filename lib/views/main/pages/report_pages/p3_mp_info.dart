import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'p1_classifier.dart';

/* SHARED PREFERENCE */
late SharedPreferences _prefs;
void clearPrefs() {
  _prefs.clear();
}

/* DATE AND FORMATTER */
List<String> reformatDate(String dateTime, DateTime dateTimeBday) {
  var dateParts = dateTime.split('-');
  var month = dateParts[1];
  if (int.parse(month) % 10 != 0) {
    month = month.replaceAll('0', '');
  }
  
  // تحويل الأشهر إلى العربية
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
  day = day.substring(0, day.indexOf(' '));
  if (int.parse(day) % 10 != 0) {
    day = day.replaceAll('0', '');
  }

  var year = dateParts[0];

  var age =
      (DateTime.now().difference(dateTimeBday).inDays / 365).floor().toString();
  var returnVal = '$day $month $year'; // تنسيق عربي: يوم شهر سنة
  return [returnVal, age];
}

/* PAGE 3 */
class Page3MPDetails extends StatefulWidget {
  final VoidCallback addHeightParent;
  final VoidCallback subtractHeightParent;
  final VoidCallback defaultHeightParent;
  
  const Page3MPDetails({
    super.key,
    required this.addHeightParent,
    required this.subtractHeightParent,
    required this.defaultHeightParent,
  });

  @override
  State<Page3MPDetails> createState() => _Page3MPDetailsState();
}

/* PAGE 3 STATE */
class _Page3MPDetailsState extends State<Page3MPDetails> {
  // ألوان مخصصة للمملكة العربية السعودية
  final Color _primaryColor = Color(0xFF006400); // أخضر داكن
  final Color _accentColor = Color(0xFFCE1126); // أحمر
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _borderColor = Color(0xFFDEE2E6);

  // أحجام خطوط متجاوبة
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.06;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.038;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.033;
  
  // مسافات متجاوبة
  double get _verticalPadding => MediaQuery.of(context).size.height * 0.012;
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

  // متغير للتحكم في التمرير
  final ScrollController _scrollController = ScrollController();

  /* CONTROLLERS */
  // for basic info
  late final TextEditingController _mp_lastName = TextEditingController();
  late final TextEditingController _mp_firstName = TextEditingController();
  late final TextEditingController _mp_middleName = TextEditingController();
  late final TextEditingController _mp_qualifier = TextEditingController();
  late final TextEditingController _mp_nickname = TextEditingController();
  late final TextEditingController _mp_citizenship = TextEditingController();
  late final TextEditingController _mp_nationalityEthnicity = TextEditingController();
  late final TextEditingController _mp_sex = TextEditingController();
  late final TextEditingController _mp_civilStatus = TextEditingController();
  late final TextEditingController _mp_birthDate;
  late final TextEditingController _mp_age = TextEditingController();
  // for contact info
  late final TextEditingController _mp_contact_homePhone = TextEditingController();
  late final TextEditingController _mp_contact_mobilePhone = TextEditingController();
  late final TextEditingController _mp_contact_mobilePhone_alt = TextEditingController();
  late final TextEditingController _mp_contact_email = TextEditingController();
  // for address
  late final TextEditingController _mp_address_region = TextEditingController();
  late final TextEditingController _mp_address_province = TextEditingController();
  late final TextEditingController _mp_address_city = TextEditingController();
  late final TextEditingController _mp_address_barangay = TextEditingController();
  late final TextEditingController _mp_address_villageSitio = TextEditingController();
  late final TextEditingController _mp_address_streetHouseNum = TextEditingController();
  // for alternate address
  bool mp_hasAltAddress = false;
  late final TextEditingController _mp_address_region_alt = TextEditingController();
  late final TextEditingController _mp_address_province_alt = TextEditingController();
  late final TextEditingController _mp_address_city_alt = TextEditingController();
  late final TextEditingController _mp_address_barangay_alt = TextEditingController();
  late final TextEditingController _mp_address_villageSitio_alt = TextEditingController();
  late final TextEditingController _mp_address_streetHouseNum_alt = TextEditingController();
  // for ocupation and highest education
  late final TextEditingController _mp_education = TextEditingController();
  late final TextEditingController _mp_occupation = TextEditingController();
  // for Work/School Address
  bool mp_hasSchoolWorkAddress = false;
  late final TextEditingController _mp_workSchool_region = TextEditingController();
  late final TextEditingController _mp_workSchool_province = TextEditingController();
  late final TextEditingController _mp_workSchool_city = TextEditingController();
  late final TextEditingController _mp_workSchool_barangay = TextEditingController();
  late final TextEditingController _mp_workSchool_villageSitio = TextEditingController();
  late final TextEditingController _mp_workSchool_streetHouseNum = TextEditingController();
  late final TextEditingController _mp_workSchool_name = TextEditingController();

  /* VARIABLES */
  String? ageFromMPBirthDate;
  DateTime? dateTimeMPBirthDate;
  bool? hasAlternateAddress = false;
  String? sexValue;
  String? mp_civilStatValue;
  int age_value = 0;
  String? mp_educationalAttainment;

  // قوائم منسدلة مخصصة للمملكة العربية السعودية
  final List<String> _saudiRegions = [
    'منطقة الرياض',
    'منطقة مكة المكرمة',
    'منطقة المدينة المنورة',
    'منطقة القصيم',
    'المنطقة الشرقية',
    'منطقة عسير',
    'منطقة تبوك',
    'منطقة حائل',
    'منطقة الحدود الشمالية',
    'منطقة جازان',
    'منطقة نجران',
    'منطقة الباحة',
    'منطقة الجوف'
  ];

  final List<String> _saudiCities = [
    'الرياض',
    'جدة',
    'مكة المكرمة',
    'المدينة المنورة',
    'الدمام',
    'الخبر',
    'الطائف',
    'تبوك',
    'بريدة',
    'حائل',
    'أبها',
    'جازان',
    'نجران'
  ];

  final List<String> _saudiCivilStatus = [
    'أعزب',
    'متزوج',
    'مطلق',
    'أرمل'
  ];

  final List<String> _saudiEducation = [
    'ابتدائي',
    'متوسط',
    'ثانوي',
    'دبلوم',
    'بكالوريوس',
    'ماجستير',
    'دكتوراه'
  ];

  final List<String> _sexOptions = [
    'ذكر',
    'أنثى'
  ];

  /* SHARED PREF EMPTY CHECKER AND SAVER FUNCTION*/
  Future<void> _writeToPrefs(String key, String value) async {
    if (value != '') {
      _prefs.setString(key, value);
    } else {
      _prefs.remove(key);
    }
  }

  /* INITIALIZE CONTROLLERS */
  @override
  void initState() {
    _mp_birthDate = TextEditingController();

    // shared preferences
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
        widget.defaultHeightParent();

        mp_hasAltAddress = _prefs.getBool('p3_mp_hasAltAddress') ?? false;
        mp_hasSchoolWorkAddress = _prefs.getBool('p3_mp_hasSchoolWorkAddress') ?? false;

        mp_hasAltAddress ? widget.addHeightParent() : null;
        mp_hasSchoolWorkAddress ? widget.addHeightParent() : null;

        // basic info
        if (prefs.getString('p3_mp_civilStatus') != null) {
          mp_civilStatValue = prefs.getString('p3_mp_civilStatus');
        }
        
        sexValue = prefs.getString('p3_mp_sex') ?? '';
        _mp_lastName.text = prefs.getString('p3_mp_lastName') ?? '';
        _mp_firstName.text = prefs.getString('p3_mp_firstName') ?? '';
        _mp_middleName.text = prefs.getString('p3_mp_middleName') ?? '';
        _mp_qualifier.text = prefs.getString('p3_mp_qualifier') ?? '';
        _mp_nickname.text = prefs.getString('p3_mp_nickname') ?? '';
        _mp_citizenship.text = prefs.getString('p3_mp_citizenship') ?? '';
        _mp_nationalityEthnicity.text = prefs.getString('p3_mp_nationalityEthnicity') ?? '';
        _mp_sex.text = prefs.getString('p3_mp_sex') ?? '';
        _mp_birthDate.text = prefs.getString('p3_mp_birthDate') ?? '';
        ageFromMPBirthDate = prefs.getString('p3_mp_age') ?? '';
        _mp_age.text = prefs.getString('p3_mp_age') ?? '';
        
        // for contact info
        _mp_contact_homePhone.text = prefs.getString('p3_mp_contact_homePhone') ?? '';
        _mp_contact_mobilePhone.text = prefs.getString('p3_mp_contact_mobilePhone') ?? '';
        _mp_contact_mobilePhone_alt.text = prefs.getString('p3_mp_contact_mobilePhone_alt') ?? '';
        _mp_contact_email.text = prefs.getString('p3_mp_contact_email') ?? '';
        
        // for address
        _mp_address_region.text = prefs.getString('p3_mp_address_region') ?? '';
        _mp_address_province.text = prefs.getString('p3_mp_address_province') ?? '';
        _mp_address_city.text = prefs.getString('p3_mp_address_city') ?? '';
        _mp_address_barangay.text = prefs.getString('p3_mp_address_barangay') ?? '';
        _mp_address_villageSitio.text = prefs.getString('p3_mp_address_villageSitio') ?? '';
        _mp_address_streetHouseNum.text = prefs.getString('p3_mp_address_streetHouseNum') ?? '';
        
        // for alternate address
        _mp_address_region_alt.text = prefs.getString('p3_mp_address_region_alt') ?? '';
        _mp_address_province_alt.text = prefs.getString('p3_mp_address_province_alt') ?? '';
        _mp_address_city_alt.text = prefs.getString('p3_mp_address_city_alt') ?? '';
        _mp_address_barangay_alt.text = prefs.getString('p3_mp_address_barangay_alt') ?? '';
        _mp_address_villageSitio_alt.text = prefs.getString('p3_mp_address_villageSitio_alt') ?? '';
        _mp_address_streetHouseNum_alt.text = prefs.getString('p3_mp_address_streetHouseNum_alt') ?? '';
        
        // for ocupation and highest education
        if (prefs.getString('p3_mp_education') != null) {
          mp_educationalAttainment = prefs.getString('p3_mp_education');
        }

        _mp_education.text = prefs.getString('p3_mp_education') ?? '';
        _mp_occupation.text = prefs.getString('p3_mp_occupation') ?? '';
        
        // for Work/School Address
        _mp_workSchool_region.text = prefs.getString('p3_mp_workSchool_region') ?? '';
        _mp_workSchool_province.text = prefs.getString('p3_mp_workSchool_province') ?? '';
        _mp_workSchool_city.text = prefs.getString('p3_mp_workSchool_city') ?? '';
        _mp_workSchool_barangay.text = prefs.getString('p3_mp_workSchool_barangay') ?? '';
        _mp_workSchool_villageSitio.text = prefs.getString('p3_mp_workSchool_villageSitio') ?? '';
        _mp_workSchool_streetHouseNum.text = prefs.getString('p3_mp_workSchool_streetHouseNum') ?? '';
        _mp_workSchool_name.text = prefs.getString('p3_mp_workSchool_name') ?? '';
      });
    });
    super.initState();
  }

  /* DISPOSE CONTROLLERS */
  @override
  void dispose() {
    _mp_birthDate.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // دالة مساعدة لبناء حقل النموذج
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function(String)? onChanged,
    bool enabled = true,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              isRequired ? '$label *' : label,
              style: _bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: _textColor,
                fontSize: _bodyFontSize * 0.9,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: _verticalPadding * 0.2),
          ],
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            enabled: enabled,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: _smallStyle.copyWith(color: _hintColor),
              hintTextDirection: TextDirection.rtl,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              filled: true,
              fillColor: enabled ? _cardColor : Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _horizontalPadding * 0.6,
                vertical: _verticalPadding * 0.5,
              ),
            ),
            onChanged: onChanged ?? (text) {
              if (onChanged != null) onChanged(text);
            },
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء القائمة المنسدلة
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = false,
    String? hint,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
            style: _bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: _textColor,
              fontSize: _bodyFontSize * 0.9,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: _verticalPadding * 0.2),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
              color: _cardColor,
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding * 0.6,
                  vertical: _verticalPadding * 0.3,
                ),
                hintText: hint,
                hintStyle: _smallStyle.copyWith(color: _hintColor),
                hintTextDirection: TextDirection.rtl,
              ),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor, size: 20),
              iconSize: 20,
              elevation: 8,
              style: _bodyStyle.copyWith(fontSize: _bodyFontSize * 0.9),
              dropdownColor: _cardColor,
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    textDirection: TextDirection.rtl,
                    style: _bodyStyle.copyWith(fontSize: _bodyFontSize * 0.9),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء زر الراديو
  Widget _buildRadioOption({
    required String value,
    required String groupValue,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.2),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: groupValue == value ? _primaryColor : _borderColor,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          label,
          style: _bodyStyle.copyWith(fontSize: _bodyFontSize * 0.9),
          textDirection: TextDirection.rtl,
        ),
        value: value,
        groupValue: groupValue,
        activeColor: _primaryColor,
        contentPadding: EdgeInsets.symmetric(horizontal: _horizontalPadding * 0.4),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildHeaderSection(),
              ),
              
              // محتوى قابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(_horizontalPadding * 0.8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: _verticalPadding * 0.5),
                      
                      // Information Card
                      _buildInfoCard(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Personal Information Section
                      _buildPersonalInfoSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Contact Information Section
                      _buildContactInfoSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Address Section
                      _buildAddressSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Education & Occupation Section
                      _buildEducationOccupationSection(),
                      
                      SizedBox(height: _verticalPadding * 1.5),
                      
                      // Footer Section
                      _buildFooterSection(),
                      
                      // مسافة إضافية في الأسفل للتأكد من رؤية كل المحتوى
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              width: MediaQuery.of(context).size.width * 0.3,
              height: 3,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Container(
                height: 3,
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
                    'تفاصيل الشخص المفقود',
                    style: _titleStyle.copyWith(fontSize: _titleFontSize * 0.9),
                  ),
                  SizedBox(height: _verticalPadding * 0.2),
                  Text(
                    'الصفحة ٣ من ٦',
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
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: _bodyFontSize * 1.1, color: _primaryColor),
          SizedBox(width: _horizontalPadding * 0.4),
          Expanded(
            child: Text(
              'الحقول المميزة بعلامة (*) إلزامية. اكتب "غير معروف" إذا لم تكن المعلومة متوفرة',
              style: _smallStyle.copyWith(
                color: _primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المعلومات الشخصية',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        // الاسم
        _buildFormField(
          controller: _mp_lastName,
          label: 'الاسم الأخير',
          hint: 'أدخل الاسم الأخير',
          isRequired: true,
          maxLength: 25,
          onChanged: (value) => _writeToPrefs('p3_mp_lastName', value),
        ),
        
        _buildFormField(
          controller: _mp_firstName,
          label: 'الاسم الأول',
          hint: 'أدخل الاسم الأول',
          isRequired: true,
          maxLength: 25,
          onChanged: (value) => _writeToPrefs('p3_mp_firstName', value),
        ),
        
        _buildFormField(
          controller: _mp_middleName,
          label: 'اسم الأب',
          hint: 'أدخل اسم الأب',
          maxLength: 25,
          onChanged: (value) => _writeToPrefs('p3_mp_middleName', value),
        ),
        
        _buildFormField(
          controller: _mp_qualifier,
          label: 'اللقب',
          hint: 'مثال: الابن، الأب، إلخ',
          maxLength: 10,
          onChanged: (value) => _writeToPrefs('p3_mp_qualifier', value),
        ),
        
        _buildFormField(
          controller: _mp_nickname,
          label: 'الاسم المستعار / الكنية',
          hint: 'الاسم المستعار أو الكنية',
          maxLength: 20,
          onChanged: (value) => _writeToPrefs('p3_mp_nickname', value),
        ),
        
        // الجنسية والعرق
        _buildFormField(
          controller: _mp_citizenship,
          label: 'الجنسية',
          hint: 'مثال: سعودي',
          isRequired: true,
          maxLength: 20,
          onChanged: (value) => _writeToPrefs('p3_mp_citizenship', value),
        ),
        
        _buildFormField(
          controller: _mp_nationalityEthnicity,
          label: 'القومية / العرق',
          hint: 'مثال: عربي',
          isRequired: true,
          maxLength: 20,
          onChanged: (value) => _writeToPrefs('p3_mp_nationalityEthnicity', value),
        ),
        
        // الجنس
        Text(
          'الجنس *',
          style: _bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: _textColor,
            fontSize: _bodyFontSize * 0.9,
          ),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: _verticalPadding * 0.2),
        
        Row(
          children: [
            Expanded(
              child: _buildRadioOption(
                value: 'ذكر',
                groupValue: sexValue ?? '',
                label: 'ذكر',
                onChanged: (value) {
                  setState(() {
                    sexValue = value;
                    _writeToPrefs('p3_mp_sex', value!);
                  });
                },
              ),
            ),
            SizedBox(width: _horizontalPadding * 0.3),
            Expanded(
              child: _buildRadioOption(
                value: 'أنثى',
                groupValue: sexValue ?? '',
                label: 'أنثى',
                onChanged: (value) {
                  setState(() {
                    sexValue = value;
                    _writeToPrefs('p3_mp_sex', value!);
                  });
                },
              ),
            ),
          ],
        ),
        
        // الحالة الاجتماعية
        _buildDropdownField(
          label: 'الحالة الاجتماعية',
          value: mp_civilStatValue,
          items: _saudiCivilStatus,
          isRequired: true,
          hint: 'اختر الحالة الاجتماعية',
          onChanged: (value) {
            setState(() {
              mp_civilStatValue = value;
              _writeToPrefs('p3_mp_civilStatus', value!);
            });
          },
        ),
        
        // تاريخ الميلاد
        Container(
          margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تاريخ الميلاد *',
                style: _bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                  fontSize: _bodyFontSize * 0.9,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: _verticalPadding * 0.2),
              TextFormField(
                controller: _mp_birthDate,
                readOnly: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'اختر تاريخ الميلاد',
                  hintStyle: _smallStyle.copyWith(color: _hintColor),
                  hintTextDirection: TextDirection.rtl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _primaryColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: _cardColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _horizontalPadding * 0.6,
                    vertical: _verticalPadding * 0.5,
                  ),
                  prefixIcon: Icon(Icons.calendar_today_outlined, color: _primaryColor, size: 20),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  var pickedDate = await showCalendarDatePicker2Dialog(
                    context: context,
                    config: CalendarDatePicker2WithActionButtonsConfig(
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      calendarType: CalendarDatePicker2Type.single,
                    ),
                    dialogSize: Size(325, 400),
                    value: [DateTime.now()],
                    borderRadius: BorderRadius.circular(15),
                  );
                  
                  if (pickedDate != null && pickedDate.isNotEmpty) {
                    dateTimeMPBirthDate = pickedDate[0];
                    var stringDatetimempbirthdate = dateTimeMPBirthDate.toString();
                    List returnVal = reformatDate(stringDatetimempbirthdate, dateTimeMPBirthDate!);
                    String reformattedMPBirthDate = returnVal[0];
                    ageFromMPBirthDate = returnVal[1];
                    
                    setState(() {
                      _mp_birthDate.text = reformattedMPBirthDate;
                      _mp_age.text = ageFromMPBirthDate!;
                    });
                    
                    _writeToPrefs('p3_mp_birthDate', _mp_birthDate.text);
                    _writeToPrefs('p3_mp_age', ageFromMPBirthDate!);
                    
                    if (int.parse(ageFromMPBirthDate!) < 18) {
                      _prefs.setBool('p1_isMinor', true);
                    } else {
                      _prefs.setBool('p1_isMinor', false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
        
        // العمر
        _buildFormField(
          controller: _mp_age,
          label: 'العمر',
          hint: 'سيتم حسابه تلقائياً',
          enabled: false,
          onChanged: (value) => _writeToPrefs('p3_mp_age', value),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات الاتصال',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildFormField(
          controller: _mp_contact_homePhone,
          label: '',
          hint: 'هاتف المنزل',
          keyboardType: TextInputType.phone,
          onChanged: (value) => _writeToPrefs('p3_mp_contact_homePhone', value),
        ),
        
        _buildFormField(
          controller: _mp_contact_mobilePhone,
          label: '',
          hint: 'رقم الجوال (مثال: 0512345678)',
          isRequired: true,
          keyboardType: TextInputType.phone,
          onChanged: (value) => _writeToPrefs('p3_mp_contact_mobilePhone', value),
        ),
        
        _buildFormField(
          controller: _mp_contact_mobilePhone_alt,
          label: '',
          hint: 'جوال بديل',
          keyboardType: TextInputType.phone,
          onChanged: (value) => _writeToPrefs('p3_mp_contact_mobilePhone_alt', value),
        ),
        
        _buildFormField(
          controller: _mp_contact_email,
          label: '',
          hint: 'البريد الإلكتروني',
          maxLength: 50,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => _writeToPrefs('p3_mp_contact_email', value),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العنوان',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildDropdownField(
          label: 'المنطقة',
          value: _mp_address_region.text.isEmpty ? null : _mp_address_region.text,
          items: _saudiRegions,
          isRequired: true,
          hint: 'اختر المنطقة',
          onChanged: (value) {
            setState(() {
              _mp_address_region.text = value!;
              _writeToPrefs('p3_mp_address_region', value);
            });
          },
        ),
        
        _buildDropdownField(
          label: 'المدينة',
          value: _mp_address_city.text.isEmpty ? null : _mp_address_city.text,
          items: _saudiCities,
          isRequired: true,
          hint: 'اختر المدينة',
          onChanged: (value) {
            setState(() {
              _mp_address_city.text = value!;
              _writeToPrefs('p3_mp_address_city', value);
            });
          },
        ),
        
        _buildFormField(
          controller: _mp_address_province,
          label: '',
          hint: 'المحافظة',
          isRequired: true,
          maxLength: 30,
          onChanged: (value) => _writeToPrefs('p3_mp_address_province', value),
        ),
        
        _buildFormField(
          controller: _mp_address_barangay,
          label: '',
          hint: 'الحي',
          isRequired: true,
          maxLength: 30,
          onChanged: (value) => _writeToPrefs('p3_mp_address_barangay', value),
        ),
        
        _buildFormField(
          controller: _mp_address_villageSitio,
          label: '',
          hint: 'القطعة / الشارع',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p3_mp_address_villageSitio', value),
        ),
        
        _buildFormField(
          controller: _mp_address_streetHouseNum,
          label: '',
          hint: 'رقم المنزل / الشارع',
          isRequired: true,
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p3_mp_address_streetHouseNum', value),
        ),
        
        // عنوان بديل
        _buildAlternativeAddressSection(),
      ],
    );
  }

  Widget _buildAlternativeAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _verticalPadding * 0.5),
        
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          padding: EdgeInsets.all(_horizontalPadding * 0.6),
          child: Row(
            children: [
              Checkbox(
                value: mp_hasAltAddress,
                activeColor: _primaryColor,
                onChanged: (bool? value) {
                  setState(() {
                    mp_hasAltAddress = value!;
                    if (value == true) {
                      widget.addHeightParent();
                    } else {
                      widget.subtractHeightParent();
                    }
                    _prefs.setBool('p3_mp_hasAltAddress', value);
                  });
                },
              ),
              Expanded(
                child: Text(
                  'هل لدى الشخص المفقود عنوان آخر؟',
                  style: _bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: _bodyFontSize * 0.9,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
        
        if (mp_hasAltAddress) ...[
          SizedBox(height: _verticalPadding * 0.5),
          Text(
            'العنوان البديل',
            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 0.95),
          ),
          SizedBox(height: _verticalPadding * 0.3),
          
          _buildDropdownField(
            label: 'المنطقة البديلة',
            value: _mp_address_region_alt.text.isEmpty ? null : _mp_address_region_alt.text,
            items: _saudiRegions,
            hint: 'اختر المنطقة',
            onChanged: (value) {
              setState(() {
                _mp_address_region_alt.text = value!;
                _writeToPrefs('p3_mp_address_region_alt', value);
              });
            },
          ),
          
          _buildDropdownField(
            label: 'المدينة البديلة',
            value: _mp_address_city_alt.text.isEmpty ? null : _mp_address_city_alt.text,
            items: _saudiCities,
            hint: 'اختر المدينة',
            onChanged: (value) {
              setState(() {
                _mp_address_city_alt.text = value!;
                _writeToPrefs('p3_mp_address_city_alt', value);
              });
            },
          ),
          
          _buildFormField(
            controller: _mp_address_province_alt,
            label: '',
            hint: 'المحافظة البديلة',
            maxLength: 30,
            onChanged: (value) => _writeToPrefs('p3_mp_address_province_alt', value),
          ),
          
          _buildFormField(
            controller: _mp_address_barangay_alt,
            label: '',
            hint: 'الحي البديل',
            maxLength: 30,
            onChanged: (value) => _writeToPrefs('p3_mp_address_barangay_alt', value),
          ),
          
          _buildFormField(
            controller: _mp_address_villageSitio_alt,
            label: '',
            hint: 'القطعة / الشارع البديل',
            maxLength: 50,
            onChanged: (value) => _writeToPrefs('p3_mp_address_villageSitio_alt', value),
          ),
          
          _buildFormField(
            controller: _mp_address_streetHouseNum_alt,
            label: '',
            hint: 'رقم المنزل / الشارع البديل',
            maxLength: 50,
            onChanged: (value) => _writeToPrefs('p3_mp_address_streetHouseNum_alt', value),
          ),
        ],
      ],
    );
  }

  Widget _buildEducationOccupationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المؤهل العلمي والمهنة',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildDropdownField(
          label: 'أعلى مؤهل علمي',
          value: mp_educationalAttainment,
          items: _saudiEducation,
          isRequired: true,
          hint: 'اختر المؤهل العلمي',
          onChanged: (value) {
            setState(() {
              mp_educationalAttainment = value;
              _writeToPrefs('p3_mp_education', value!);
            });
          },
        ),
        
        _buildFormField(
          controller: _mp_occupation,
          label: '',
          hint: 'المهنة',
          maxLength: 30,
          onChanged: (value) => _writeToPrefs('p3_mp_occupation', value),
        ),
        
        // عنوان العمل/الدراسة
        _buildWorkSchoolSection(),
      ],
    );
  }

  Widget _buildWorkSchoolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _verticalPadding * 0.5),
        
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          padding: EdgeInsets.all(_horizontalPadding * 0.6),
          child: Row(
            children: [
              Checkbox(
                value: mp_hasSchoolWorkAddress,
                activeColor: _primaryColor,
                onChanged: (bool? value) {
                  setState(() {
                    mp_hasSchoolWorkAddress = value!;
                    if (value == true) {
                      widget.addHeightParent();
                    } else {
                      widget.subtractHeightParent();
                    }
                    _prefs.setBool('p3_mp_hasSchoolWorkAddress', value);
                  });
                },
              ),
              Expanded(
                child: Text(
                  'هل لدى الشخص المفقود عنوان عمل أو دراسة؟',
                  style: _bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: _bodyFontSize * 0.9,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
        
        if (mp_hasSchoolWorkAddress) ...[
          SizedBox(height: _verticalPadding * 0.5),
          Text(
            'عنوان العمل/الدراسة',
            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 0.95),
          ),
          SizedBox(height: _verticalPadding * 0.3),
          
          _buildFormField(
            controller: _mp_workSchool_name,
            label: '',
            hint: 'اسم العمل أو المؤسسة التعليمية',
            maxLength: 30,
            onChanged: (value) => _writeToPrefs('p3_mp_workSchool_name', value),
          ),
          
          _buildDropdownField(
            label: 'منطقة العمل/الدراسة',
            value: _mp_workSchool_region.text.isEmpty ? null : _mp_workSchool_region.text,
            items: _saudiRegions,
            hint: 'اختر المنطقة',
            onChanged: (value) {
              setState(() {
                _mp_workSchool_region.text = value!;
                _writeToPrefs('p3_mp_workSchool_region', value);
              });
            },
          ),
          
          _buildDropdownField(
            label: 'مدينة العمل/الدراسة',
            value: _mp_workSchool_city.text.isEmpty ? null : _mp_workSchool_city.text,
            items: _saudiCities,
            hint: 'اختر المدينة',
            onChanged: (value) {
              setState(() {
                _mp_workSchool_city.text = value!;
                _writeToPrefs('p3_mp_workSchool_city', value);
              });
            },
          ),
          
          _buildFormField(
            controller: _mp_workSchool_province,
            label: '',
            hint: 'محافظة العمل/الدراسة',
            maxLength: 30,
            onChanged: (value) => _writeToPrefs('p3_mp_workSchool_province', value),
          ),
          
          _buildFormField(
            controller: _mp_workSchool_barangay,
            label: '',
            hint: 'حي العمل/الدراسة',
            maxLength: 30,
            onChanged: (value) => _writeToPrefs('p3_mp_workSchool_barangay', value),
          ),
          
          _buildFormField(
            controller: _mp_workSchool_villageSitio,
            label: '',
            hint: 'القطعة / الشارع',
            maxLength: 50,
            onChanged: (value) => _writeToPrefs('p3_mp_workSchool_villageSitio', value),
          ),
          
          _buildFormField(
            controller: _mp_workSchool_streetHouseNum,
            label: '',
            hint: 'رقم المبنى / الشارع',
            maxLength: 50,
            onChanged: (value) => _writeToPrefs('p3_mp_workSchool_streetHouseNum', value),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: EdgeInsets.all(_horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Lottie.asset(
            "assets/lottie/swipeLeft.json",
            animate: true,
            width: MediaQuery.of(context).size.width * 0.08,
            height: MediaQuery.of(context).size.width * 0.08,
          ),
          SizedBox(width: _horizontalPadding * 0.4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'نهاية نموذج تفاصيل الشخص المفقود',
                  style: _smallStyle.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: _verticalPadding * 0.2),
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
        ],
      ),
    );
  }
}