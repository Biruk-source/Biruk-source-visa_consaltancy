// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import Services for HapticFeedback & Formatters
import 'package:firebase_auth/firebase_auth.dart'; // Keep for FirebaseAuthException type
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'dart:ui'; // Import UI for BackdropFilter

// Import your FirebaseService, LocaleProvider AND AppStrings
import '../services/firebase_service.dart';
import '../providers/locale_provider.dart'; // Import LocaleProvider
import 'app_strings.dart'; // Import AppStrings

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  // --- Services and Controllers ---
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  // --- State ---
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AppStrings _strings; // Will hold localized strings

  // --- Animations ---
  late AnimationController _panelController;
  late AnimationController _buttonController;
  late Animation<Offset> _panelSlide;
  late Animation<double> _buttonScale;

  // --- Theme Colors ---
  final Color _primaryColor = Colors.teal; // Adjusted slightly
  final Color _accentColor = Colors.amber; // Consistent accent

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // String initialization deferred
    _panelController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
  }

  void _setupAnimations() {
    // ... (keep animation setup) ...
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
    _usernameController.dispose();
    _phoneController.dispose();
    _referralCodeController.dispose();
    _panelController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  // --- Authentication Method ---
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar(_strings.formErrorCheckForm);
      return;
    }
    _buttonController.forward().then((_) => _buttonController.reverse());
    setState(() => _isLoading = true);

    try {
      await _firebaseService.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
        _phoneController.text,
        _referralCodeController.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      // AuthWrapper handles navigation on success
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = _strings.signupErrorEmailInUse;
          break;
        case 'weak-password':
          errorMessage = _strings.signupErrorWeakPassword;
          break;
        default:
          errorMessage = e.message ?? _strings.signupErrorGenericSignupFailed;
      }
      _showErrorSnackbar(errorMessage);
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  // Optional: More specific phone validation
  // bool _isValidPhoneNumber(String phone) { return RegExp(r'^\+?[0-9]{10,}$').hasMatch(phone.trim()); }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>(); // Watch for changes
    _strings = AppLocalizations.getStrings(
      localeProvider.locale,
    ); // Update strings

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final textTheme = _strings.textTheme; // Get theme for correct font

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed:
              () =>
                  Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : null,
          tooltip: 'Back',
        ),
        actions: [
          _buildLanguageToggle(), // Add toggle button here
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SlideTransition(
            position: _panelSlide,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 40,
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                ),
                child: _buildGlassPanel(isSmallScreen, textTheme), // Pass theme
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // --- UI Building Widgets ---

  Widget _buildLanguageToggle() {
    final localeProvider = context.read<LocaleProvider>();
    return Tooltip(
      message: _strings.languageToggleTooltip,
      child: Padding(
        // Added padding for AppBar action spacing
        padding: const EdgeInsets.only(right: 8.0),
        child: Material(
          color: Colors.white.withOpacity(0.15),
          shape: const CircleBorder(),
          elevation: 1.0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              localeProvider.toggleLocale();
              HapticFeedback.lightImpact();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.translate,
                color: Colors.white.withOpacity(0.9),
                size: 22,
              ),
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
    // Use passed textTheme with correct font
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
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
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
                  _strings.signupCreateAccountTitle,
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
                  _strings.signupCreateAccountSubtitle,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    _strings.signupUsernameLabel,
                    Icons.person_outline,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return _strings.signupErrorUsernameRequired;
                    if (v.trim().length < 3)
                      return _strings.signupErrorUsernameMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    _strings.signupEmailLabel,
                    Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return _strings.signupErrorEmailRequired;
                    if (!_isValidEmail(v))
                      return _strings.signupErrorEmailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    _strings.signupPhoneNumberLabel,
                    Icons.phone_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return _strings
                          .signupErrorPhoneRequired; /*if(!_isValidPhoneNumber(v)) return _strings.signupErrorPhoneInvalid; */
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    _strings.signupPasswordLabel,
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
                      return _strings.signupErrorPasswordRequired;
                    if (v.length < 6)
                      return _strings.signupErrorPasswordMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referralCodeController,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    _strings.signupReferralCodeLabel,
                    Icons.card_giftcard_outlined,
                  ),
                ),
                const SizedBox(height: 30),
                _buildSignUpButton(textTheme),
                const SizedBox(height: 25),
                _buildLoginPrompt(textTheme),
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

  Widget _buildSignUpButton(TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _buttonScale,
      builder:
          (context, child) => Transform.scale(
            scale: _buttonScale.value,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
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
                        _strings.signupCreateAccountButton,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
            ),
          ),
    );
  }

  Widget _buildLoginPrompt(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _strings.signupLoginPrompt,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        TextButton(
          onPressed: () {
            if (!_isLoading) Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _strings.signupLoginButton,
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
} // End of _SignupScreenState
