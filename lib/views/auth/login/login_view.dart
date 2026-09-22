import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../signup/signup_view.dart';
import '../reset/reset_view.dart';
import '../../home/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  AuthViewModel? _viewModel;
  Offset _mouseOffset = Offset.zero;

  // Focus Nodes for scaling effect
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

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
      // Transition to HomeView dashboard on login success
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
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
    final titleColor = AppColors.assessmentTextPrimary;
    final subtitleColor = secondaryTextColor;
    final surfaceBorderColor = outlineColor;

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
            // Ethereal Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF0DBFF),
                    Color(0xFFE1E1F5),
                    Colors.white,
                    Color(0xFFF9F9F9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Orb 1
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              top: -200 + _mouseOffset.dy,
              left: -200 + _mouseOffset.dx,
              child: Container(
                width: 500,
                height: 500,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33F0DBFF),
                ),
              ),
            ),
            // Orb 2
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              bottom: -200 + (_mouseOffset.dy * -1.5),
              right: -200 + (_mouseOffset.dx * -1.5),
              child: Container(
                width: 600,
                height: 600,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33E1E1F5),
                ),
              ),
            ),

            // Content Canvas
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
                            // Brand Identity Header
                            Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(128),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryContainerColor.withAlpha(38),
                                        blurRadius: 32,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.spa_rounded,
                                    color: primaryContainerColor,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Welcome Back',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue your mindfulness journey',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),

                            // Main Glass Card Form
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(153),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryContainerColor.withAlpha(20),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Email Field
                                      Text(
                                        'EMAIL ADDRESS',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(204),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _isEmailFocused
                                                ? primaryContainerColor
                                                : surfaceBorderColor,
                                            width: _isEmailFocused ? 2 : 1,
                                          ),
                                        ),
                                        child: TextField(
                                          focusNode: _emailFocusNode,
                                          keyboardType: TextInputType.emailAddress,
                                          onChanged: viewModel.setEmail,
                                          style: GoogleFonts.manrope(
                                            fontSize: 15,
                                            color: titleColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'name@example.com',
                                            hintStyle: GoogleFonts.manrope(
                                              color: subtitleColor.withAlpha(128),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.mail_outline_rounded,
                                              color: _isEmailFocused
                                                  ? primaryContainerColor
                                                  : subtitleColor,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Password Field
                                      Text(
                                        'PASSWORD',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(204),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _isPasswordFocused
                                                ? primaryContainerColor
                                                : surfaceBorderColor,
                                            width: _isPasswordFocused ? 2 : 1,
                                          ),
                                        ),
                                        child: TextField(
                                          focusNode: _passwordFocusNode,
                                          obscureText: !_isPasswordVisible,
                                          onChanged: viewModel.setPassword,
                                          style: GoogleFonts.manrope(
                                            fontSize: 15,
                                            color: titleColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your password',
                                            hintStyle: GoogleFonts.manrope(
                                              color: subtitleColor.withAlpha(128),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outline_rounded,
                                              color: _isPasswordFocused
                                                  ? primaryContainerColor
                                                  : subtitleColor,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isPasswordVisible
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: subtitleColor,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordVisible = !_isPasswordVisible;
                                                });
                                              },
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Forgot Password Link
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => const ResetView(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: GoogleFonts.manrope(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: primaryContainerColor,
                                            ),
                                          ),
                                        ),
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

                                      // Login CTA Button
                                      GestureDetector(
                                        onTap: viewModel.canSubmitLogin && !viewModel.isSubmitting
                                            ? viewModel.submitLogin
                                            : null,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(28),
                                            gradient: viewModel.canSubmitLogin
                                                ?  LinearGradient(
                                                    colors: [primaryColor, primaryContainerColor],
                                                  )
                                                : null,
                                            color: viewModel.canSubmitLogin
                                                ? null
                                                : primaryContainerColor.withAlpha(102),
                                            boxShadow: viewModel.canSubmitLogin
                                                ? [
                                                    BoxShadow(
                                                      color: primaryContainerColor.withAlpha(64),
                                                      blurRadius: 24,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: viewModel.isEmailSubmitting
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : Text(
                                                  'Sign In',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Divider
                                      Row(
                                        children: [
                                          Expanded(child: Container(height: 1, color: surfaceBorderColor)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(
                                              'or continue with',
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: subtitleColor,
                                              ),
                                            ),
                                          ),
                                          Expanded(child: Container(height: 1, color: surfaceBorderColor)),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Google Sign In Button
                                      _buildSocialButton(
                                        label: 'Continue with Google',
                                        iconUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA1IygalH8s5Ucs4YAeErXHC8NPRvZK1PafkF9l_izmt07prCSrK88yPB9Q99E_yvbLk7T0jKciPCTLOS_CBUCn4SezcK13b0ySI9vHWlfYNsRNyxc_T3HdCESqe2jx1Cg8j_WIZ8tL-325QH2Ufz5MaEkc6CAK0wSE9zCnRPWUGYSUvwLuPHVQUitBRy1KUNJFqABdNJqDAJCkI4PNmtv2X14LED3o-HstCYFUrxzRVy9VIvjkwyJGZg',
                                        isLoading: viewModel.isGoogleSubmitting,
                                        onTap: viewModel.isSubmitting ? null : viewModel.signInWithGoogle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Footer link to SignupView
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.authNoAccount,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const SignupView(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                        transitionDuration: const Duration(milliseconds: 400),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
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

  // Social Button Widget builder
  Widget _buildSocialButton({
    required String label,
    required String iconUrl,
    bool isApple = false,
    bool isLoading = false,
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
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLoading
              ? [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: isApple ? Colors.white : AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ]
              : [
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
