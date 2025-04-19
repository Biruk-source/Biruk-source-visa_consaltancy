import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:google_fonts/google_fonts.dart'; // Base import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Import the strings file
import 'app_strings.dart'; // Adjust path if needed

// --- Constants ---
class _AppColors {
  static const primary = Color(0xFF00C9D4);
  static const secondary = Color(0xFFFFD600);
  static const darkBgStart = Color(0xFF011015);
  static const darkBgCenter = Color(0xFF00333A);
  static const darkBgEnd = Color(0xFF005850);
  static const highContrastBgStart = Colors.black;
  static const highContrastBgEnd = Color(0xFF303030);
  static const darkCardBg = Color(0xBD253439);
  static const highContrastCardBg = Color(0xE63A3A3A);
  static const white = Colors.white;
  static const white70 = Colors.white70;
  static const white54 = Colors.white54;
  static const black = Colors.black;
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFFA000);
  static const success = Color(0xFF4CAF50);
}

class _AppAssets {
  // ***** REPLACE WITH YOUR ACTUAL ASSET PATHS *****
  static const logoPlaceholder = 'logo_placeholder.png';
  static const googleLogoPlaceholder = 'google_logo_placeholder.png';
  static const officerPlaceholder = 'subtle_pattern.png';
  static const flagsPlaceholder = 'flags_placeholder.png';
  static const backgroundPattern = 'subtle_pattern.png';
}

class _AppDurations {
  static const fadeIn = Duration(milliseconds: 1600);
  static const ctaPulse = Duration(milliseconds: 400);
  static const shimmer = Duration(milliseconds: 2500);
}

class _AppRoutes {
  static const home = '/home';
  static const login = '/login';
  static const consultation = '/consultation'; // Placeholder
  static const officers = '/officers'; // Placeholder
  static const services = '/services'; // Placeholder
  static const languages =
      '/languages'; // Placeholder for 'Learn More' languages
}

