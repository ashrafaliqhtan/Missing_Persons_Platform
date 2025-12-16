import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:Missing_Persons_Platform/views/login_view.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';

class ProfileMain extends StatefulWidget {
  const ProfileMain({super.key});

  @override
  State<ProfileMain> createState() => _ProfileMainState();
}

class _ProfileMainState extends State<ProfileMain> {
  // بيانات المستخدم
  String _usrFullName = '';
  String _usrFirstName = 'جاري التحميل';
  String _usrLastName = '';
  String _usrMiddleName = '';
  String _usrQualifiers = '';
  String _usrEmail = ' ';
  String _usrNumber = ' ';
  String _usrBirthDate = ' ';
  String _usrAge = ' ';
  String _birthDateFormatted = ' ';
  String _usrSex = ' ';
  String _usrProfileImage = '';
  
  // حالات التحميل والأخطاء
  bool _isLoading = true;
  bool _hasError = false;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  
  // مراقبة التغييرات
  DatabaseReference mainUsersRef = FirebaseDatabase.instance.ref('Main Users');
  final user = FirebaseAuth.instance.currentUser;
  StreamSubscription<DatabaseEvent>? _profileSubscription;
  
  // أدوات الصور
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  
  // وحدات تحكم النماذج
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _qualifiersController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // متغيرات للجنس وتاريخ الميلاد
  String _selectedSex = 'ذكر';
  DateTime? _selectedBirthDate;
  
  // ألوان مخصصة للمظهر
  final Color _primaryColor = Color(0xFF6A1B9A);
  final Color _accentColor = Color(0xFFAB47BC);
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _qualifiersController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // دالة لإعادة تنسيق التاريخ باللغة العربية
  List<String> reformatDate(String dateTime, DateTime dateTimeBday) {
    try {
      final dateParts = dateTime.split('-');
      var month = dateParts[1];
      if (int.parse(month) % 10 != 0) {
        month = month.replaceAll('0', '');
      }

      const monthNames = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      
      month = monthNames[int.parse(month) - 1];

      var day = dateParts[2].contains(' ') 
          ? dateParts[2].substring(0, dateParts[2].indexOf(' '))
          : dateParts[2];
          
      if (int.parse(day) % 10 != 0) {
        day = day.replaceAll('0', '');
      }

      final year = dateParts[0];
      final age = (DateTime.now().difference(dateTimeBday).inDays / 365).floor().toString();
      final formattedDate = '$day $month $year';
      
      return [formattedDate, age];
    } catch (e) {
      return [dateTime, 'غير معروف'];
    }
  }

