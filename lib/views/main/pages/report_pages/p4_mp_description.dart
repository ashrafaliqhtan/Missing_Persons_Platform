import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:Missing_Persons_Platform/main.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/* SHARED PREFERENCE */
late SharedPreferences _prefs;
void clearPrefs() {
  _prefs.clear();
}

/* PAGE 4 */
class Page4MPDesc extends StatefulWidget {
  final VoidCallback addHeightParent;
  final VoidCallback subtractHeightParent;
  final VoidCallback defaultHeightParent;
  const Page4MPDesc({
    super.key,
    required this.addHeightParent,
    required this.subtractHeightParent,
    required this.defaultHeightParent,
  });

  @override
  State<Page4MPDesc> createState() => _Page4MPDescState();
}

/* PAGE 4 STATE */
class _Page4MPDescState extends State<Page4MPDesc> {
  // ألوان مخصصة للمملكة العربية السعودية
  final Color _primaryColor = Color(0xFF006400); // أخضر داكن
  final Color _accentColor = Color(0xFFCE1126); // أحمر
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _borderColor = Color(0xFFDEE2E6);

  // أحجام خطوط متجاوبة
  double get _titleFontSize => MediaQuery.of(_currentContext).size.width * 0.06;
  double get _bodyFontSize => MediaQuery.of(_currentContext).size.width * 0.038;
  double get _smallFontSize => MediaQuery.of(_currentContext).size.width * 0.033;
  
  // مسافات متجاوبة
  double get _verticalPadding => MediaQuery.of(_currentContext).size.height * 0.012;
  double get _horizontalPadding => MediaQuery.of(_currentContext).size.width * 0.04;

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

  // متغير لحفظ context الحالي
  late BuildContext _currentContext;

  String userUID = FirebaseAuth.instance.currentUser!.uid;
  Reference reportRef = FirebaseStorage.instance.ref().child('Reports');
  
  /* VARIABLES */
  // MP Appearance
  String mpImageURL = '';
  String? mp_scars;
  String? mp_marks;
  String? mp_tattoos;
  String? mp_hair_color;
  bool? mp_hair_color_natural;
  String? mp_eye_color;
  bool? mp_eye_color_natural;
  String? mp_prosthetics;
  String? mp_birth_defects;
  String? last_clothing;
  // MP medical details
  String? mp_height_feet;
  String? mp_height_inches;
  String? mp_weight;
  String? mp_blood_typeValue;
  String? mp_medications;
  // MP socmed details
  String? mp_facebook;
  String? mp_twitter;
  String? mp_instagram;
  String? mp_socmed_other_platform;
  String? mp_socmed_other_username;
  // Photos
  Uint8List? mp_recent_photo;
  Uint8List? mp_dental_record_photo;
  Uint8List? mp_finger_print_record_photo;
  // Boolean variables for checkboxes
  bool? mp_dental_available = false;
  bool? mp_fingerprints_available = false;

  // all controlers for text fields
  late final TextEditingController _mp_scars = TextEditingController();
  late final TextEditingController _mp_marks = TextEditingController();
  late final TextEditingController _mp_tattoos = TextEditingController();
  late final TextEditingController _mp_hair_color = TextEditingController();
  late final TextEditingController _mp_eye_color = TextEditingController();
  late final TextEditingController _mp_prosthetics = TextEditingController();
  late final TextEditingController _mp_birth_defects = TextEditingController();
  late final TextEditingController _mp_last_clothing = TextEditingController();
  late final TextEditingController _mp_height_feet = TextEditingController();
  late final TextEditingController _mp_height_inches = TextEditingController();
  late final TextEditingController _mp_weight = TextEditingController();
  late final TextEditingController _mp_blood_type = TextEditingController();
  late final TextEditingController _mp_medications = TextEditingController();
  // socmed details
  late final TextEditingController _mp_facebook = TextEditingController();
  late final TextEditingController _mp_twitter = TextEditingController();
  late final TextEditingController _mp_instagram = TextEditingController();
  late final TextEditingController _mp_socmed_other_platform = TextEditingController();
  late final TextEditingController _mp_socmed_other_username = TextEditingController();

