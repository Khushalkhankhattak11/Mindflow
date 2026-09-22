import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class ResetView extends StatefulWidget {
  const ResetView({super.key});

  @override
  State<ResetView> createState() => _ResetViewState();
}

class _ResetViewState extends State<ResetView> {
  AuthViewModel? _viewModel;
  Offset _mouseOffset = Offset.zero;

  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<AuthViewModel>();
    if (_viewModel != vm) {
      _viewModel = vm;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel?.clearError();
        }
      });
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
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
                            // Header
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
                                  child: const Icon(
                                    Icons.key_outlined,
                                    color: Color(0xFF4B0082),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppStrings.appName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),

                            // Glassmorphic Card
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
                              child: viewModel.resetSent
                                  ? Column(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                          size: 56,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Email Sent',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Verification link has been sent to your email. Check your inbox to set a new password.',
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            color: secondaryTextColor,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 32),
                                        GestureDetector(
                                          onTap: () => Navigator.of(context).pop(),
                                          child: Container(
                                            width: double.infinity,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(26),
                                              border: Border.all(color: outlineColor, width: 1.5),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Back to Login',
                                              style: GoogleFonts.manrope(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.authResetPassword,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppStrings.authResetDesc,
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            color: secondaryTextColor,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 32),

                                        // Email Field
                                        _buildInputField(
                                          label: AppStrings.authEmailLabel,
                                          isFocused: _isEmailFocused,
                                          child: TextField(
                                            focusNode: _emailFocusNode,
                                            onChanged: viewModel.setEmail,
                                            keyboardType: TextInputType.emailAddress,
                                            textInputAction: TextInputAction.done,
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
 
                                         // Reset CTA Button
                                        GestureDetector(
                                          onTap: viewModel.canSubmitReset && !viewModel.isSubmitting
                                              ? viewModel.submitReset
                                              : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(28),
                                              gradient: viewModel.canSubmitReset
                                                  ?  LinearGradient(
                                                      colors: [primaryColor, primaryContainerColor],
                                                    )
                                                  : null,
                                              color: viewModel.canSubmitReset
                                                  ? null
                                                  : primaryContainerColor.withAlpha(102),
                                              boxShadow: viewModel.canSubmitReset
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
                                                    'Send Reset Email',
                                                    style: GoogleFonts.manrope(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: () => Navigator.of(context).pop(),
                                          child: Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(28),
                                              border: Border.all(color: outlineColor, width: 1.5),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Back to Login',
                                              style: GoogleFonts.manrope(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
}
