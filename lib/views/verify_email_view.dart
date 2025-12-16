import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Missing_Persons_Platform/views/login_view.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({Key? key}) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  bool _isSending = false;
  bool _isEmailSent = false;

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
  final Color _borderColor = Color(0xFFDEE2E6); // تم إضافة هذا المتغير

  // أحجام خطوط متجاوبة
  double get _titleFontSize => MediaQuery.of(context).size.width * 0.065;
  double get _bodyFontSize => MediaQuery.of(context).size.width * 0.04;
  double get _smallFontSize => MediaQuery.of(context).size.width * 0.035;
  
  // مسافات متجاوبة
  double get _verticalPadding => MediaQuery.of(context).size.height * 0.015;
  double get _horizontalPadding => MediaQuery.of(context).size.width * 0.045;

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null && !user.emailVerified) {
      setState(() {
        _isSending = true;
      });

      try {
        await user.sendEmailVerification();
        
        setState(() {
          _isEmailSent = true;
          _isSending = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال بريد التحقق بنجاح', style: _bodyStyle.copyWith(color: Colors.white)),
              backgroundColor: _successColor,
              duration: Duration(seconds: 4),
            ),
          );
        }

      } on FirebaseAuthException catch (e) {
        setState(() {
          _isSending = false;
        });

        String errorMessage = 'حدث خطأ في إرسال بريد التحقق';
        
        if (e.code == 'too-many-requests') {
          errorMessage = 'طلبات كثيرة جداً، يرجى المحاولة لاحقاً';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: _bodyStyle.copyWith(color: Colors.white)),
              backgroundColor: _errorColor,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSending = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ غير متوقع', style: _bodyStyle.copyWith(color: Colors.white)),
              backgroundColor: _errorColor,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(_horizontalPadding),
            child: Column(
              children: [
                // مساحة في الأعلى
                SizedBox(height: _verticalPadding * 2),
                
                // الصورة التوضيحية
                _buildHeaderImage(),
                
                // العنوان الرئيسي
                _buildTitleSection(),
                
                // رسالة التأكيد
                _buildConfirmationMessage(userEmail),
                
                // تعليمات التحقق
                _buildVerificationInstructions(),
                
                // زر إرسال التحقق
                _buildVerificationButton(),
                
                // زر تسجيل الدخول
                _buildLoginButton(),
                
                // مساحة في الأسفل
                SizedBox(height: _verticalPadding * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding * 2),
      child: Image.asset(
        "assets/images/verify-email_2.png",
        height: MediaQuery.of(context).size.height * 0.25,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding),
      child: Column(
        children: [
          Text(
            'تفعيل البريد الإلكتروني',
            style: _headingStyle.copyWith(
              fontSize: _titleFontSize * 0.9,
              color: _primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _verticalPadding * 0.5),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationMessage(String userEmail) {
    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding * 1.5),
      padding: EdgeInsets.all(_horizontalPadding * 0.8),
      decoration: BoxDecoration(
        color: _infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _infoColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _infoColor, size: _bodyFontSize * 1.2),
          SizedBox(width: _horizontalPadding * 0.6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم إرسال رابط التفعيل إلى:',
                  style: _smallStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _infoColor,
                  ),
                ),
                SizedBox(height: _verticalPadding * 0.3),
                Text(
                  userEmail,
                  style: _bodyStyle.copyWith(
                    fontSize: _bodyFontSize * 0.9,
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

  Widget _buildVerificationInstructions() {
    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding * 2),
      child: Column(
        children: [
          _buildInstructionStep(
            icon: Icons.email_outlined,
            title: 'افتح بريدك الإلكتروني',
            description: 'ابحث عن رسالة التحقق من Missing_Persons_Platform',
          ),
          SizedBox(height: _verticalPadding),
          _buildInstructionStep(
            icon: Icons.link_outlined,
            title: 'انقر على رابط التفعيل',
            description: 'اضغط على الرابط الموجود داخل الرسالة',
          ),
          SizedBox(height: _verticalPadding),
          _buildInstructionStep(
            icon: Icons.verified_outlined,
            title: 'اكمل عملية التسجيل',
            description: 'عد إلى التطبيق واكمل إنشاء حسابك',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(_horizontalPadding * 0.6),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_horizontalPadding * 0.4),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryColor, size: _bodyFontSize * 1.1),
          ),
          SizedBox(width: _horizontalPadding * 0.6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _bodyStyle.copyWith(
                    fontSize: _bodyFontSize * 0.9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: _verticalPadding * 0.2),
                Text(
                  description,
                  style: _smallStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationButton() {
    return Container(
      margin: EdgeInsets.only(bottom: _verticalPadding * 1.5),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEmailSent ? _successColor : _primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSending ? null : _sendVerificationEmail,
              child: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEmailSent ? Icons.check_circle_outline : Icons.send_outlined,
                          size: _bodyFontSize * 0.9,
                        ),
                        SizedBox(width: _horizontalPadding * 0.3),
                        Text(
                          _isEmailSent ? 'تم الإرسال بنجاح' : 'إرسال بريد التحقق',
                          style: _bodyStyle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_isEmailSent) ...[
            SizedBox(height: _verticalPadding * 0.5),
            Text(
              'تم إرسال رابط التفعيل بنجاح',
              style: _smallStyle.copyWith(
                color: _successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: _borderColor,
          margin: EdgeInsets.symmetric(vertical: _verticalPadding),
        ),
        Text(
          'تم تفعيل حسابك بالفعل؟',
          style: _bodyStyle.copyWith(
            color: _hintColor,
          ),
        ),
        SizedBox(height: _verticalPadding * 0.5),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
            child: Text(
              'تسجيل الدخول',
              style: _bodyStyle.copyWith(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}