  // قوائم منسدلة
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'غير معروف'
  ];

  // dispose all controllers
  @override
  void dispose() {
    _mp_scars.dispose();
    _mp_marks.dispose();
    _mp_tattoos.dispose();
    _mp_hair_color.dispose();
    _mp_eye_color.dispose();
    _mp_prosthetics.dispose();
    _mp_birth_defects.dispose();
    _mp_last_clothing.dispose();
    _mp_height_feet.dispose();
    _mp_height_inches.dispose();
    _mp_weight.dispose();
    _mp_blood_type.dispose();
    _mp_medications.dispose();
    _mp_facebook.dispose();
    _mp_twitter.dispose();
    _mp_instagram.dispose();
    _mp_socmed_other_platform.dispose();
    _mp_socmed_other_username.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  late String reportCount;
  
  retrieveUserData() async {
    _prefs = await SharedPreferences.getInstance();
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

  // save images to shared preference
  Future<void> _saveImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mp_recent_photo != null) {
      String mpRecentPhotoString = base64Encode(mp_recent_photo!);
      prefs.setString('p4_mp_recent_photo', mpRecentPhotoString);
    }
    if (mp_dental_record_photo != null) {
      String mpDentalRecordPhotoString = base64Encode(mp_dental_record_photo!);
      prefs.setString('p4_mp_dental_record_photo', mpDentalRecordPhotoString);
    }
    if (mp_finger_print_record_photo != null) {
      String mpFingerPrintRecordPhotoString = base64Encode(mp_finger_print_record_photo!);
      prefs.setString('p4_mp_finger_print_record_photo', mpFingerPrintRecordPhotoString);
    }
  }

  // get images from shared preference
  Future<void> _getImages(String photoType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      try {
        final file = File(pickedFile.path);
        setState(() {
          _writeToPrefs('p4_${photoType}_PATH', file.path);
        });
      } catch (e) {
        print('[ERROR] $e');
      }
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        if (photoType == 'mp_recent_photo') {
          mp_recent_photo = imageBytes;
        } else if (photoType == 'mp_dental_record_photo') {
          mp_dental_record_photo = imageBytes;
        } else if (photoType == 'mp_finger_print_record_photo') {
          mp_finger_print_record_photo = imageBytes;
        }
      });
      await _saveImages();
    }
  }

  // load images from shared preference
  Future<void> _loadImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('p4_mp_recent_photo') != null) {
      String mpRecentPhotoString = prefs.getString('p4_mp_recent_photo')!;
      mp_recent_photo = base64Decode(mpRecentPhotoString);
    }
    if (prefs.getString('p4_mp_dental_record_photo') != null) {
      String mpDentalRecordPhotoString = prefs.getString('p4_mp_dental_record_photo')!;
      mp_dental_record_photo = base64Decode(mpDentalRecordPhotoString);
    }
    if (prefs.getString('p4_mp_finger_print_record_photo') != null) {
      String mpFingerPrintRecordPhotoString = prefs.getString('p4_mp_finger_print_record_photo')!;
      mp_finger_print_record_photo = base64Decode(mpFingerPrintRecordPhotoString);
    }
  }

  /* SHARED PREF EMPTY CHECKER AND SAVER FUNCTION*/
  Future<void> _writeToPrefs(String key, String value) async {
    if (value != '') {
      _prefs.setString(key, value);
    } else {
      _prefs.remove(key);
    }
  }

  Future<void> getBoolChoices() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      mp_hair_color_natural = _prefs.getBool('p4_mp_hair_color_natural') ?? true;
      mp_eye_color_natural = _prefs.getBool('p4_mp_eye_color_natural') ?? true;
    });
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
    int maxLines = 1,
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
            maxLines: maxLines,
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

  // دالة مساعدة لبناء خانة الاختيار
  Widget _buildCheckboxOption({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    String? description,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalPadding * 0.2),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      padding: EdgeInsets.all(_horizontalPadding * 0.6),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: _primaryColor,
            onChanged: onChanged,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: _bodyFontSize * 0.9,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                if (description != null) ...[
                  SizedBox(height: _verticalPadding * 0.2),
                  Text(
                    description,
                    style: _smallStyle,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء قسم رفع الصور
  Widget _buildImageUploadSection({
    required String title,
    required Uint8List? image,
    required String buttonText,
    required Function() onPressed,
    double imageHeight = 180,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          padding: EdgeInsets.all(_horizontalPadding * 0.6),
          child: Column(
            children: [
              image != null
                  ? Container(
                      width: double.infinity,
                      height: imageHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 60,
                          color: _hintColor,
                        ),
                        SizedBox(height: _verticalPadding * 0.5),
                        Text(
                          'لم يتم رفع صورة',
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
                  onPressed: onPressed,
                  child: Text(
                    buttonText,
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

  /* initState for shared pref text and bool */
  @override
  void initState() {
    super.initState();
    _loadImages();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
        widget.defaultHeightParent();

        mp_dental_available = _prefs.getBool('p4_mp_dental_available') ?? false;
        mp_fingerprints_available = _prefs.getBool('p4_mp_fingerprints_available') ?? false;

        mp_dental_available! ? widget.addHeightParent() : null;
        mp_fingerprints_available! ? widget.addHeightParent() : null;

        // scars, marks, tattoos
        _mp_scars.text = _prefs.getString('p4_mp_scars') ?? '';
        _mp_marks.text = _prefs.getString('p4_mp_marks') ?? '';
        _mp_tattoos.text = _prefs.getString('p4_mp_tattoos') ?? '';
        // hair, eye color
        _mp_hair_color.text = _prefs.getString('p4_mp_hair_color') ?? '';
        _mp_eye_color.text = _prefs.getString('p4_mp_eye_color') ?? '';
        // prosthetics, birth defects, last clothing
        _mp_prosthetics.text = _prefs.getString('p4_mp_prosthetics') ?? '';
        _mp_birth_defects.text = _prefs.getString('p4_mp_birth_defects') ?? '';
        _mp_last_clothing.text = _prefs.getString('p4_mp_last_clothing') ?? '';
        // MP medical details
        _mp_height_feet.text = _prefs.getString('p4_mp_height_feet') ?? '';
        _mp_height_inches.text = _prefs.getString('p4_mp_height_inches') ?? '';
        _mp_weight.text = _prefs.getString('p4_mp_weight') ?? '';
        _mp_blood_type.text = _prefs.getString('p4_mp_blood_type') ?? '';
        
        if (prefs.getString('p4_mp_blood_type') != null) {
          mp_blood_typeValue = prefs.getString('p4_mp_blood_type');
        }
        
        _mp_medications.text = _prefs.getString('p4_mp_medications') ?? '';
        // MP socmed details
        _mp_facebook.text = _prefs.getString('p4_mp_socmed_facebook_username') ?? '';
        _mp_twitter.text = _prefs.getString('p4_mp_socmed_twitter_username') ?? '';
        _mp_instagram.text = _prefs.getString('p4_mp_socmed_instagram_username') ?? '';
        _mp_socmed_other_platform.text = _prefs.getString('p4_mp_socmed_other_platform') ?? '';
        _mp_socmed_other_username.text = _prefs.getString('p4_mp_socmed_other_username') ?? '';
      });
    });
    getBoolChoices();
    retrieveUserData();
  }

  @override
  Widget build(BuildContext context) {
    // حفظ context الحالي
    _currentContext = context;

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
                      
                      // Scars, Marks, and Tattoos Section
                      _buildScarsMarksTattoosSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Hair and Eye Color Section
                      _buildHairEyeColorSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Medical Details Section
                      _buildMedicalDetailsSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Social Media Section
                      _buildSocialMediaSection(),
                      
                      SizedBox(height: _verticalPadding),
                      
                      // Photos Section
                      _buildPhotosSection(),
                      
                      SizedBox(height: _verticalPadding * 1.5),
                      
                      // Footer Section
                      _buildFooterSection(),
                      
                      // مسافة إضافية في الأسفل
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
              width: MediaQuery.of(_currentContext).size.width * 0.4,
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
                    'وصف الشخص المفقود',
                    style: _titleStyle.copyWith(fontSize: _titleFontSize * 0.9),
                  ),
                  SizedBox(height: _verticalPadding * 0.2),
                  Text(
                    'الصفحة ٤ من ٦',
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
        color: _accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: _bodyFontSize * 1.1, color: _accentColor),
          SizedBox(width: _horizontalPadding * 0.4),
          Expanded(
            child: Text(
              'جميع الحقول مطلوبة. اكتب "غير معروف" إذا لم تكن المعلومة متوفرة',
              style: _smallStyle.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScarsMarksTattoosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الندوب، العلامات، والوشوم',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildFormField(
          controller: _mp_scars,
          label: 'الندوب',
          hint: 'وصف الندوب (اكتب "غير معروف" إذا لم تكن متوفرة)',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p4_mp_scars', value),
        ),
        
        _buildFormField(
          controller: _mp_marks,
          label: 'العلامات',
          hint: 'وصف العلامات (اكتب "غير معروف" إذا لم تكن متوفرة)',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p4_mp_marks', value),
        ),
        
        _buildFormField(
          controller: _mp_tattoos,
          label: 'الوشوم',
          hint: 'وصف الوشوم (اكتب "غير معروف" إذا لم تكن متوفرة)',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p4_mp_tattoos', value),
        ),
      ],
    );
  }

  Widget _buildHairEyeColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لون الشعر والعينين',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildFormField(
          controller: _mp_hair_color,
          label: 'لون الشعر',
          hint: 'لون الشعر',
          maxLength: 20,
          onChanged: (value) => _writeToPrefs('p4_mp_hair_color', value),
        ),
        
        _buildCheckboxOption(
          label: 'لون الشعر طبيعي (غير مصبوغ/بدون باروكة)',
          value: mp_hair_color_natural ?? true,
          onChanged: (value) {
            setState(() {
              mp_hair_color_natural = value;
            });
            _prefs.setBool('p4_mp_hair_color_natural', value!);
          },
        ),
        
        _buildFormField(
          controller: _mp_eye_color,
          label: 'لون العينين',
          hint: 'لون العينين',
          maxLength: 20,
          onChanged: (value) => _writeToPrefs('p4_mp_eye_color', value),
        ),
        
        _buildCheckboxOption(
          label: 'لون العينين طبيعي (بدون عدسات لاصقة)',
          value: mp_eye_color_natural ?? true,
          onChanged: (value) {
            setState(() {
              mp_eye_color_natural = value;
            });
            _prefs.setBool('p4_mp_eye_color_natural', value!);
          },
        ),
        
        _buildFormField(
          controller: _mp_prosthetics,
          label: 'الأطراف الاصطناعية',
          hint: 'وصف الأطراف الاصطناعية (اكتب "غير معروف" إذا لم تكن متوفرة)',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p4_mp_prosthetics', value),
        ),
        
        _buildFormField(
          controller: _mp_birth_defects,
          label: 'العيوب الخلقية',
          hint: 'وصف العيوب الخلقية (اكتب "غير معروف" إذا لم تكن متوفرة)',
          onChanged: (value) => _writeToPrefs('p4_mp_birth_defects', value),
        ),
        
        _buildFormField(
          controller: _mp_last_clothing,
          label: 'الملابس والإكسسوارات المعروفة الأخيرة',
          hint: 'وصف الملابس والإكسسوارات',
          maxLength: 60,
          maxLines: 2,
          onChanged: (value) => _writeToPrefs('p4_mp_last_clothing', value),
        ),
      ],
    );
  }

  Widget _buildMedicalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التفاصيل الطبية',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        // الطول
        Text(
          'الطول',
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
              child: _buildFormField(
                controller: _mp_height_feet,
                label: '',
                hint: 'القدم',
                keyboardType: TextInputType.phone,
                onChanged: (value) => _writeToPrefs('p4_mp_height_feet', value),
              ),
            ),
            SizedBox(width: _horizontalPadding * 0.3),
            Expanded(
              child: _buildFormField(
                controller: _mp_height_inches,
                label: '',
                hint: 'البوصة',
                keyboardType: TextInputType.phone,
                onChanged: (value) => _writeToPrefs('p4_mp_height_inches', value),
              ),
            ),
          ],
        ),
        
        _buildFormField(
          controller: _mp_weight,
          label: 'الوزن',
          hint: 'الكيلوجرام (كجم)',
          keyboardType: TextInputType.phone,
          onChanged: (value) => _writeToPrefs('p4_mp_weight', value),
        ),
        
        _buildDropdownField(
          label: 'فصيلة الدم',
          value: mp_blood_typeValue,
          items: _bloodTypes,
          isRequired: true,
          hint: 'اختر فصيلة الدم',
          onChanged: (value) {
            setState(() {
              mp_blood_typeValue = value;
              _writeToPrefs('p4_mp_blood_type', value!);
            });
          },
        ),
        
        _buildFormField(
          controller: _mp_medications,
          label: 'الأدوية',
          hint: 'وصف الأدوية (اكتب "غير معروف" إذا لم تكن متوفرة)',
          maxLength: 60,
          onChanged: (value) => _writeToPrefs('p4_mp_medications', value),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حسابات وسائل التواصل الاجتماعي',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildFormField(
          controller: _mp_facebook,
          label: 'فيسبوك',
          hint: 'اسم المستخدم (اكتب "غير معروف" إذا لم يكن متوفراً)',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p4_mp_socmed_facebook_username', value),
        ),
        
        _buildFormField(
          controller: _mp_twitter,
          label: 'تويتر',
          hint: 'اسم المستخدم (اكتب "غير معروف" إذا لم يكن متوفراً)',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p4_mp_socmed_twitter_username', value),
        ),
        
        _buildFormField(
          controller: _mp_instagram,
          label: 'إنستغرام',
          hint: 'اسم المستخدم (اكتب "غير معروف" إذا لم يكن متوفراً)',
          maxLength: 50,
          onChanged: (value) => _writeToPrefs('p4_mp_socmed_instagram_username', value),
        ),
        
        // منصات أخرى
        Text(
          'منصات أخرى',
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
              child: _buildFormField(
                controller: _mp_socmed_other_platform,
                label: '',
                hint: 'اسم المنصة',
                maxLength: 50,
                onChanged: (value) => _writeToPrefs('p4_mp_socmed_other_platform', value),
              ),
            ),
            SizedBox(width: _horizontalPadding * 0.3),
            Expanded(
              child: _buildFormField(
                controller: _mp_socmed_other_username,
                label: '',
                hint: 'اسم المستخدم',
                maxLength: 50,
                onChanged: (value) => _writeToPrefs('p4_mp_socmed_other_username', value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الصور والسجلات',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        // صورة حديثة
        _buildImageUploadSection(
          title: 'صورة حديثة للشخص المفقود',
          image: mp_recent_photo,
          buttonText: 'رفع صورة حديثة',
          imageHeight: 200,
          onPressed: () => _getImages('mp_recent_photo'),
        ),
        
        SizedBox(height: _verticalPadding),
        
        // السجلات الطبية
        Text(
          'السجلات الطبية',
          style: _headingStyle.copyWith(fontSize: _bodyFontSize),
        ),
        SizedBox(height: _verticalPadding * 0.3),
        Text(
          'هل لدى الشخص سجلات طبية؟ يرجى اختيار جميع الخيارات المناسبة',
          style: _smallStyle,
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: _verticalPadding * 0.5),
        
        _buildCheckboxOption(
          label: 'سجلات الأسنان',
          value: mp_dental_available ?? false,
          onChanged: (value) {
            setState(() {
              mp_dental_available = value!;
              if (value == true) {
                widget.addHeightParent();
              } else {
                widget.subtractHeightParent();
              }
              _prefs.setBool('p4_mp_dental_available', value);
            });
          },
          description: 'هل توجد سجلات للأسنان؟',
        ),
        
        if (mp_dental_available == true) ...[
          SizedBox(height: _verticalPadding * 0.5),
          _buildImageUploadSection(
            title: 'سجل الأسنان',
            image: mp_dental_record_photo,
            buttonText: 'رفع سجل الأسنان',
            imageHeight: 180,
            onPressed: () => _getImages('mp_dental_record_photo'),
          ),
        ],
        
        _buildCheckboxOption(
          label: 'سجلات البصمات',
          value: mp_fingerprints_available ?? false,
          onChanged: (value) {
            setState(() {
              mp_fingerprints_available = value!;
              if (value == true) {
                widget.addHeightParent();
              } else {
                widget.subtractHeightParent();
              }
              _prefs.setBool('p4_mp_fingerprints_available', value);
            });
          },
          description: 'هل توجد سجلات للبصمات؟',
        ),
        
        if (mp_fingerprints_available == true) ...[
          SizedBox(height: _verticalPadding * 0.5),
          _buildImageUploadSection(
            title: 'سجل البصمات',
            image: mp_finger_print_record_photo,
            buttonText: 'رفع سجل البصمات',
            imageHeight: 180,
            onPressed: () => _getImages('mp_finger_print_record_photo'),
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
            width: MediaQuery.of(_currentContext).size.width * 0.08,
            height: MediaQuery.of(_currentContext).size.width * 0.08,
          ),
          SizedBox(width: _horizontalPadding * 0.4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'نهاية نموذج وصف الشخص المفقود',
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