  void _loadUserProfile() {
    if (user == null) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _usrFirstName = 'لا يوجد مستخدم';
      });
      return;
    }

    // إلغاء أي اشتراك سابق لمنع التكرار
    _profileSubscription?.cancel();

    // جلب بيانات البروفايل من قاعدة البيانات
    _profileSubscription = mainUsersRef.child(user!.uid).onValue.listen((event) {
      if (event.snapshot.value == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _usrFirstName = 'لا توجد بيانات';
        });
        return;
      }

      try {
        var usrProfileDict = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);
        
        String firstNameFromDB = usrProfileDict['firstName'] ?? 'غير محدد';
        String lastNameFromDB = usrProfileDict['lastName'] ?? 'غير محدد';
        String middleNameFromDB = usrProfileDict['middleName'] == 'N/A' || usrProfileDict['middleName'] == null
            ? ''
            : usrProfileDict['middleName'];
        String qualifiersFromDB = usrProfileDict['qualifiers'] == 'N/A' || usrProfileDict['qualifiers'] == null
            ? ''
            : usrProfileDict['qualifiers'];
        String numberFromDB = usrProfileDict['phoneNumber'] ?? 'غير محدد';
        String emailFromDB = usrProfileDict['email'] ?? 'غير محدد';
        String sexFromDB = usrProfileDict['sex'] ?? 'غير محدد';
        String profileImageFromDB = usrProfileDict['profileImage'] ?? '';

        // تحويل الجنس إلى العربية
        String sexInArabic = _translateSexToArabic(sexFromDB);

        String birthDate = usrProfileDict['birthDate'] ?? 'غير محدد';
        String birthDateFormatted = 'غير محدد';
        String age = 'غير معروف';

        if (birthDate != 'غير محدد') {
          try {
            List birthDateList = reformatDate(birthDate, DateTime.parse(birthDate));
            birthDateFormatted = birthDateList[0];
            age = birthDateList[1];
          } catch (e) {
            birthDateFormatted = birthDate;
            age = 'غير معروف';
          }
        }

        if (kDebugMode) {
          print('[تم الاسترجاع] $usrProfileDict');
          print('تاريخ الميلاد: $birthDateFormatted, العمر: $age');
        }

        setState(() {
          _usrFirstName = firstNameFromDB;
          _usrLastName = lastNameFromDB;
          _usrMiddleName = middleNameFromDB;
          _usrQualifiers = qualifiersFromDB;
          _usrNumber = numberFromDB;
          _usrEmail = emailFromDB;
          _usrSex = sexInArabic;
          _usrBirthDate = birthDate;
          _usrAge = age;
          _birthDateFormatted = birthDateFormatted;
          _usrProfileImage = profileImageFromDB;
          _isLoading = false;
          _hasError = false;
          
          // تعبئة وحدات التحكم للتحرير
          _firstNameController.text = firstNameFromDB;
          _lastNameController.text = lastNameFromDB;
          _middleNameController.text = middleNameFromDB;
          _qualifiersController.text = qualifiersFromDB;
          _phoneController.text = numberFromDB;
          _emailController.text = emailFromDB;
          _birthDateController.text = birthDateFormatted;
          _selectedSex = sexInArabic;
        });
      } catch (e) {
        if (kDebugMode) {
          print('خطأ في تحميل البروفايل: $e');
        }
        setState(() {
          _hasError = true;
          _isLoading = false;
          _usrFirstName = 'خطأ';
        });
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('خطأ في الاستماع للبروفايل: $error');
      }
      setState(() {
        _hasError = true;
        _isLoading = false;
        _usrFirstName = 'خطأ';
      });
    });
  }

  // دالة لترجمة الجنس إلى العربية
  String _translateSexToArabic(String sex) {
    switch (sex.toLowerCase()) {
      case 'male':
        return 'ذكر';
      case 'female':
        return 'أنثى';
      case 'ذكر':
        return 'ذكر';
      case 'أنثى':
        return 'أنثى';
      default:
        return sex;
    }
  }

  // دالة لترجمة الجنس إلى الإنجليزية
  String _translateSexToEnglish(String sex) {
    switch (sex.toLowerCase()) {
      case 'ذكر':
        return 'male';
      case 'أنثى':
        return 'female';
      case 'male':
        return 'male';
      case 'female':
        return 'female';
      default:
        return sex;
    }
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _loadUserProfile();
  }

  // دالة لاختيار صورة من المعرض
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في اختيار الصورة: $e');
      }
      _showErrorDialog('خطأ في اختيار الصورة', 'تعذر اختيار الصورة. يرجى المحاولة مرة أخرى.');
    }
  }

  // دالة لالتقاط صورة بالكاميرا
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في التقاط الصورة: $e');
      }
      _showErrorDialog('خطأ في التقاط الصورة', 'تعذر التقاط الصورة. يرجى المحاولة مرة أخرى.');
    }
  }

  // دالة لرفع الصورة إلى Firebase Storage
  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null || user == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user!.uid}.jpg');

      final uploadTask = storageRef.putFile(_selectedImage!);
      await uploadTask.whenComplete(() {});
      
      final downloadURL = await storageRef.getDownloadURL();

      // تحديث رابط الصورة في قاعدة البيانات
      await mainUsersRef.child(user!.uid).update({
        'profileImage': downloadURL,
      });

      setState(() {
        _usrProfileImage = downloadURL;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الصورة الشخصية بنجاح', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _successColor,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في رفع الصورة: $e');
      }
      setState(() {
        _isUploadingImage = false;
      });
      _showErrorDialog('خطأ في رفع الصورة', 'تعذر رفع الصورة لانك تستخدم المتصفح لرفع الصورة قم باستخدام التطبيق . يرجى المحاولة مرة أخرى.');
    }
  }

  // دالة لحفظ التعديلات
  Future<void> _saveProfileChanges() async {
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // تحديث البيانات في Firebase
      await mainUsersRef.child(user!.uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'middleName': _middleNameController.text.trim().isEmpty ? 'N/A' : _middleNameController.text.trim(),
        'qualifiers': _qualifiersController.text.trim().isEmpty ? 'N/A' : _qualifiersController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'sex': _translateSexToEnglish(_selectedSex),
      });

      // إعادة تحميل البيانات
      _loadUserProfile();
      
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ التغييرات بنجاح', style: _bodyStyle.copyWith(color: Colors.white)),
          backgroundColor: _successColor,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في حفظ التغييرات: $e');
      }
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('خطأ في الحفظ', 'تعذر حفظ التغييرات. يرجى المحاولة مرة أخرى.');
    }
  }

  // دالة لإلغاء التعديلات
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // إعادة تعيين وحدات التحكم إلى القيم الأصلية
      _firstNameController.text = _usrFirstName;
      _lastNameController.text = _usrLastName;
      _middleNameController.text = _usrMiddleName;
      _qualifiersController.text = _usrQualifiers;
      _phoneController.text = _usrNumber;
      _selectedSex = _usrSex;
    });
  }

  // دالة لعرض منتقي التاريخ
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 5)),
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
    
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // دالة لعرض حوار الأخطاء
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: _headingStyle.copyWith(color: _errorColor)),
          content: Text(message, style: _bodyStyle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('حسناً', style: _bodyStyle.copyWith(color: _primaryColor)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _usrFullName =
        '$_usrFirstName $_usrMiddleName $_usrLastName $_usrQualifiers'.trim();
    
    if (_isLoading && !_isEditing) {
      return _buildLoadingScreen();
    }
    
    if (_hasError) {
      return _buildErrorScreen();
    }
    
    return _buildProfileScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitCubeGrid(
              color: _primaryColor,
              size: 40.0,
            ),
            SizedBox(height: _verticalPadding),
            Text(
              'جاري تحميل البروفايل...',
              style: _bodyStyle.copyWith(color: _hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(_horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: _errorColor,
              ),
              SizedBox(height: _verticalPadding),
              Text(
                'تعذر تحميل البروفايل',
                style: _headingStyle.copyWith(color: _errorColor),
              ),
              SizedBox(height: _verticalPadding * 0.5),
              Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                textAlign: TextAlign.center,
                style: _bodyStyle.copyWith(color: _hintColor),
              ),
              SizedBox(height: _verticalPadding * 2),
              _buildButton(
                text: 'حاول مرة أخرى',
                onPressed: _retryLoading,
                isPrimary: true,
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // الهيدر
              _buildHeader(),
              
              // قسم البروفايل الرئيسي
              _buildProfileHeader(),
              
              // قسم المعلومات
              _buildProfileInfo(),
              
              // زر تسجيل الخروج
              _buildLogoutButton(),
              
              SizedBox(height: _verticalPadding * 2),
            ],
          ),
        ),
      ),
    );
  }

  // بناء الهيدر
  Widget _buildHeader() {
    return Container(
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
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: _primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Spacer(),
          Text(
            'البروفايل الشخصي',
            style: _headingStyle.copyWith(fontSize: _bodyFontSize * 1.1),
          ),
          Spacer(),
          if (!_isEditing)
            Container(
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.edit, color: _primaryColor),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                tooltip: 'تعديل البروفايل',
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: _warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.close, color: _warningColor),
                onPressed: _cancelEditing,
                tooltip: 'إلغاء التعديل',
              ),
            ),
        ],
      ),
    );
  }

  // بناء رأس البروفايل مع الصورة
  Widget _buildProfileHeader() {
    return Padding(
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: _verticalPadding),
          
          // صورة البروفايل مع إمكانية التعديل
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primaryColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.15,
                  backgroundImage: _usrProfileImage.isNotEmpty
                      ? NetworkImage(_usrProfileImage) as ImageProvider
                      : (_selectedImage != null
                          ? FileImage(_selectedImage!)
                          : AssetImage('assets/images/default_profile.png') as ImageProvider),
                  child: _usrProfileImage.isEmpty && _selectedImage == null
                      ? Icon(
                          Icons.person,
                          size: MediaQuery.of(context).size.width * 0.15,
                          color: _hintColor,
                        )
                      : null,
                ),
              ),
              
              // زر تغيير الصورة
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isUploadingImage
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: _isUploadingImage ? null : _showImagePickerDialog,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: _verticalPadding * 1.5),
          
          // اسم المستخدم
          if (!_isEditing)
            Column(
              children: [
                Text(
                  textAlign: TextAlign.center,
                  _usrFullName,
                  style: _titleStyle.copyWith(
                    fontSize: _titleFontSize * 0.8,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: _verticalPadding * 0.3),
                SelectableText(
                  _usrEmail,
                  style: _bodyStyle.copyWith(color: _hintColor),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildEditableForm(),
              ],
            ),
        ],
      ),
    );
  }

  // بناء النموذج القابل للتحرير
  Widget _buildEditableForm() {
    return Column(
      children: [
        // الاسم الأول
        _buildFormField(
          controller: _firstNameController,
          label: 'الاسم الأول',
          hint: 'أدخل الاسم الأول',
          icon: Icons.person_outline,
        ),
        
        SizedBox(height: _verticalPadding * 0.5),
        
        // الاسم الأوسط
        _buildFormField(
          controller: _middleNameController,
          label: 'الاسم الأوسط (اختياري)',
          hint: 'أدخل الاسم الأوسط',
          icon: Icons.person_outline,
        ),
        
        SizedBox(height: _verticalPadding * 0.5),
        
        // الاسم الأخير
        _buildFormField(
          controller: _lastNameController,
          label: 'الاسم الأخير',
          hint: 'أدخل الاسم الأخير',
          icon: Icons.person_outline,
        ),
        
        SizedBox(height: _verticalPadding * 0.5),
        
        // اللقب (اختياري)
        _buildFormField(
          controller: _qualifiersController,
          label: 'اللقب (اختياري)',
          hint: 'أدخل اللقب أو الصفة',
          icon: Icons.work_outline,
        ),
        
        SizedBox(height: _verticalPadding * 0.5),
        
        // رقم الهاتف
        _buildFormField(
          controller: _phoneController,
          label: 'رقم الهاتف',
          hint: 'أدخل رقم الهاتف',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        
        SizedBox(height: _verticalPadding * 0.5),
        
        // اختيار الجنس
        _buildGenderSelector(),
        
        SizedBox(height: _verticalPadding),
        
        // أزرار الحفظ والإلغاء
        Row(
          children: [
            Expanded(
              child: _buildButton(
                text: 'إلغاء',
                onPressed: _cancelEditing,
                isPrimary: false,
                backgroundColor: _hintColor,
              ),
            ),
            SizedBox(width: _horizontalPadding * 0.5),
            Expanded(
              child: _buildButton(
                text: 'حفظ التغييرات',
                onPressed: _saveProfileChanges,
                isPrimary: true,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء حقل النموذج
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: isReadOnly,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: _smallStyle.copyWith(color: _hintColor),
          hintStyle: _smallStyle,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: _primaryColor),
          contentPadding: EdgeInsets.symmetric(
            horizontal: _horizontalPadding * 0.6,
            vertical: _verticalPadding * 0.8,
          ),
        ),
        style: _bodyStyle,
      ),
    );
  }

  // بناء منتقي الجنس
  Widget _buildGenderSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSex,
        onChanged: _isEditing ? (String? newValue) {
          setState(() {
            _selectedSex = newValue!;
          });
        } : null,
        items: ['ذكر', 'أنثى'].map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender, style: _bodyStyle),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: 'الجنس',
          labelStyle: _smallStyle.copyWith(color: _hintColor),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.wc_outlined, color: _primaryColor),
        ),
        style: _bodyStyle,
        dropdownColor: _cardColor,
        icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
      ),
    );
  }

  // بناء قسم المعلومات
  Widget _buildProfileInfo() {
    return Padding(
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        children: [
          // بطاقة رقم الهاتف
          _buildInfoCard(
            icon: Icons.phone_outlined,
            title: 'رقم الهاتف',
            value: _usrNumber,
            iconColor: _successColor,
          ),
          SizedBox(height: _verticalPadding),

          // بطاقة تاريخ الميلاد
          _buildInfoCard(
            icon: Icons.event_outlined,
            title: 'تاريخ الميلاد',
            value: _birthDateFormatted,
            iconColor: _infoColor,
          ),
          SizedBox(height: _verticalPadding),

          // بطاقة العمر
          _buildInfoCard(
            icon: Icons.timeline_outlined,
            title: 'العمر',
            value: '$_usrAge سنة',
            iconColor: _accentColor,
          ),
          SizedBox(height: _verticalPadding),

          // بطاقة الجنس
          _buildInfoCard(
            icon: Icons.wc_outlined,
            title: 'الجنس',
            value: _usrSex,
            iconColor: _warningColor,
          ),
          SizedBox(height: _verticalPadding),

          // بطاقة البريد الإلكتروني
          _buildInfoCard(
            icon: Icons.email_outlined,
            title: 'البريد الإلكتروني',
            value: _usrEmail,
            iconColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  // بناء بطاقة المعلومات
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(_horizontalPadding * 0.8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_horizontalPadding * 0.4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: _bodyFontSize * 1.2,
            ),
          ),
          SizedBox(width: _horizontalPadding * 0.6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _smallStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _hintColor,
                  ),
                ),
                SizedBox(height: _verticalPadding * 0.2),
                Text(
                  value.isNotEmpty && value != 'غير محدد' ? value : 'غير محدد',
                  style: _bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء زر تسجيل الخروج
  Widget _buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.all(_horizontalPadding),
      child: _buildButton(
        text: 'تسجيل الخروج',
        onPressed: () {
          _showSignOutDialog(context);
        },
        isPrimary: false,
        backgroundColor: _errorColor,
        textColor: Colors.white,
        icon: Icons.logout,
        width: double.infinity,
      ),
    );
  }

  // دالة مساعدة لبناء زر
  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPrimary = true,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    double? width,
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
            side: isPrimary ? BorderSide.none : BorderSide(color: backgroundColor ?? _primaryColor),
          ),
          elevation: 2,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? (isPrimary ? Colors.white : _primaryColor),
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

  // عرض حوار اختيار الصورة
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('اختيار صورة', style: _headingStyle),
          content: Text('كيف تريد اختيار الصورة؟', style: _bodyStyle),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, color: _primaryColor),
                  SizedBox(width: 8),
                  Text('المعرض', style: _bodyStyle.copyWith(color: _primaryColor)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _takePhoto();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: _primaryColor),
                  SizedBox(width: 8),
                  Text('الكاميرا', style: _bodyStyle.copyWith(color: _primaryColor)),
                ],
              ),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  // عرض حوار تأكيد تسجيل الخروج
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                Icon(
                  Icons.logout,
                  size: 50,
                  color: _errorColor,
                ),
                SizedBox(height: _verticalPadding),
                Text(
                  'تسجيل الخروج',
                  style: _headingStyle.copyWith(color: _errorColor),
                ),
                SizedBox(height: _verticalPadding * 0.5),
                Text(
                  'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                  textAlign: TextAlign.center,
                  style: _bodyStyle,
                ),
                SizedBox(height: _verticalPadding * 1.5),
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        text: 'إلغاء',
                        onPressed: () => Navigator.of(context).pop(),
                        isPrimary: false,
                      ),
                    ),
                    SizedBox(width: _horizontalPadding * 0.5),
                    Expanded(
                      child: _buildButton(
                        text: 'تسجيل الخروج',
                        onPressed: () {
                          Navigator.of(context).pop();
                          FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginView()),
                            (route) => false,
                          );
                        },
                        isPrimary: true,
                        backgroundColor: _errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}