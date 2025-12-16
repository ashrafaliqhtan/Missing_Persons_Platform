import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* DATE PICKER SETUP */
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

/* END OF DATE PICKER SETUP */

/* Stateful Widget Class */
class Page2ReporteeDetails extends StatefulWidget {
  final VoidCallback addHeightParent;
  final VoidCallback subtractHeightParent;
  final VoidCallback defaultHeightParent;
  
  const Page2ReporteeDetails({
    super.key,
    required this.addHeightParent,
    required this.subtractHeightParent,
    required this.defaultHeightParent,
  });

  @override
  State<Page2ReporteeDetails> createState() => _Page2ReporteeDetailsState();
}

late SharedPreferences _prefs;

class _Page2ReporteeDetailsState extends State<Page2ReporteeDetails> {
  PlatformFile? pickedFile;
  Uint8List? pickedFileBytes;

  Uint8List? reportee_ID_Photo;
  Uint8List? singlePhoto_face;
  String? relationshipToMP;
  String? citizenship;
  String? civil_status;
  String? homePhone;
  String? mobilePhone;
  String? altMobilePhone;
  String? region;
  String? province;
  String? townCity;
  String? barangay;
  String? villageSitio;
  String? streetHouseNum;
  String? altRegion;
  String? altProvince;
  String? altTownCity;
  String? altBarangay;
  String? altVillageSitio;
  String? altStreetHouseNum;
  String? highestEduc;
  String? occupation;

  // ألوان مخصصة للمملكة العربية السعودية
  final Color _primaryColor = Color(0xFF006400); // أخضر داكن
  final Color _accentColor = Color(0xFFCE1126); // أحمر
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _borderColor = Color(0xFFDEE2E6);

