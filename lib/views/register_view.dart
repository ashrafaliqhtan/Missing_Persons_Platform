import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Missing_Persons_Platform/firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Missing_Persons_Platform/views/verify_email_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _qualifiers;
  late final TextEditingController _phoneNumber;
  late final TextEditingController _birthDate;
  late final Future<FirebaseApp> _firebaseInit;
  
  String? ageFromBday;
  String? _selectedSex;
  String? _selectedUserType;
  DateTime? dateTimeBday;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  bool _obscured = true;
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final FirebaseDatabase database = FirebaseDatabase.instance;

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

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _firstName = TextEditingController();
    _middleName = TextEditingController();
    _lastName = TextEditingController();
    _qualifiers = TextEditingController();
    _phoneNumber = TextEditingController();
    _birthDate = TextEditingController();
    
    _firebaseInit = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _qualifiers.dispose();
    _phoneNumber.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  List<String> _reformatDate(String dateTime, DateTime dateTimeBday) {
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

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = AutovalidateMode.always);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة بشكل صحيح')),
      );
      return;
    }

    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار نوع المستخدم')),
      );
      return;
    }

    if (dateTimeBday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ الميلاد')),
      );
      return;
    }

    if (_selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الجنس')),
      );
      return;
    }

    setState(() {
      _autoValidate = AutovalidateMode.disabled;
      _isLoading = true;
    });

    try {
      final email = _email.text.trim();
      final password = _password.text;
      final firstName = _firstName.text.trim();
      final lastName = _lastName.text.trim();
      final qualifiers = _qualifiers.text.isEmpty ? 'N/A' : _qualifiers.text.trim();
      final middleName = _middleName.text.isEmpty ? 'N/A' : _middleName.text.trim();
      final phoneNumber = _phoneNumber.text.trim();

      if (kDebugMode) {
        print('[REGISTER] بدء عملية التسجيل...');
        print('البريد الإلكتروني: $email');
        print('نوع المستخدم: $_selectedUserType');
      }

      // إنشاء مستخدم في Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (kDebugMode) {
        print('[AUTH] تم إنشاء المستخدم: ${userCredential.user!.uid}');
      }

      final User user = userCredential.user!;
      
      // تحديث اسم العرض
      await user.updateDisplayName(firstName);
      
      // إرسال التحقق من البريد الإلكتروني
      await user.sendEmailVerification();

      if (kDebugMode) {
        print('[AUTH] تم إرسال التحقق من البريد الإلكتروني');
      }

      // حفظ بيانات المستخدم في قاعدة البيانات
      await _saveUserData(
        user.uid,
        email,
        firstName,
        lastName,
        qualifiers,
        middleName,
        phoneNumber,
      );

      if (kDebugMode) {
        print('[DATABASE] تم حفظ بيانات المستخدم بنجاح');
        print('[REGISTERED] اكتمل التسجيل لـ: $email');
      }

      // الانتقال إلى شاشة التحقق من البريد الإلكتروني
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerifyEmailView()),
        );
      }

    } on FirebaseAuthException catch (e) {
      _handleRegistrationError(e);
    } catch (e) {
      if (kDebugMode) {
        print('[UNKNOWN ERROR]: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserData(
    String uid,
    String email,
    String firstName,
    String lastName,
    String qualifiers,
    String middleName,
    String phoneNumber,
  ) async {
    try {
      final userData = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'qualifiers': qualifiers,
        'middleName': middleName,
        'phoneNumber': phoneNumber,
        'birthDate': dateTimeBday.toString(),
        'sex': _selectedSex,
        'userType': _selectedUserType,
        'reportCount': '0',
        'createdAt': ServerValue.timestamp,
      };

      DatabaseReference ref;
      if (_selectedUserType == 'مستخدم رئيسي') {
        ref = database.ref("Main Users").child(uid);
      } else {
        ref = database.ref("Companion Users").child(uid);
      }

      await ref.set(userData);
      
      if (kDebugMode) {
        print('[DATABASE] تم حفظ البيانات للمسار: ${ref.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DATABASE ERROR]: $e');
      }
      rethrow;
    }
  }

  void _handleRegistrationError(FirebaseAuthException e) {
    String errorMessage = 'حدث خطأ أثناء التسجيل';

    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = 'البريد الإلكتروني مستخدم بالفعل!';
        break;
      case 'weak-password':
        errorMessage = 'كلمة المرور ضعيفة جداً! يجب أن تكون 6 أحرف على الأقل.';
        break;
      case 'invalid-email':
        errorMessage = 'صيغة البريد الإلكتروني غير صالحة!';
        break;
      case 'operation-not-allowed':
        errorMessage = 'حسابات البريد الإلكتروني/كلمة المرور غير مفعلة. يرجى التواصل مع الدعم.';
        break;
      case 'network-request-failed':
        errorMessage = 'خطأ في الشبكة. يرجى التحقق من اتصال الإنترنت.';
        break;
    }

    if (kDebugMode) {
      print('[FIREBASE AUTH ERROR]: ${e.code} - ${e.message}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: FutureBuilder(
        future: _firebaseInit,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: _errorColor),
                  SizedBox(height: _verticalPadding),
                  Text(
                    'فشل تهيئة Firebase',
                    style: GoogleFonts.inter(fontSize: 16, color: _hintColor),
                  ),
                  SizedBox(height: _verticalPadding * 0.5),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: _hintColor),
                  ),
                ],
              ),
            );
          }

          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return _buildRegistrationForm();
            case ConnectionState.waiting:
            default:
              return _buildLoadingWidget();
          }
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
          SizedBox(height: _verticalPadding),
          Text(
            'جاري الإعداد...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: _verticalPadding),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate,
          child: Column(
            children: [
              // الهيدر مع الصورة
              _buildHeader(),
              SizedBox(height: _verticalPadding * 1.5),

              // العنوان والوصف
              _buildTitleSection(),
              SizedBox(height: _verticalPadding * 2),

              // نوع المستخدم
              _buildUserTypeField(),
              SizedBox(height: _verticalPadding * 1.5),

              // المعلومات الشخصية
              _buildPersonalInfoSection(),
              SizedBox(height: _verticalPadding * 1.5),

              // معلومات الحساب
              _buildAccountInfoSection(),
              SizedBox(height: _verticalPadding * 2),

              // زر التسجيل
              _buildRegisterButton(),
              SizedBox(height: _verticalPadding * 1.5),

              // الشروط والسياسات
              _buildTermsText(),
              SizedBox(height: _verticalPadding),

              // رابط تسجيل الدخول
              _buildLoginLink(),
              SizedBox(height: _verticalPadding * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      child: Image.asset(
        'assets/images/register.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'إنشاء حساب جديد',
          style: GoogleFonts.inter(
            fontSize: _titleFontSize,
            fontWeight: FontWeight.w800,
            color: _primaryColor,
          ),
        ),
        SizedBox(height: _verticalPadding * 0.3),
        Text(
          'انضم إلينا وابدأ رحلتك',
          style: GoogleFonts.inter(
            fontSize: _bodyFontSize,
            fontWeight: FontWeight.w400,
            color: _hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'أنا: *',
          style: GoogleFonts.inter(
            fontSize: _bodyFontSize,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * 0.6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUserType,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: _hintColor),
                hint: Text(
                  'اختر نوع المستخدم',
                  style: GoogleFonts.inter(color: _hintColor),
                ),
                items: ['مستخدم رئيسي', 'مستخدم مرافق'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: _bodyFontSize,
                        color: _textColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedUserType = newValue);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        // صف الاسم الأول والأخير
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstName,
                label: 'الاسم الأول *',
                icon: Icons.person_outline_rounded,
                validator: (value) => value?.isEmpty ?? true ? 'يرجى إدخال الاسم الأول' : null,
              ),
            ),
            SizedBox(width: _horizontalPadding * 0.3),
            Expanded(
              child: _buildTextField(
                controller: _lastName,
                label: 'اسم العائلة *',
                icon: Icons.person_outline_rounded,
                validator: (value) => value?.isEmpty ?? true ? 'يرجى إدخال اسم العائلة' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: _verticalPadding),

        // الاسم الأوسط
        _buildTextField(
          controller: _middleName,
          label: 'الاسم الأوسط (اختياري)',
          icon: Icons.person_outline_rounded,
        ),
        SizedBox(height: _verticalPadding),

        // اللقب
        _buildTextField(
          controller: _qualifiers,
          label: 'اللقب (اختياري)',
          icon: Icons.workspace_premium_outlined,
        ),
        SizedBox(height: _verticalPadding),

        // رقم الهاتف والجنس
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _phoneNumber,
                label: 'رقم الهاتف *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال رقم الهاتف';
                  if (value.length < 10 || value.length > 11) return 'رقم الهاتف غير صالح';
                  if (!_isNumeric(value)) return 'يرجى إدخال رقم هاتف صالح';
                  return null;
                },
              ),
            ),
            SizedBox(width: _horizontalPadding * 0.3),
            Expanded(
              flex: 1,
              child: _buildDropdownField(
                value: _selectedSex,
                label: 'الجنس *',
                icon: Icons.wc_outlined,
                items: ['ذكر', 'أنثى'],
                onChanged: (value) => setState(() => _selectedSex = value),
                validator: (value) => value == null ? 'يرجى اختيار الجنس' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: _verticalPadding),

        // تاريخ الميلاد
        _buildBirthDateField(),
      ],
    );
  }

  Widget _buildAccountInfoSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _email,
          label: 'البريد الإلكتروني *',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
            if (!value.contains('@') || !value.contains('.')) return 'يرجى إدخال بريد إلكتروني صالح';
            return null;
          },
        ),
        SizedBox(height: _verticalPadding),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: !obscureText,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      textCapitalization: keyboardType == TextInputType.name ? TextCapitalization.words : TextCapitalization.none,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _hintColor),
        labelText: label,
        labelStyle: GoogleFonts.inter(color: _hintColor),
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
          vertical: _verticalPadding * 0.8,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _obscured,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline_rounded, color: _hintColor),
        labelText: 'كلمة المرور *',
        labelStyle: GoogleFonts.inter(color: _hintColor),
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
          vertical: _verticalPadding * 0.8,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: _hintColor,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
        if (value.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.inter(fontSize: _bodyFontSize),
            textAlign: TextAlign.right,
          ),
        );
      }).toList(),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _hintColor),
        labelText: label,
        labelStyle: GoogleFonts.inter(color: _hintColor),
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
      validator: validator,
      dropdownColor: _cardColor,
      icon: Icon(Icons.arrow_drop_down, color: _hintColor),
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: _birthDate,
          readOnly: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today_outlined, color: _hintColor),
            labelText: 'تاريخ الميلاد *',
            hintText: 'انقر لاختيار تاريخ الميلاد',
            labelStyle: GoogleFonts.inter(color: _hintColor),
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
              vertical: _verticalPadding * 0.8,
            ),
          ),
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            final results = await showCalendarDatePicker2Dialog(
              context: context,
              config: CalendarDatePicker2WithActionButtonsConfig(
                calendarType: CalendarDatePicker2Type.single,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              ),
              dialogSize: Size(MediaQuery.of(context).size.width * 0.9, 400),
              value: [DateTime.now().subtract(const Duration(days: 365 * 18))],
              borderRadius: BorderRadius.circular(15),
            );

            if (results != null && results.isNotEmpty) {
              dateTimeBday = results[0];
              final stringBday = dateTimeBday.toString();
              final returnVals = _reformatDate(stringBday, dateTimeBday!);
              setState(() {
                _birthDate.text = returnVals[0];
                ageFromBday = returnVals[1];
              });
            }
          },
          validator: (value) => value?.isEmpty ?? true ? 'يرجى اختيار تاريخ الميلاد' : null,
        ),
        if (ageFromBday != null) ...[
          SizedBox(height: _verticalPadding * 0.5),
          Text(
            'عمرك الحالي هو $ageFromBday سنة',
            style: GoogleFonts.inter(
              fontSize: _smallFontSize,
              color: _successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _registerUser,
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'إنشاء حساب',
                style: GoogleFonts.inter(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: _smallFontSize,
          color: _hintColor,
        ),
        children: const <TextSpan>[
          TextSpan(text: 'بالتسجيل، فإنك توافق على '),
          TextSpan(
            text: 'الشروط والأحكام',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: ' و '),
          TextSpan(
            text: 'سياسة الخصوصية',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لديك حساب بالفعل؟ ',
          style: GoogleFonts.inter(
            fontSize: _bodyFontSize,
            color: _hintColor,
          ),
        ),
        GestureDetector(
          onTap: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'تسجيل الدخول',
            style: GoogleFonts.inter(
              fontSize: _bodyFontSize,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  bool _isNumeric(String s) => double.tryParse(s) != null;
}