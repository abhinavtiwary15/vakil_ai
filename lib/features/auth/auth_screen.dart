import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pinput/pinput.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/locale_service.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/shared_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showOtpInput = false;
  bool _isLoading = false;
  String? _verificationId;
  int _resendCountdown = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final phone = _phoneController.text.trim();
    await ref.read(authServiceProvider).sendOTP(
      phone,
      onCodeSent: (verificationId) {
        setState(() {
          _showOtpInput = true;
          _isLoading = false;
          _verificationId = verificationId;
          _startResendTimer();
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
      onAutoVerify: (credential) {
        _navigateToNextScreen();
      },
    );
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  Future<void> _verifyOTP(String otp) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).verifyOTP(otp);
      _navigateToNextScreen();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToNextScreen() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      context.go(AppRoutes.home);
    }
  }

  void _showGuestNameDialog(BuildContext context, String lang) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          lang == 'hi' ? 'अपना नाम बताएं' : 'What is your name?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'hi' ? 'हम आपको किस नाम से पुकारें?' : 'How should we address you?',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            VakilTextField(
              controller: controller,
              labelHi: 'नाम',
              labelEn: 'Name',
              hintHi: 'उदा: राहुल शर्मा',
              hintEn: 'e.g. Rahul Sharma',
              lang: lang,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang == 'hi' ? 'वापस' : 'Back'),
          ),
          VakilButton(
            text: lang == 'hi' ? 'शुरू करें' : 'Get Started',
            width: 120,
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                // Save name to Hive
                final box = await Hive.openBox('settings');
                await box.put('guestName', name);
                
                if (context.mounted) {
                  ref.read(guestModeProvider.notifier).state = true;
                  Navigator.pop(context);
                  context.go(AppRoutes.home);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text('⚖️', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VakilAI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.get('tagline', lang),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const LanguageToggle(), // Imported from shared_widgets
                  ],
                ),
              ),

              const SizedBox(height: 48),

              if (!_showOtpInput) ...[
                Text(
                  lang == 'hi' ? 'लॉगिन करें' : 'Sign In',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.get('enter_phone', lang),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (v) {
                      if (v == null || v.length != 10) {
                        return lang == 'hi' ? 'कृपया 10 अंकों का नंबर दर्ज करें' : 'Please enter 10 digit number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: AppStrings.get('phone_hint', lang),
                      hintText: '9876543210',
                      prefix: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text('+91  ', style: TextStyle(fontSize: 15, fontWeight: lang == 'hi' ? FontWeight.w500 : FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],

                const SizedBox(height: 24),

                VakilButton(
                  text: AppStrings.get('send_otp', lang),
                  onPressed: _sendOTP,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(lang == 'hi' ? 'या' : 'or', style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Sign-In
                VakilButton(
                  text: AppStrings.get('google_signin', lang),
                  isOutlined: true,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await ref.read(authServiceProvider).signInWithGoogle();
                    if (mounted) setState(() => _isLoading = false);
                    _navigateToNextScreen();
                  },
                  icon: Icons.g_mobiledata,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => _showGuestNameDialog(context, lang),
                    child: Text(
                      lang == 'hi' ? 'अभी छोड़ें' : 'Skip for now',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // OTP Input
                Text(
                  AppStrings.get('enter_otp', lang),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  lang == 'hi' 
                    ? '+91 ${_phoneController.text} पर भेजा गया' 
                    : 'Sent to +91 ${_phoneController.text}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _showOtpInput = false),
                  child: Text(
                    lang == 'hi' ? 'नंबर बदलें' : 'Change number', 
                    style: const TextStyle(fontSize: 13)
                  ),
                ),
                const SizedBox(height: 24),

                Pinput(
                  length: 6,
                  autofocus: true,
                  defaultPinTheme: PinTheme(
                    width: 52,
                    height: 56,
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surface,
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 52,
                    height: 56,
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surface,
                    ),
                  ),
                  onCompleted: _verifyOTP,
                ),

                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),

                const SizedBox(height: 16),

                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          lang == 'hi' 
                            ? '$_resendCountdown सेकंड में दोबारा भेजें' 
                            : 'Resend in ${_resendCountdown}s',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        )
                      : TextButton(
                          onPressed: _sendOTP,
                          child: Text(AppStrings.get('resend_otp', lang)),
                        ),
                ),
              ],

              const SizedBox(height: 40),

              Center(
                child: Text(
                  lang == 'hi'
                    ? 'जारी रखकर आप हमारी Privacy Policy और Terms of Service से सहमत होते हैं'
                    : 'By continuing, you agree to our Privacy Policy and Terms of Service',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