class _PrefKeys {
  static const highContrast = 'high_contrast';
  static const darkMode = 'dark_mode';
  static const languageCode = 'language_code'; // Key to save language pref
}
// --- End Constants ---

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // --- Animation Controllers ---
  late AnimationController _fadeController;
  late AnimationController _ctaController;
  late AnimationController _shimmerController;

  // --- Animations ---
  late Animation<double> _fadeAnimation;
  late Animation<double> _ctaScale;
  late Animation<double> _shimmerAnimation;

  // --- State Variables ---
  bool _isHighContrast = false;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isDarkMode = false;
  bool _hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // --- Form Controllers ---
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newsletterFormKey = GlobalKey<FormState>();

  // --- Localization State ---
  late Locale _currentLocale;
  late AppStrings _strings;

  @override
  void initState() {
    super.initState();
    // Initialize Locale and Strings FIRST
    _currentLocale = const Locale('en'); // Default to English
    _strings = AppLocalizations.getStrings(_currentLocale);

    _setupAnimations();
    _listenToConnectivity();
    _initialize(); // Initialize will now load saved locale if available
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ctaController.dispose();
    _shimmerController.dispose();
    _connectivitySubscription?.cancel();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- Setup & Initialization ---
  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: _AppDurations.fadeIn,
    );
    _ctaController = AnimationController(
      vsync: this,
      duration: _AppDurations.ctaPulse,
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: _AppDurations.shimmer,
    )..repeat(reverse: true);
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );
    _ctaScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _ctaController,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn,
      ),
    );
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initialize() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHighContrast = prefs.getBool(_PrefKeys.highContrast) ?? false;
      _isDarkMode = prefs.getBool(_PrefKeys.darkMode) ?? false;
      _isLoggedIn = FirebaseAuth.instance.currentUser != null;

      // Load saved language preference
      String? savedLangCode = prefs.getString(_PrefKeys.languageCode);
      if (savedLangCode != null && ['en', 'am'].contains(savedLangCode)) {
        _currentLocale = Locale(savedLangCode);
        _strings = AppLocalizations.getStrings(_currentLocale);
      } else {
        // Set default if no preference saved or it's invalid
        _currentLocale = const Locale('en');
        _strings = AppLocalizations.getStrings(_currentLocale);
      }

      await _checkConnectivity(showSnackBar: false);
    } catch (e, s) {
      if (mounted)
        _showErrorSnackBar(
          _strings.errorInitializationFailed,
        ); // Uses localized string
      debugPrint('Initialization Error: $e\n$s');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
        if (!_hasInternet) _showNoInternetSnackBar();
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_PrefKeys.highContrast, _isHighContrast);
      await prefs.setBool(_PrefKeys.darkMode, _isDarkMode);
      await prefs.setString(
        _PrefKeys.languageCode,
        _currentLocale.languageCode,
      ); // Save current language
    } catch (e) {
      _showErrorSnackBar(_strings.errorCouldNotSavePrefs);
      debugPrint('Preference Save Error: $e');
    }
  }

  // --- Language Toggle ---
  void _toggleLanguage() async {
    HapticFeedback.lightImpact();
    final newLocale =
        _currentLocale.languageCode == 'en'
            ? const Locale('am')
            : const Locale('en');

    setState(() {
      _isLoading = true;
    });
    await Future.delayed(
      const Duration(milliseconds: 50),
    ); // Allow UI to show loading

    setState(() {
      _currentLocale = newLocale;
      _strings = AppLocalizations.getStrings(_currentLocale);
      _isLoading = false;
    });
    _savePreferences(); // Save the new language preference
  }

  // --- Connectivity Methods ---
  Future<void> _checkConnectivity({bool showSnackBar = true}) async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectivityStatus(results, showSnackBar: showSnackBar);
    } catch (e) {
      if (mounted) _showErrorSnackBar(_strings.errorConnectivityCheck);
      debugPrint('Connectivity Check Error: $e');
      if (mounted) setState(() => _hasInternet = false);
    }
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (mounted) _updateConnectivityStatus(results);
    });
  }

  void _updateConnectivityStatus(
    List<ConnectivityResult> results, {
    bool showSnackBar = true,
  }) {
    final bool hasNet =
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
    if (_hasInternet != hasNet) {
      if (mounted)
        setState(() {
          _hasInternet = hasNet;
        });
      if (!_isLoading) {
        if (!hasNet && showSnackBar)
          _showNoInternetSnackBar();
        else if (hasNet && showSnackBar)
          _showSuccessSnackBar(_strings.connectionRestored);
      }
    } else if (mounted) {
      setState(() {
        _hasInternet = hasNet;
      });
    }
  }

  // --- UI Helpers (Snackbars use _strings) ---
  void _showSnackBar(
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: _strings.textTheme.bodyMedium?.copyWith(
              color: _AppColors.black,
            ),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) => _showSnackBar(
    "ስህተት፦ $message",
    _AppColors.error,
  ); // Use appropriate language prefix
  void _showWarningSnackBar(String message) => _showSnackBar(
    "ማስጠንቀቂያ፦ $message",
    _AppColors.warning,
  ); // Use appropriate language prefix
  void _showSuccessSnackBar(String message) =>
      _showSnackBar(message, _AppColors.success);
  void _showNoInternetSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: _AppColors.black,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _strings.noInternet,
                  style: _strings.textTheme.bodyMedium?.copyWith(
                    color: _AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: _strings.retryButton,
            textColor: _AppColors.black,
            onPressed: () => _checkConnectivity(showSnackBar: true),
          ),
        ),
      );
    }
  }

  // --- URL Launcher ---
  Future<void> _launchUrlHelper(String url) async {
    HapticFeedback.lightImpact();
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw 'Could not launch $url';
    } catch (e) {
      _showErrorSnackBar(_strings.errorActionFailed);
      debugPrint('Launch URL error: $e');
    }
  }

  // --- Newsletter Form Submit ---
  void _submitNewsletter() {
    HapticFeedback.mediumImpact();
    if (_newsletterFormKey.currentState?.validate() ?? false) {
      String firstName = _firstNameController.text;
      String email = _emailController.text;
      String phone = _phoneController.text;
      print(
        'Newsletter: $firstName, $email, $phone',
      ); /* !!! REPLACE WITH ACTUAL SUBMISSION !!! */
      _firstNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      FocusScope.of(context).unfocus();
      _showSuccessSnackBar(_strings.successSubscription);
    } else {
      _showWarningSnackBar(_strings.formErrorCheckForm);
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isSmallScreen = screenSize.width < 600;
    final bgGradient = LinearGradient(
      colors:
          _isHighContrast
              ? [_AppColors.highContrastBgStart, _AppColors.highContrastBgEnd]
              : [
                _AppColors.darkBgStart,
                _AppColors.darkBgCenter,
                _AppColors.darkBgEnd,
              ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: _isHighContrast ? null : [0.0, 0.4, 1.0],
    );
    final cardBackgroundColor =
        _isHighContrast ? _AppColors.highContrastCardBg : _AppColors.darkCardBg;
    final cardTextColor = _AppColors.white;
    final cardTextSecondaryColor = _AppColors.white70;

    // Apply Theme with correct TextTheme for the current locale
    return Theme(
      data: Theme.of(context).copyWith(textTheme: _strings.textTheme),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: bgGradient),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage(_AppAssets.backgroundPattern),
                    fit: BoxFit.cover,
                    opacity: _isHighContrast ? 0.05 : 0.08,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child:
                    _isLoading
                        ? _buildLoadingIndicator()
                        : Stack(
                          children: [
                            _buildGlobalMainContent(
                              isSmallScreen,
                              cardBackgroundColor,
                              cardTextColor,
                              cardTextSecondaryColor,
                            ), // Content sections use _strings
                            _buildAccessibilityToggles(
                              isSmallScreen,
                              cardBackgroundColor,
                            ), // Includes language toggle now
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Loading Indicator ---
  Widget _buildLoadingIndicator() => const Center(
    child: SpinKitCubeGrid(color: _AppColors.secondary, size: 50.0),
  );

  // --- Main Content ---
  Widget _buildGlobalMainContent(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    final double hPad = isSmallScreen ? 20.0 : 40.0;
    final double vPad = isSmallScreen ? 30.0 : 50.0;
    const double heroInterval = 0.3,
        statsInterval = 0.4,
        expertiseInterval = 0.55,
        teamInterval = 0.65,
        servicesInterval = 0.75,
        reachInterval = 0.8,
        situationsInterval = 0.85,
        freebieInterval = 0.9,
        testimonialsInterval = 0.95,
        languagesInterval = 0.98,
        newsletterInterval = 1.0,
        finalCtaInterval = 1.0,
        footerInterval = 1.0;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            left: hPad,
            right: hPad,
            top: vPad + 40,
            bottom: vPad,
          ), // Extra top padding for fixed header/toggles
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildAnimatedSection(
                intervalStart: 0.0,
                intervalEnd: heroInterval,
                child: _buildHeroSection(isSmallScreen),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.1,
                intervalEnd: statsInterval,
                child: _buildStatsRow(isSmallScreen, cardTextColor),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.2,
                intervalEnd: expertiseInterval,
                child: _buildExpertiseCards(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.3,
                intervalEnd: teamInterval,
                child: _buildTeamSection(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.4,
                intervalEnd: servicesInterval,
                child: _buildServicesSection(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.45,
                intervalEnd: reachInterval,
                child: _buildReachSection(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.5,
                intervalEnd: situationsInterval,
                child: _buildSituationsCard(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.55,
                intervalEnd: freebieInterval,
                child: _buildLeadMagnetCard(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 50),
              _buildAnimatedSection(
                intervalStart: 0.6,
                intervalEnd: testimonialsInterval,
                child: _buildTestimonialsSection(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 50),
              _buildAnimatedSection(
                intervalStart: 0.65,
                intervalEnd: languagesInterval,
                child: _buildLanguagesSection(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 50),
              _buildAnimatedSection(
                intervalStart: 0.7,
                intervalEnd: newsletterInterval,
                child: _buildNewsletterSection(
                  isSmallScreen,
                  cardBackgroundColor,
                  cardTextColor,
                  cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 60),
              _buildAnimatedSection(
                intervalStart: 0.75,
                intervalEnd: finalCtaInterval,
                child: _buildFinalCta(isSmallScreen, cardTextColor),
              ),
              const SizedBox(height: 40),
              _buildAnimatedSection(
                intervalStart: 0.8,
                intervalEnd: footerInterval,
                child: _buildFooterStats(isSmallScreen, cardTextSecondaryColor),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }

  // --- Helper: Animation Section ---
  Widget _buildAnimatedSection({
    required double intervalStart,
    required double intervalEnd,
    double verticalOffset = 20.0,
    required Widget child,
  }) => FadeTransition(
    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Interval(
          intervalStart.clamp(0.0, 1.0),
          intervalEnd.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    ),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, verticalOffset / 50),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            intervalStart.clamp(0.0, 1.0),
            intervalEnd.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
      child: child,
    ),
  );

  // --- Section Builders (Using _strings) ---

  Widget _buildHeroSection(bool isSmallScreen) {
    final headlineStyle = TextStyle(
      fontSize: isSmallScreen ? 28 : 40,
      fontWeight: FontWeight.w600,
      color: _AppColors.white,
      height: 1.2,
    );

    final subHeadlineStyle = TextStyle(
      fontSize: isSmallScreen ? 16 : 20,
      color: _AppColors.white70,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _strings.heroHeadline,
          textAlign: TextAlign.center,
          style: headlineStyle,
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Container(
                width: isSmallScreen ? 80 : 120,
                height: isSmallScreen ? 80 : 120,
                decoration: BoxDecoration(
                  color: _AppColors.darkCardBg.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _AppColors.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    _AppAssets.officerPlaceholder,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (c, o, s) => Icon(
                          Icons.person_outline_rounded,
                          color: _AppColors.secondary,
                          size: isSmallScreen ? 35 : 40,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Text(
          _strings.heroSubheadline,
          textAlign: TextAlign.center,
          style: subHeadlineStyle,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed:
              () => Navigator.pushNamed(context, _AppRoutes.consultation),
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          label: Text(
            _strings.bookConsultationButton,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _AppColors.secondary,
            foregroundColor: _AppColors.black,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isSmallScreen, Color textColor) {
    Widget buildStat(String value, String label) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: isSmallScreen ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: _AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 13,
            color: textColor.withOpacity(0.8),
            height: 1.2,
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: buildStat(
              "1,000,000+",
              _strings.statsInterviewsConductedLabel,
            ),
          ),
          Expanded(child: buildStat("10+", _strings.statsLanguagesSpokenLabel)),
          Expanded(child: buildStat("30+", _strings.statsConsulatesLabel)),
        ],
      ),
    );
  }

  Widget _buildExpertiseCards(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    Widget buildExpertiseCard({
      required IconData icon,
      required String title,
      required String description,
    }) => _buildGlassCard(
      backgroundColor: cardBackgroundColor,
      borderColor: _AppColors.primary.withOpacity(0.3),
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _AppColors.secondary, size: 30),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: cardTextSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
    final cards = [
      buildExpertiseCard(
        icon: Icons.how_to_reg_outlined,
        title: _strings.expertiseCard1Title,
        description: _strings.expertiseCard1Desc,
      ),
      buildExpertiseCard(
        icon: Icons.report_problem_outlined,
        title: _strings.expertiseCard2Title,
        description: _strings.expertiseCard2Desc,
      ),
      buildExpertiseCard(
        icon: Icons.lan_outlined,
        title: _strings.expertiseCard3Title,
        description: _strings.expertiseCard3Desc,
      ),
    ];
    if (isSmallScreen) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 25),
          cards[1],
          const SizedBox(height: 25),
          cards[2],
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 25),
          Expanded(child: cards[1]),
          const SizedBox(width: 25),
          Expanded(child: cards[2]),
        ],
      );
    }
  }

  Widget _buildTeamSection(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    return _buildGlassCard(
      backgroundColor: cardBackgroundColor,
      gradientBorder: LinearGradient(
        colors: [
          _AppColors.secondary.withOpacity(0.5),
          _AppColors.primary.withOpacity(0.5),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _strings.teamHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _strings.teamDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: cardTextSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, _AppRoutes.officers),
            child: Text(
              _strings.meetOfficersButton,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _AppColors.secondary,
              side: const BorderSide(color: _AppColors.secondary, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    Widget buildVisaList(String title, List<String> visas) => ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _AppColors.secondary,
        ),
      ),
      iconColor: _AppColors.secondary,
      collapsedIconColor: _AppColors.secondary.withOpacity(0.7),
      initiallyExpanded: !isSmallScreen,
      childrenPadding: const EdgeInsets.only(left: 16, bottom: 10, right: 16),
      children:
          visas
              .map(
                (visa) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    "• $visa",
                    style: TextStyle(
                      fontSize: 14,
                      color: cardTextSecondaryColor,
                    ),
                  ),
                ),
              )
              .toList(),
    );
    return _buildGlassCard(
      backgroundColor: cardBackgroundColor,
      borderColor: _AppColors.primary.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _strings.servicesHeadline,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _strings.servicesSubheadline,
            style: TextStyle(fontSize: 15, color: cardTextSecondaryColor),
          ),

          const SizedBox(height: 20),
          buildVisaList(_strings.servicesNivTitle, _strings.nivVisaTypes),
          const Divider(color: _AppColors.white54, height: 20, thickness: 0.5),
          buildVisaList(_strings.servicesIvTitle, _strings.ivVisaTypes),
        ],
      ),
    );
  }

  Widget _buildReachSection(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    return _buildGlassCard(
      backgroundColor: cardBackgroundColor,
      gradientBorder: LinearGradient(
        colors: [
          _AppColors.primary.withOpacity(0.6),
          _AppColors.secondary.withOpacity(0.6),
        ],
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _strings.reachHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _strings.reachDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: cardTextSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            height: isSmallScreen ? 60 : 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _AppColors.darkCardBg.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              _AppAssets.flagsPlaceholder,
              fit: BoxFit.cover,
              errorBuilder:
                  (c, o, s) => Center(
                    child: Text(
                      _strings.reachImagePlaceholder,
                      style: TextStyle(color: _AppColors.white54),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSituationsCard(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    final List<String> situations = _strings.situationList;
    return _buildGlassCard(
      backgroundColor: cardBackgroundColor,
      borderColor: _AppColors.secondary.withOpacity(0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _strings.situationsHeadline,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                situations
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: _AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cardTextSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 15),
          Text(
            _strings.situationsContactPrompt,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: _AppColors.white54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: TextButton(
              onPressed:
                  () => Navigator.pushNamed(context, _AppRoutes.services),
              child: Text(
                _strings.learnMoreServicesLink,
                style: TextStyle(
                  color: _AppColors.secondary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadMagnetCard(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    return _buildGlassCard(
      backgroundColor: cardBackgroundColor,
      gradientBorder: LinearGradient(
        colors: [
          _AppColors.primary.withOpacity(0.7),
          _AppColors.secondary.withOpacity(0.7),
        ],
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _strings.leadMagnetHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _strings.leadMagnetDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: cardTextSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed:
                () => _launchUrlHelper(
                  "https://example.com/f1-guide",
                ), // Assuming same guide URL
            child: Text(
              _strings.downloadFreeButton,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.secondary,
              foregroundColor: _AppColors.black,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    final List<Map<String, String>> testimonials = _strings.testimonials;
    Widget buildTestimonialCard(Map<String, String> testimonial) =>
        _buildGlassCard(
          backgroundColor: cardBackgroundColor.withOpacity(0.9),
          borderColor: _AppColors.secondary.withOpacity(0.3),
          borderRadius: 12,
          blurSigma: 3,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (_) => const Icon(
                        Icons.star_rounded,
                        color: _AppColors.secondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.asset(
                      _AppAssets.googleLogoPlaceholder,
                      errorBuilder:
                          (c, o, s) => Center(
                            child: Text(
                              "G",
                              style: TextStyle(
                                color: _AppColors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "“${testimonial['quote']}”",
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: cardTextSecondaryColor,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                testimonial['name'] ?? _strings.anonymous,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cardTextColor,
                ),
              ),
              Text(
                testimonial['source'] ?? _strings.googleReviewSource,
                style: const TextStyle(fontSize: 11, color: _AppColors.white54),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _strings.testimonialsHeadline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: cardTextColor,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 20.0,
          runSpacing: 20.0,
          alignment: WrapAlignment.center,
          children:
              testimonials
                  .take(isSmallScreen ? 3 : 4)
                  .map(
                    (t) => SizedBox(
                      width: isSmallScreen ? double.infinity : 300,
                      child: buildTestimonialCard(t),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    Widget flagIcon(String langCode) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.2),
      ),
      child: Icon(
        Icons.flag_circle_outlined,
        color: _AppColors.white70,
        size: 24,
      ),
    ); // Placeholder icon for all flags
    return _buildGlassCard(
      backgroundColor: cardBackgroundColor,
      borderColor: _AppColors.primary.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _strings.languagesHeadline,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _strings.languagesDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: cardTextSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              flagIcon("tr"),
              flagIcon("br"),
              flagIcon("fr"),
              flagIcon("cn"),
              flagIcon("in"),
              flagIcon("ir"),
              flagIcon("es"),
              flagIcon("mx"),
              flagIcon("us"),
              flagIcon("ee"),
            ],
          ),
          const SizedBox(height: 25),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, _AppRoutes.languages),
            child: Text(
              _strings.learnMoreButton,
              style: const TextStyle(
                color: _AppColors.secondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsletterSection(
    bool isSmallScreen,
    Color cardBackgroundColor,
    Color cardTextColor,
    Color cardTextSecondaryColor,
  ) {
    InputDecoration inputDecoration(
      String label, {
      bool isRequired = false,
    }) => InputDecoration(
      labelText: isRequired ? "$label*" : label,
      labelStyle: TextStyle(
        color: _AppColors.white70.withOpacity(0.8),
        fontSize: 14,
      ),

      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.secondary, width: 1.5),
      ),
      errorStyle: TextStyle(
        color: _AppColors.error.withOpacity(0.9),
        fontSize: 11,
      ),
    );
    return _buildGlassCard(
      backgroundColor: cardBackgroundColor.withOpacity(0.95),
      gradientBorder: LinearGradient(
        colors: [
          _AppColors.primary.withOpacity(0.3),
          _AppColors.secondary.withOpacity(0.3),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _newsletterFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _strings.newsletterHeadline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: cardTextColor,
              ),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _firstNameController,
              decoration: inputDecoration(_strings.newsletterFirstNameLabel),
              style: const TextStyle(color: _AppColors.white),

              validator:
                  (v) =>
                      (v == null || v.isEmpty)
                          ? _strings.formErrorRequired
                          : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _emailController,
              decoration: inputDecoration(
                _strings.newsletterEmailLabel,
                isRequired: true,
              ),
              style: const TextStyle(color: _AppColors.white),

              keyboardType: TextInputType.emailAddress,
              validator:
                  (v) =>
                      (v == null || v.isEmpty)
                          ? _strings.formErrorRequired
                          : (!v.contains('@') || !v.contains('.'))
                          ? _strings.formErrorInvalidEmail
                          : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _phoneController,
              decoration: inputDecoration(
                _strings.newsletterPhoneOptionalLabel,
              ),
              style: const TextStyle(color: _AppColors.white),

              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            Text(
              _strings.newsletterDisclaimer,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: _AppColors.white54,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _submitNewsletter,
              child: Text(
                _strings.subscribeButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.secondary,
                foregroundColor: _AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalCta(bool isSmallScreen, Color cardTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _strings.finalCtaHeadline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 30 : 42,
            fontWeight: FontWeight.bold,
            color: cardTextColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _strings.finalCtaSubheadline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: _AppColors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
        _buildCtaButton(isSmallScreen),
      ],
    ); // Reuses CTA button
  }

  Widget _buildFooterStats(bool isSmallScreen, Color cardTextSecondaryColor) {
    Widget statText(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: cardTextSecondaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10.0,
          runSpacing: 8.0,
          children: [
            statText(_strings.footerStatCountries),
            statText(_strings.footerStatApplicants),
            statText(_strings.footerStatRecommendation),
          ],
        ),
        const SizedBox(height: 25),
        Container(
          height: 40,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            _AppAssets.logoPlaceholder,
            errorBuilder:
                (c, o, s) => Center(
                  child: Text(
                    _strings.footerLogoAltText,
                    style: TextStyle(
                      color: _AppColors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  // --- Accessibility Toggles & Helper ---
  Widget _buildAccessibilityToggles(
    bool isSmallScreen,
    Color cardBackgroundColor,
  ) {
    return Positioned(
      top: 16,
      right: 16,
      child: Row(
        // Simple row for toggles now, no GlassCard to simplify
        children: [
          _buildToggleButton(
            icon:
                _isHighContrast ? Icons.contrast : Icons.brightness_6_outlined,
            isActive: _isHighContrast,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isHighContrast = !_isHighContrast);
              _savePreferences();
            },
            tooltip: _strings.highContrastTooltip,
          ), // Use string key
          const SizedBox(width: 8), // Space between buttons
          _buildToggleButton(
            icon: Icons.language,
            isActive:
                false, // Language toggle appearance - always 'inactive' style?
            onTap: _toggleLanguage,
            tooltip:
                _currentLocale.languageCode == 'en'
                    ? 'አማርኛ ቀይር'
                    : 'Switch to English',
          ), // Dynamic tooltip based on current lang
          const SizedBox(width: 8), // Space between buttons
          _buildToggleButton(
            icon: _isDarkMode ? Icons.dark_mode : Icons.light_mode_outlined,
            isActive: _isDarkMode,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isDarkMode = !_isDarkMode);
              _savePreferences();
              _showSuccessSnackBar(_strings.successPrefsSaved);
            },
            tooltip: _strings.darkModeTooltip,
          ), // Use string key
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    // Fix: Ensure Tooltip ALWAYS has a non-empty message
    String effectiveTooltip = tooltip.isEmpty ? 'Toggle Option' : tooltip;
    return Tooltip(
      message: effectiveTooltip, // Pass the validated tooltip string here
      child: Material(
        // Need Material for InkWell splash
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(8), // Standard padding
            decoration: BoxDecoration(
              color:
                  isActive
                      ? _AppColors.primary.withOpacity(0.8)
                      : _AppColors.darkCardBg.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: _AppColors.primary.withOpacity(0.6),
                width: 1,
              ),
            ), // Add subtle border always?
            child: Icon(
              icon,
              color: isActive ? _AppColors.black : _AppColors.secondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // --- CTA Button Builder ---
  Widget _buildCtaButton(bool isSmallScreen) {
    final String buttonText =
        _isLoggedIn
            ? _strings.goToDashboardButton
            : _strings.getStartedButton; // Use localized strings
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_ctaScale, _shimmerController]),
        builder:
            (context, child) => Transform.scale(
              scale: _ctaScale.value,
              child: GestureDetector(
                onTapDown: (_) => _ctaController.forward(),
                onTapCancel: () => _ctaController.reverse(),
                onTapUp: (_) async {
                  HapticFeedback.mediumImpact();
                  _ctaController.reverse();
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (mounted)
                    Navigator.pushReplacementNamed(
                      context,
                      _isLoggedIn ? _AppRoutes.home : _AppRoutes.login,
                    );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.primary.withOpacity(0.5),
                        blurRadius: 18,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: _AppColors.secondary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 16 : 18,
                            horizontal: isSmallScreen ? 40 : 60,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _AppColors.primary,
                                _AppColors.secondary,
                              ],
                              begin: Alignment(-1.2, -1.0),
                              end: Alignment(1.2, 1.0),
                            ),
                          ),
                          child: Text(
                            buttonText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _AppColors.black,
                              letterSpacing: 0.5,
                            ).copyWith(fontSize: isSmallScreen ? 16 : 18),
                          ),
                        ),
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _shimmerAnimation,
                            builder:
                                (context, child) => FractionallySizedBox(
                                  widthFactor: 0.5,
                                  alignment: Alignment(
                                    _shimmerAnimation.value,
                                    0.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.5),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.1, 0.5, 0.9],
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  // --- Reusable Glass Card Widget ---
  Widget _buildGlassCard({
    required Color backgroundColor,
    Color? borderColor,
    Gradient? gradientBorder,
    double borderWidth = 1.5,
    double borderRadius = 16.0,
    double blurSigma = 4.0,
    EdgeInsets padding = const EdgeInsets.all(16.0),
    required Widget child,
  }) {
    assert(
      borderColor != null || gradientBorder != null,
      'Must provide borderColor or gradientBorder',
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border:
                  gradientBorder != null
                      ? GradientBoxBorder(
                        gradient: gradientBorder,
                        width: borderWidth,
                      )
                      : Border.all(color: borderColor!, width: borderWidth),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
} // End of _WelcomeScreenState

// --- Helper class for Gradient Borders ---
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  const GradientBoxBorder({required this.gradient, this.width = 1.0});
  @override
  BorderSide get bottom => BorderSide.none;
  @override
  BorderSide get top => BorderSide.none;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);
  @override
  bool get isUniform => true;
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (borderRadius != null) {
      final RRect outer = borderRadius.toRRect(rect);
      final RRect inner = outer.deflate(width);
      final Paint paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawDRRect(outer, inner, paint);
    } else {
      final Paint paint =
          Paint()
            ..shader = gradient.createShader(rect)
            ..strokeWidth = width
            ..style = PaintingStyle.stroke;
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient.scale(t), width: width * t);
}
