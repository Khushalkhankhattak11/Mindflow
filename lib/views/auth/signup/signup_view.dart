import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../login/login_view.dart';
import '../../home/home_view.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  AuthViewModel? _viewModel;
  Offset _mouseOffset = Offset.zero;

  // Focus Nodes for scaling effect
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isNameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _nameFocusNode.addListener(() {
      setState(() => _isNameFocused = _nameFocusNode.hasFocus);
    });
    _emailFocusNode.addListener(() {
      setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<AuthViewModel>();
    if (_viewModel != vm) {
      _viewModel?.removeListener(_onStateChanged);
      _viewModel = vm;
      _viewModel?.addListener(_onStateChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel?.clearError();
        }
      });
    }
  }

  void _onStateChanged() {
    if (_viewModel?.isComplete == true && mounted) {
      // Complete signup and transition to HomeView
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _viewModel?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.welcomePrimary;
    final secondaryTextColor = AppColors.welcomeSecondaryText;
    final primaryContainerColor = AppColors.primaryContainer;
    final outlineColor = AppColors.welcomeOutline;

    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _mouseOffset = Offset(
              (event.localPosition.dx - MediaQuery.of(context).size.width / 2) * 0.02,
              (event.localPosition.dy - MediaQuery.of(context).size.height / 2) * 0.02,
            );
          });
        },
        child: Stack(
          children: [
            // 1. Ethereal Moving Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF0DBFF),
                    Color(0xFFE1E1F5),
                    Colors.white,
                    Color(0xFFF3F3F4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Orb 1 (Top Right)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              top: -200 + _mouseOffset.dy,
              right: -200 + _mouseOffset.dx,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF0DBFF).withAlpha(102),
                ),
              ),
            ),
            // Orb 2 (Bottom Left)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              bottom: -200 + (_mouseOffset.dy * -1.5),
              left: -200 + (_mouseOffset.dx * -1.5),
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE1E1F5).withAlpha(102),
                ),
              ),
            ),

            // 2. Main Canvas Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Consumer<AuthViewModel>(
                      builder: (context, viewModel, _) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mini Brand Header
                            Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(128),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.spa,
                                      color: primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppStrings.appName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Glassmorphic Signup Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(179),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withAlpha(102),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4B0082).withAlpha(10),
                                    blurRadius: 32,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.authBeginJourney,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppStrings.authCreateAccount,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Full Name Input
                                  _buildInputField(
                                    label: AppStrings.authNameLabel,
                                    isFocused: _isNameFocused,
                                    child: TextField(
                                      focusNode: _nameFocusNode,
                                      onChanged: viewModel.setName,
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.next,
                                      style: GoogleFonts.manrope(fontSize: 15, color: primaryColor),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your full name',
                                        hintStyle: GoogleFonts.manrope(color: secondaryTextColor.withAlpha(128)),
                                        border: InputBorder.none,
                                        prefixIcon: Icon(Icons.person_outline, color: _isNameFocused ? primaryContainerColor : secondaryTextColor),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Email Input
                                  _buildInputField(
                                    label: AppStrings.authEmailLabel,
                                    isFocused: _isEmailFocused,
                                    child: TextField(
                                      focusNode: _emailFocusNode,
                                      onChanged: viewModel.setEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: GoogleFonts.manrope(fontSize: 15, color: primaryColor),
                                      decoration: InputDecoration(
                                        hintText: 'name@example.com',
                                        hintStyle: GoogleFonts.manrope(color: secondaryTextColor.withAlpha(128)),
                                        border: InputBorder.none,
                                        prefixIcon: Icon(Icons.mail_outline, color: _isEmailFocused ? primaryContainerColor : secondaryTextColor),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Input
                                  _buildInputField(
                                    label: AppStrings.authPasswordLabel,
                                    isFocused: _isPasswordFocused,
                                    child: TextField(
                                      focusNode: _passwordFocusNode,
                                      onChanged: viewModel.setPassword,
                                      obscureText: !_isPasswordVisible,
                                      textInputAction: TextInputAction.done,
                                      style: GoogleFonts.manrope(fontSize: 15, color: primaryColor),
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        hintStyle: GoogleFonts.manrope(color: secondaryTextColor.withAlpha(128)),
                                        border: InputBorder.none,
                                        prefixIcon: Icon(Icons.lock_outline, color: _isPasswordFocused ? primaryContainerColor : secondaryTextColor),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                            color: secondaryTextColor,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                                          },
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Terms Agreement Checkbox
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: viewModel.termsAccepted,
                                        onChanged: (val) => viewModel.setTermsAccepted(val ?? false),
                                        activeColor: primaryContainerColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'I agree to the ',
                                              style: GoogleFonts.manrope(fontSize: 12, color: secondaryTextColor),
                                              children: [
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: primaryContainerColor),
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: primaryContainerColor),
                                                ),
                                                const TextSpan(text: '.'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Error Message Display
                                  if (viewModel.errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withAlpha(26),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.redAccent.withAlpha(77)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              viewModel.errorMessage!,
                                              style: GoogleFonts.manrope(
                                                color: Colors.redAccent,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Create Account CTA Button
                                  GestureDetector(
                                    onTap: viewModel.canSubmitSignup && !viewModel.isSubmitting
                                        ? viewModel.submitSignup
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: viewModel.canSubmitSignup
                                            ?  LinearGradient(
                                                colors: [primaryColor, primaryContainerColor],
                                              )
                                            : null,
                                        color: viewModel.canSubmitSignup
                                            ? null
                                            : primaryContainerColor.withAlpha(102),
                                        boxShadow: viewModel.canSubmitSignup
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF4B0082).withAlpha(64),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: viewModel.isSubmitting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              'Create Account',
                                              style: GoogleFonts.manrope(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ),

                                  // Divider
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: outlineColor.withAlpha(77),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          AppStrings.authOrContinue,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: outlineColor.withAlpha(77),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Google Sign In (Full width)
                                  _buildSocialButton(
                                    label: 'Continue with Google',
                                    iconUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA1IygalH8s5Ucs4YAeErXHC8NPRvZK1PafkF9l_izmt07prCSrK88yPB9Q99E_yvbLk7T0jKciPCTLOS_CBUCn4SezcK13b0ySI9vHWlfYNsRNyxc_T3HdCESqe2jx1Cg8j_WIZ8tL-325QH2Ufz5MaEkc6CAK0wSE9zCnRPWUGYSUvwLuPHVQUitBRy1KUNJFqABdNJqDAJCkI4PNmtv2X14LED3o-HstCYFUrxzRVy9VIvjkwyJGZg',
                                    onTap: viewModel.signInWithGoogle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Footer link to LoginView
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.authAlreadyAccount,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const LoginView(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                        transitionDuration: const Duration(milliseconds: 400),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryContainerColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required bool isFocused,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4C4451),
            ),
          ),
        ),
        AnimatedScale(
          scale: isFocused ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F4).withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused ? const Color(0xFF4B0082) : const Color(0xFFCEC3D3),
                width: 1.5,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4B0082).withAlpha(26),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String iconUrl,
    bool isApple = false,
    VoidCallback? onTap,
  }) {
    const outlineColor = Color(0xFFCEC3D3);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isApple ? Colors.black : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: isApple ? null : Border.all(color: outlineColor.withAlpha(77), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              iconUrl,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                isApple ? Icons.apple : Icons.g_mobiledata,
                color: isApple ? Colors.white : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isApple ? Colors.white : const Color(0xFF1A1C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
