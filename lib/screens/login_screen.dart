// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep for FirebaseAuthException type
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:flutter/services.dart'; // Import Services for HapticFeedback
import 'dart:ui'; // Import UI for BackdropFilter

// Import project files
import '../services/firebase_service.dart';
import '../providers/locale_provider.dart'; // Import LocaleProvider
import 'app_strings.dart'; // Import AppStrings (contains localization logic now)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // --- Services and Controllers ---
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- State ---
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AppStrings _strings; // Will hold localized strings

  // --- Animations ---
  late AnimationController _panelController;
  late AnimationController _buttonController;
  late Animation<Offset> _panelSlide;
  late Animation<double> _buttonScale;

  // --- Theme Colors (Consider moving to a theme file) ---
  final Color _primaryColor = const Color(0xFF00ACC1); // Teal variant
  final Color _accentColor = const Color(0xFFFFCA28); // Yellow accent

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // String initialization deferred to didChangeDependencies
    _panelController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize strings using Provider context access
    // listen: false is okay here as build() will use watch()
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
  }

  void _setupAnimations() {
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeOutQuad),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _panelController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  // --- Authentication Methods ---
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar(
        _strings.formErrorCheckForm,
      ); // Use specific localized string
      return;
    }

    _buttonController.forward().then((_) => _buttonController.reverse());
    setState(() => _isLoading = true);

    try {
      await _firebaseService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
        ); // Or '/welcome' if preferred
      }
      // AuthWrapper handles navigation on success
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential': // Handles newer Firebase errors too
          errorMessage =
              _strings
                  .loginErrorInvalidCredentials; // Specific localized message
          break;
        case 'invalid-email':
          errorMessage = _strings.loginErrorEmailInvalid;
          break;
        default:
          errorMessage =
              e.message ??
              _strings.loginErrorGenericLoginFailed; // Use specific generic
      }
      _showErrorSnackbar(errorMessage);
    } catch (e) {
      _showErrorSnackbar(_strings.errorGeneric); // Catch general errors
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    _buttonController.forward().then((_) => _buttonController.reverse());
    setState(() => _isLoading = true);

    try {
      await _firebaseService.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      // AuthWrapper handles navigation
    } on FirebaseAuthException catch (e) {
      // Handle specific errors if needed (e.g., account-exists-with-different-credential)
      _showErrorSnackbar(
        e.message ??
            '${_strings.loginSignInWithGoogleButton} ${_strings.errorActionFailed.toLowerCase()}',
      ); // Combine strings
    } catch (e) {
      _showErrorSnackbar(_strings.errorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (!_isValidEmail(_emailController.text)) {
      _showErrorSnackbar(_strings.loginErrorForgotPasswordEmailPrompt);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _firebaseService.sendPasswordResetEmail(_emailController.text);
      _showSuccessSnackbar(_strings.loginSuccessPasswordResetSent);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(
        e.message ??
            '${_strings.loginForgotPasswordButton} ${_strings.errorActionFailed.toLowerCase()}',
      );
    } catch (e) {
      _showErrorSnackbar(_strings.errorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Helper Methods ---
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Use watch here to rebuild UI when locale changes
    final localeProvider = context.watch<LocaleProvider>();
    _strings = AppLocalizations.getStrings(
      localeProvider.locale,
    ); // Update strings

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Determine text theme based on AppStrings for consistent font usage
    final textTheme = _strings.textTheme;

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SlideTransition(
            position: _panelSlide,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 60.0,
                ),
                child: _buildGlassPanel(isSmallScreen, textTheme), // Pass theme
              ),
            ),
          ),
          Positioned(
            // Position the language toggle button
            top: MediaQuery.of(context).padding.top + 15,
            right: 20,
            child: _buildLanguageToggle(),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // --- UI Building Widgets ---

  Widget _buildLanguageToggle() {
    final localeProvider =
        context.read<LocaleProvider>(); // Use read for callback
    return Tooltip(
      message: _strings.languageToggleTooltip,
      child: Material(
        color: Colors.white.withOpacity(0.15),
        shape: const CircleBorder(),
        elevation: 2.0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            localeProvider.toggleLocale();
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              Icons.translate,
              color: Colors.white.withOpacity(0.9),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00333A), Color(0xFF011015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: const Center(
        child: SpinKitCubeGrid(color: Color(0xFF00ACC1), size: 50.0),
      ),
    );
  }

  Widget _buildGlassPanel(bool isSmallScreen, TextTheme textTheme) {
    // Use the passed textTheme which has the correct font
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width:
              isSmallScreen
                  ? double.infinity
                  : MediaQuery.of(context).size.width * 0.5,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _strings.loginWelcomeTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.orbitron().fontFamily,
                    shadows: [
                      Shadow(
                        color: _primaryColor.withOpacity(0.7),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _strings.loginWelcomeSubtitle,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    _strings.loginEmailLabel,
                    Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return _strings.loginErrorEmailRequired;
                    if (!_isValidEmail(v))
                      return _strings.loginErrorEmailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    _strings.loginPasswordLabel,
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _primaryColor.withOpacity(0.7),
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return _strings.loginErrorPasswordRequired;
                    if (v.length < 6)
                      return _strings.loginErrorPasswordMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _strings.loginForgotPasswordButton,
                      style: textTheme.bodySmall?.copyWith(color: _accentColor),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSignInButton(textTheme),
                const SizedBox(height: 25),
                _buildDividerWithText(_strings.loginOrDivider, textTheme),
                const SizedBox(height: 25),
                _buildGoogleSignInButton(textTheme),
                const SizedBox(height: 30),
                _buildSignUpPrompt(textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    // Uses GoogleFonts locally here, but base font comes from theme
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: _primaryColor.withOpacity(0.8)),
      hintText: label,
      hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: _primaryColor, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 15.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(
        color: Colors.redAccent.shade100,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSignInButton(TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _buttonScale,
      builder:
          (context, child) => Transform.scale(
            scale: _buttonScale.value,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
                shadowColor: _primaryColor.withOpacity(0.4),
              ),
              child:
                  _isLoading
                      ? const SpinKitThreeBounce(
                        color: Colors.black,
                        size: 20.0,
                      )
                      : Text(
                        _strings.loginSignInButton,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
            ),
          ),
    );
  }

  Widget _buildDividerWithText(String text, TextTheme textTheme) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white38, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white38, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleSignInButton(TextTheme textTheme) {
    String googleLogoAsset = 'assets/google_logo.png'; // CHANGE IF NEEDED
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: Image.asset(
        googleLogoAsset,
        height: 20,
        width: 20,
        errorBuilder:
            (ctx, err, stack) => const Icon(
              Icons.g_mobiledata_rounded,
              color: Colors.white,
              size: 24,
            ),
      ),
      label: Text(
        _strings.loginSignInWithGoogleButton,
        style: textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: Colors.white54, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildSignUpPrompt(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _strings.loginSignUpPrompt,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        TextButton(
          onPressed: () {
            if (!_isLoading) Navigator.pushNamed(context, '/signup');
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _strings.loginSignUpButton,
            style: textTheme.bodyMedium?.copyWith(
              color: _accentColor,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: _accentColor,
            ),
          ),
        ),
      ],
    );
  }
} // End of _LoginScreenState