  // أحجام خطوط متجاوبة
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.065;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.04;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.035;
  
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
    height: 1.5,
  );

  TextStyle get _smallStyle => TextStyle(
    fontSize: _smallFontSize,
    fontWeight: FontWeight.w400,
    color: _hintColor,
    fontFamily: 'Tajawal',
    height: 1.4,
  );

  TextStyle get _headingStyle => TextStyle(
    fontSize: _bodyFontSize * 1.1,
    fontWeight: FontWeight.w600,
    color: _primaryColor,
    fontFamily: 'Tajawal',
  );

  // متغير للتحكم في التمرير
  final ScrollController _scrollController = ScrollController();

  Future<void> loadImages() async {
    String? reportee_ID_Photo_String = _prefs.getString('p2_reportee_ID_Photo');
    if (reportee_ID_Photo_String == null) {
      print('[p2] No ID photo');
      return;
    } else {
      setState(() {
        reportee_ID_Photo = base64Decode(reportee_ID_Photo_String);
      });
    }
  }

  Future<void> loadImage_face() async {
    String? singlePhotoStringFace = _prefs.getString('p2_reporteeSelfie');
    if (singlePhotoStringFace == null) {
      print('[p2] No user selfie ');
      return;
    } else {
      setState(() {
        singlePhoto_face = base64Decode(singlePhotoStringFace);
      });
    }
  }

  Future<void> saveImages() async {
    if (reportee_ID_Photo != null) {
      _prefs.setString(
          'p2_reportee_ID_Photo', base64Encode(reportee_ID_Photo!));
    }
    if (singlePhoto_face != null) {
      _prefs.setString('p2_reporteeSelfie', base64Encode(singlePhoto_face!));
    }
  }

  Future<void> getImages() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _writeToPrefs('p2_reportee_ID_Photo_PATH', file.path);
      });
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        reportee_ID_Photo = imageBytes;
      });
      await saveImages();
    }
  }

  Future<void> getImageFace() async {
    final pickerFace = ImagePicker();
    final pickedFileFace =
        await pickerFace.pickImage(source: ImageSource.camera);
    if (pickedFileFace != null) {
      final file = File(pickedFileFace.path);
      setState(() {
        _writeToPrefs('p2_reporteeSelfie_PATH', file.path);
      });
      final imageBytesFace = await pickedFileFace.readAsBytes();
      setState(() {
        singlePhoto_face = imageBytesFace;
      });
      await saveImages();
    }
  }

  bool isDrafted = false;
  Future<void> getReporteeInfo() async {
    _prefs = await SharedPreferences.getInstance();
    loadImages();
    loadImage_face();
    setState(() {
      widget.defaultHeightParent();
      reportee_hasAltAddress = _prefs.getBool('p2_hasAltAddress') ?? false;
      reportee_hasAltAddress ? widget.addHeightParent() : null;

      if (_prefs.getString('p2_civil_status') != null) {
        _civilStatusValue = _prefs.getString('p2_civil_status');
      }

      if (_prefs.getString('p2_highestEduc') != null) {
        _highestEduc = _prefs.getString('p2_highestEduc');
      }

      relationshipToMP = _prefs.getString('p2_relationshipToMP');
      if (relationshipToMP != null) {
        _reporteeRelationshipToMissingPerson.text = relationshipToMP!;
      }

      citizenship = _prefs.getString('p2_citizenship');
      if (citizenship != null) {
        _reporteeCitizenship.text = citizenship!;
      }

      civil_status = _prefs.getString('p2_civil_status');
      if (civil_status != null) {
        _reporteeCivilStatus.text = civil_status!;
      }

      homePhone = _prefs.getString('p2_homePhone');
      if (homePhone != null) {
        _reporteeHomePhone.text = homePhone!;
      }

      mobilePhone = _prefs.getString('p2_mobilePhone');
      if (mobilePhone != null) {
        _reporteeMobilePhone.text = mobilePhone!;
      }

      altMobilePhone = _prefs.getString('p2_altMobilePhone');
      if (altMobilePhone != null) {
        _reporteeAlternateMobilePhone.text = altMobilePhone!;
      }

      region = _prefs.getString('p2_region');
      if (region != null) {
        _reporteeRegion.text = region!;
      }

      province = _prefs.getString('p2_province');
      if (province != null) {
        _reporteeProvince.text = province!;
      }

      townCity = _prefs.getString('p2_townCity');
      if (townCity != null) {
        _reporteeCity.text = townCity!;
      }

      barangay = _prefs.getString('p2_barangay');
      if (barangay != null) {
        _reporteeBarangay.text = barangay!;
      }

      villageSitio = _prefs.getString('p2_villageSitio');
      if (villageSitio != null) {
        _reporteeVillageSitio.text = villageSitio!;
      }

      streetHouseNum = _prefs.getString('p2_streetHouseNum');
      if (streetHouseNum != null) {
        _reporteeStreetHouseNum.text = streetHouseNum!;
      }

      altRegion = _prefs.getString('p2_altRegion');
      if (altRegion != null) {
        _reporteeAltRegion.text = altRegion!;
      }

      altProvince = _prefs.getString('p2_altProvince');
      if (altProvince != null) {
        _reporteeAltProvince.text = altProvince!;
      }

      altTownCity = _prefs.getString('p2_altTownCity');
      if (altTownCity != null) {
        _reporteeAltCityTown.text = altTownCity!;
      }

      altBarangay = _prefs.getString('p2_altBarangay');
      if (altBarangay != null) {
        _reporteeAltBarangay.text = altBarangay!;
      }

      altVillageSitio = _prefs.getString('p2_altVillageSitio');
      if (altVillageSitio != null) {
        _reporteeAltVillageSitio.text = altVillageSitio!;
      }

      altStreetHouseNum = _prefs.getString('p2_altStreetHouseNum');
      if (altStreetHouseNum != null) {
        _reporteeAltStreetHouseNum.text = altStreetHouseNum!;
      }

      highestEduc = _prefs.getString('p2_highestEduc');
      if (highestEduc != null) {
        _reporteeHighestEduc.text = highestEduc!;
      }
      occupation = _prefs.getString('p2_occupation');
      if (occupation != null) {
        _reporteeOccupation.text = occupation!;
      }
    });
  }

  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );
    if (result == null) return;

    setState(() {
      pickedFile = result.files.first;
      pickedFileBytes = pickedFile!.bytes;
    });
  }

  /* SHARED PREF EMPTY CHECKER AND SAVER FUNCTION*/
  Future<void> _writeToPrefs(String key, String value) async {
    if (value != '') {
      await _prefs.setString(key, value);
    } else {
      await _prefs.remove(key);
    }
  }

