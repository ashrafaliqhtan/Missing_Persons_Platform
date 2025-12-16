import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Missing_Persons_Platform/firebase_options.dart';
import 'package:Missing_Persons_Platform/views/main/navigation_view_main.dart';
import 'package:Missing_Persons_Platform/views/register_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Missing_Persons_Platform/views/verify_email_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final Future<FirebaseApp> _firebaseInit;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  bool _obscured = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _firebaseInit = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = AutovalidateMode.always);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء النموذج بشكل صحيح')),
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
      
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!userCredential.user!.emailVerified) {
        if (kDebugMode) print('[UNVERIFIED] البريد الإلكتروني غير مفعل!');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const VerifyEmailView()),
          );
        }
        return;
      }

      // التحقق من نوع المستخدم والتوجيه accordingly
      await _checkUserTypeAndNavigate(email);
      
    } on FirebaseAuthException catch (e) {
      _handleLoginError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkUserTypeAndNavigate(String email) async {
    final mainUserRef = FirebaseDatabase.instance.ref('Main Users');
    final companionRef = FirebaseDatabase.instance.ref('Companion Users');
    
    bool isUserMain = false;
    bool isUserCompanion = false;

    // التحقق في المستخدمين الرئيسيين
    final mainUserSnapshot = await mainUserRef.once();
    if (mainUserSnapshot.snapshot.value != null) {
      final usersData = Map<String, dynamic>.from(
        mainUserSnapshot.snapshot.value as Map<dynamic, dynamic>
      );
      isUserMain = usersData.values.any(
        (value) => value['email']?.toString() == email
      );
    }

    // التحقق في المستخدمين المرافقين
    final companionSnapshot = await companionRef.once();
    if (companionSnapshot.snapshot.value != null) {
      final usersData = Map<String, dynamic>.from(
        companionSnapshot.snapshot.value as Map<dynamic, dynamic>
      );
      isUserCompanion = usersData.values.any(
        (value) => value['email']?.toString() == email
      );
    }

    if (isUserMain) {
      if (kDebugMode) print('[FOUND] المستخدم رئيسي');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NavigationField()),
        (route) => false,
      );
    } else if (isUserCompanion) {
      if (kDebugMode) print('[FOUND] المستخدم مرافق');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NavigationField()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المستخدم غير موجود في قاعدة البيانات')),
      );
    }
  }

  void _handleLoginError(FirebaseAuthException e) {
    String errorMessage = 'حدث خطأ';
    
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'المستخدم غير موجود!';
        break;
      case 'wrong-password':
        errorMessage = 'كلمة المرور خاطئة!';
        break;
      case 'invalid-email':
        errorMessage = 'صيغة البريد الإلكتروني غير صالحة!';
        break;
      case 'user-disabled':
        errorMessage = 'تم تعطيل حساب المستخدم';
        break;
      case 'too-many-requests':
        errorMessage = 'طلبات كثيرة، يرجى المحاولة مرة أخرى لاحقاً';
        break;
      case 'network-request-failed':
        errorMessage = 'فشل الاتصال، تحقق من اتصال الإنترنت';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    if (kDebugMode) print('خطأ تسجيل الدخول: $e');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder(
        future: _firebaseInit,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return _buildErrorWidget('لا يوجد اتصال');
            case ConnectionState.waiting:
              return _buildLoadingWidget();
            case ConnectionState.active:
              return _buildErrorWidget('الاتصال نشط!');
            case ConnectionState.done:
              return _buildLoginForm();
            default:
              return _buildLoadingWidget();
          }
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل Missing_Persons_Platform...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate,
          child: Column(
            children: [
              // صورة الهيدر
              Padding(
                padding: const EdgeInsets.only(bottom: 40, top: 60),
                child: Image.asset(
                  'assets/images/login.png',
                  height: MediaQuery.of(context).size.height * .3,
                  fit: BoxFit.contain,
                ),
              ),

              // العنوان
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'مرحباً بعودتك!',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'سجل الدخول لمتابعة رحلتك',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // حقل البريد الإلكتروني
              _buildEmailField(),
              const SizedBox(height: 20),

              // حقل كلمة المرور
              _buildPasswordField(),
              const SizedBox(height: 24),

              // زر تسجيل الدخول
              _buildLoginButton(),
              const SizedBox(height: 20),

              // رابط التسجيل
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _email,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.emailAddress,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.mail_outline_rounded, color: Colors.grey[600]),
        labelText: 'البريد الإلكتروني',
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال البريد الإلكتروني';
        } else if (!value.contains('@') || !value.contains('.')) {
          return 'يرجى إدخال بريد إلكتروني صالح';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _obscured,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[600]),
        labelText: 'كلمة المرور',
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: Icon(
            _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey[600],
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال كلمة المرور';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _loginUser,
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
                'تسجيل الدخول',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "ليس لديك حساب؟ ",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegisterView()),
                  );
                },
          child: Text(
            'سجل الآن',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ],
    );
  }
}