/* VARIABLES AND CONTROLLERS */
  late final TextEditingController _reporteeCitizenship;
  late final TextEditingController _reporteeCivilStatus;
  late final TextEditingController _reporteeBirthdayController;
  String? ageFromBday;
  late final TextEditingController _reporteeHomePhone;
  late final TextEditingController _reporteeMobilePhone;
  late final TextEditingController _reporteeAlternateMobilePhone;
  late final TextEditingController _reporteeEmail;
  late final TextEditingController _reporteeRegion;
  late final TextEditingController _reporteeProvince;
  late final TextEditingController _reporteeCity;
  late final TextEditingController _reporteeBarangay;
  late final TextEditingController _reporteeVillageSitio;
  late final TextEditingController _reporteeStreetHouseNum;
  bool reportee_hasAltAddress = false;
  late final TextEditingController _reporteeAltRegion;
  late final TextEditingController _reporteeAltProvince;
  late final TextEditingController _reporteeAltCityTown;
  late final TextEditingController _reporteeAltBarangay;
  late final TextEditingController _reporteeAltVillageSitio;
  late final TextEditingController _reporteeAltStreetHouseNum;
  late final TextEditingController _reporteeHighestEduc;
  late final TextEditingController _reporteeOccupation;
  late final TextEditingController _reporteeID;
  late final TextEditingController _reporteePhoto;
  late final TextEditingController _reporteeRelationshipToMissingPerson;

  String? _civilStatusValue;
  DateTime? dateTimeBday;
  String? _highestEduc;
  bool? reportee_AltAddress_available = false;

  late final TextEditingController _dateOfBirthController;

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

  @override
  void initState() {
    try {
      if (kDebugMode) {
        print('[PREFS] ${_prefs.getKeys()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PREFS] No prefs found: ${e.toString()}');
      }
    }
    _reporteeCitizenship = TextEditingController();
    _reporteeCivilStatus = TextEditingController();
    _reporteeBirthdayController = TextEditingController();
    _reporteeHomePhone = TextEditingController();
    _reporteeMobilePhone = TextEditingController();
    _reporteeAlternateMobilePhone = TextEditingController();
    _reporteeEmail = TextEditingController();
    _reporteeRegion = TextEditingController();
    _reporteeProvince = TextEditingController();
    _reporteeCity = TextEditingController();
    _reporteeBarangay = TextEditingController();
    _reporteeVillageSitio = TextEditingController();
    _reporteeStreetHouseNum = TextEditingController();
    _reporteeAltRegion = TextEditingController();
    _reporteeAltProvince = TextEditingController();
    _reporteeAltCityTown = TextEditingController();
    _reporteeAltBarangay = TextEditingController();
    _reporteeAltVillageSitio = TextEditingController();
    _reporteeAltStreetHouseNum = TextEditingController();
    _reporteeHighestEduc = TextEditingController();
    _reporteeOccupation = TextEditingController();
    _reporteeID = TextEditingController();
    _reporteePhoto = TextEditingController();
    _reporteeRelationshipToMissingPerson = TextEditingController();
    _dateOfBirthController = TextEditingController();
    getReporteeInfo();
    super.initState();
  }

  @override
  void dispose() {
    _reporteeCitizenship.dispose();
    _reporteeCivilStatus.dispose();
    _reporteeBirthdayController.dispose();
    _reporteeHomePhone.dispose();
    _reporteeMobilePhone.dispose();
    _reporteeAlternateMobilePhone.dispose();
    _reporteeEmail.dispose();
    _reporteeRegion.dispose();
    _reporteeProvince.dispose();
    _reporteeCity.dispose();
    _reporteeBarangay.dispose();
    _reporteeVillageSitio.dispose();
    _reporteeStreetHouseNum.dispose();
    _reporteeAltRegion.dispose();
    _reporteeAltProvince.dispose();
    _reporteeAltCityTown.dispose();
    _reporteeAltBarangay.dispose();
    _reporteeAltVillageSitio.dispose();
    _reporteeAltStreetHouseNum.dispose();
    _reporteeHighestEduc.dispose();
    _reporteeOccupation.dispose();
    _reporteeID.dispose();
    _reporteePhoto.dispose();
    _dateOfBirthController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // error message: empty field
  static const String _emptyFieldError = 'هذا الحقل مطلوب';

  // دالة مساعدة لبناء حقل النموذج
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              isRequired ? '$label *' : label,
              style: _bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: _verticalPadding * 0.3),
          ],
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: _smallStyle.copyWith(color: _hintColor),
              hintTextDirection: TextDirection.rtl,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              filled: true,
              fillColor: _cardColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _horizontalPadding * 0.8,
                vertical: _verticalPadding * 0.6,
              ),
            ),
            onChanged: onChanged ?? (text) {
              if (onChanged != null) onChanged(text);
            },
            validator: isRequired ? (value) {
              if (value == null || value.isEmpty) {
                return _emptyFieldError;
              }
              return null;
            } : null,
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
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
            style: _bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: _verticalPadding * 0.3),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
              color: _cardColor,
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding * 0.8,
                  vertical: _verticalPadding * 0.4,
                ),
                hintText: hint,
                hintStyle: _smallStyle.copyWith(color: _hintColor),
                hintTextDirection: TextDirection.rtl,
              ),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              iconSize: 24,
              elevation: 16,
              style: _bodyStyle,
              dropdownColor: _cardColor,
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    textDirection: TextDirection.rtl,
                    style: _bodyStyle,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
                padding: EdgeInsets.all(_horizontalPadding),
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
                child: _buildHeaderSection(),
              ),
              
              // محتوى قابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(_horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: _verticalPadding),
                      
                      // Information Card
                      _buildInfoCard(),
                      
                      SizedBox(height: _verticalPadding * 1.5),
                      
                      // Relationship Section
                      _buildRelationshipSection(),
                      
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
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Identity Proof Section
                      _buildIdentityProofSection(),
                      
                      SizedBox(height: _verticalPadding * 2),
                      
                      // Footer Section
                      _buildFooterSection(),
                      
                      // مسافة إضافية في الأسفل للتأكد من رؤية كل المحتوى
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
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
              width: MediaQuery.of(context).size.width * 0.2,
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
        
        SizedBox(height: _verticalPadding * 1.2),
        
        // Title and Subtitle in one row to save space
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل المُبلِّغ',
                    style: _titleStyle,
                  ),
                  SizedBox(height: _verticalPadding * 0.3),
                  Text(
                    'الصفحة ٢ من ٦',
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
      padding: EdgeInsets.all(_horizontalPadding * 0.8),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: _bodyFontSize * 1.2, color: _primaryColor),
          SizedBox(width: _horizontalPadding * 0.6),
          Expanded(
            child: Text(
              'الحقول المميزة بعلامة (*) إلزامية',
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

  Widget _buildRelationshipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العلاقة بالمفقود',
          style: _headingStyle,
        ),
        SizedBox(height: _verticalPadding * 0.5),
        _buildFormField(
          controller: _reporteeRelationshipToMissingPerson,
          label: '',
          hint: 'أدخل العلاقة (أب، أم، أخ، قريب، إلخ)',
          isRequired: true,
          maxLength: 30,
          onChanged: (text) => _writeToPrefs('p2_relationshipToMP', text),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المعلومات الشخصية',
          style: _headingStyle,
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        // الجنسية
        _buildFormField(
          controller: _reporteeCitizenship,
          label: '',
          hint: 'أدخل الجنسية (مثال: سعودي)',
          isRequired: true,
          maxLength: 30,
          onChanged: (text) => _writeToPrefs('p2_citizenship', text),
        ),
        
        // الحالة الاجتماعية
        _buildDropdownField(
          label: 'الحالة الاجتماعية',
          value: _civilStatusValue,
          items: _saudiCivilStatus,
          isRequired: true,
          hint: 'اختر الحالة الاجتماعية',
          onChanged: (value) {
            setState(() {
              _civilStatusValue = value;
              _writeToPrefs('p2_civil_status', value!);
            });
          },
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
          style: _headingStyle,
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildFormField(
          controller: _reporteeHomePhone,
          label: '',
          hint: 'هاتف المنزل (اختياري)',
          keyboardType: TextInputType.phone,
          onChanged: (text) => _writeToPrefs('p2_homePhone', text),
        ),
        
        _buildFormField(
          controller: _reporteeMobilePhone,
          label: '',
          hint: 'رقم الجوال (مثال: 0512345678)',
          isRequired: true,
          keyboardType: TextInputType.phone,
          onChanged: (text) => _writeToPrefs('p2_mobilePhone', text),
        ),
        
        _buildFormField(
          controller: _reporteeAlternateMobilePhone,
          label: '',
          hint: 'جوال بديل (اختياري)',
          keyboardType: TextInputType.phone,
          onChanged: (text) => _writeToPrefs('p2_altMobilePhone', text),
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
          style: _headingStyle,
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        // المنطقة
        _buildDropdownField(
          label: 'المنطقة',
          value: _reporteeRegion.text.isEmpty ? null : _reporteeRegion.text,
          items: _saudiRegions,
          isRequired: true,
          hint: 'اختر المنطقة',
          onChanged: (value) {
            setState(() {
              _reporteeRegion.text = value!;
              _writeToPrefs('p2_region', value);
            });
          },
        ),
        
        // المدينة
        _buildDropdownField(
          label: 'المدينة',
          value: _reporteeCity.text.isEmpty ? null : _reporteeCity.text,
          items: _saudiCities,
          isRequired: true,
          hint: 'اختر المدينة',
          onChanged: (value) {
            setState(() {
              _reporteeCity.text = value!;
              _writeToPrefs('p2_townCity', value);
            });
          },
        ),
        
        _buildFormField(
          controller: _reporteeProvince,
          label: '',
          hint: 'المحافظة',
          isRequired: true,
          maxLength: 30,
          onChanged: (text) => _writeToPrefs('p2_province', text),
        ),
        
        _buildFormField(
          controller: _reporteeBarangay,
          label: '',
          hint: 'الحي',
          isRequired: true,
          maxLength: 30,
          onChanged: (text) => _writeToPrefs('p2_barangay', text),
        ),
        
        _buildFormField(
          controller: _reporteeVillageSitio,
          label: '',
          hint: 'القطعة / الشارع (اختياري)',
          maxLength: 30,
          onChanged: (text) => _writeToPrefs('p2_villageSitio', text),
        ),
        
        _buildFormField(
          controller: _reporteeStreetHouseNum,
          label: '',
          hint: 'رقم المنزل / الشارع',
          isRequired: true,
          maxLength: 30,
          onChanged: (text) => _writeToPrefs('p2_streetHouseNum', text),
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
        SizedBox(height: _verticalPadding),
        
        // عنوان بديل
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          padding: EdgeInsets.all(_horizontalPadding * 0.8),
          child: Row(
            children: [
              Checkbox(
                value: reportee_hasAltAddress,
                activeColor: _primaryColor,
                onChanged: (bool? value) {
                  setState(() {
                    reportee_hasAltAddress = value!;
                    if (value == true) {
                      widget.addHeightParent();
                    } else {
                      widget.subtractHeightParent();
                    }
                    _prefs.setBool('p2_hasAltAddress', value);
                  });
                },
              ),
              Expanded(
                child: Text(
                  'هل لديك عنوان آخر؟',
                  style: _bodyStyle.copyWith(fontWeight: FontWeight.w500),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
        
        if (reportee_hasAltAddress) ...[
          SizedBox(height: _verticalPadding),
          Text(
            'العنوان البديل',
            style: _headingStyle.copyWith(fontSize: _bodyFontSize),
          ),
          SizedBox(height: _verticalPadding * 0.5),
          
          _buildDropdownField(
            label: 'المنطقة البديلة',
            value: _reporteeAltRegion.text.isEmpty ? null : _reporteeAltRegion.text,
            items: _saudiRegions,
            hint: 'اختر المنطقة',
            onChanged: (value) {
              setState(() {
                _reporteeAltRegion.text = value!;
                _writeToPrefs('p2_altRegion', value);
              });
            },
          ),
          
          _buildDropdownField(
            label: 'المدينة البديلة',
            value: _reporteeAltCityTown.text.isEmpty ? null : _reporteeAltCityTown.text,
            items: _saudiCities,
            hint: 'اختر المدينة',
            onChanged: (value) {
              setState(() {
                _reporteeAltCityTown.text = value!;
                _writeToPrefs('p2_altTownCity', value);
              });
            },
          ),
          
          _buildFormField(
            controller: _reporteeAltProvince,
            label: '',
            hint: 'المحافظة البديلة',
            maxLength: 30,
            onChanged: (text) => _writeToPrefs('p2_altProvince', text),
          ),
          
          _buildFormField(
            controller: _reporteeAltBarangay,
            label: '',
            hint: 'الحي البديل',
            maxLength: 30,
            onChanged: (text) => _writeToPrefs('p2_altBarangay', text),
          ),
          
          _buildFormField(
            controller: _reporteeAltVillageSitio,
            label: '',
            hint: 'القطعة / الشارع البديل',
            maxLength: 50,
            onChanged: (text) => _writeToPrefs('p2_altVillageSitio', text),
          ),
          
          _buildFormField(
            controller: _reporteeAltStreetHouseNum,
            label: '',
            hint: 'رقم المنزل / الشارع البديل',
            maxLength: 50,
            onChanged: (text) => _writeToPrefs('p2_altStreetHouseNum', text),
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
          style: _headingStyle,
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildDropdownField(
          label: 'أعلى مؤهل علمي',
          value: _highestEduc,
          items: _saudiEducation,
          isRequired: true,
          hint: 'اختر المؤهل العلمي',
          onChanged: (value) {
            setState(() {
              _highestEduc = value;
              _writeToPrefs('p2_highestEduc', value!);
            });
          },
        ),
        
        _buildFormField(
          controller: _reporteeOccupation,
          label: '',
          hint: 'المهنة',
          maxLength: 20,
          onChanged: (text) => _writeToPrefs('p2_occupation', text),
        ),
      ],
    );
  }

  Widget _buildIdentityProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إثبات الهوية',
          style: _headingStyle,
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        // بطاقة الهوية
        _buildIDCardSection(),
        
        SizedBox(height: _verticalPadding),
        
        // صورة شخصية
        _buildSelfieSection(),
      ],
    );
  }

  Widget _buildIDCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بطاقة الهوية *',
          style: _bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          padding: EdgeInsets.all(_horizontalPadding * 0.8),
          child: Column(
            children: [
              reportee_ID_Photo != null
                  ? Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(reportee_ID_Photo!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.perm_identity,
                          size: 60,
                          color: _hintColor,
                        ),
                        SizedBox(height: _verticalPadding * 0.5),
                        Text(
                          "لم يتم اختيار بطاقة هوية",
                          style: _smallStyle.copyWith(color: _hintColor),
                        ),
                      ],
                    ),
              
              SizedBox(height: _verticalPadding),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: _verticalPadding * 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: getImages,
                  child: Text(
                    "رفع بطاقة الهوية",
                    style: _bodyStyle.copyWith(
                      color: Colors.white,
                      fontSize: _bodyFontSize * 0.9,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelfieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صورة شخصية *',
          style: _bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          padding: EdgeInsets.all(_horizontalPadding * 0.8),
          child: Column(
            children: [
              singlePhoto_face != null
                  ? Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(singlePhoto_face!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.camera_front_outlined,
                          size: 60,
                          color: _hintColor,
                        ),
                        SizedBox(height: _verticalPadding * 0.5),
                        Text(
                          'لم يتم التقاط صورة شخصية',
                          style: _smallStyle.copyWith(color: _hintColor),
                        ),
                      ],
                    ),
              
              SizedBox(height: _verticalPadding),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: _verticalPadding * 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: getImageFace,
                  child: Text(
                    "التقاط صورة شخصية",
                    style: _bodyStyle.copyWith(
                      color: Colors.white,
                      fontSize: _bodyFontSize * 0.9,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Lottie.asset(
            "assets/lottie/swipeLeft.json",
            animate: true,
            width: MediaQuery.of(context).size.width * 0.10,
            height: MediaQuery.of(context).size.width * 0.10,
          ),
          SizedBox(width: _horizontalPadding * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'نهاية نموذج تفاصيل المُبلِّغ',
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
        ],
      ),
    );
  }
}