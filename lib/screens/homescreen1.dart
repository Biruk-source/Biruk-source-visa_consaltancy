// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:firebase_auth/firebase_auth.dart' hide UserProfile;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // For ImageFilter
import 'package:intl/intl.dart'; // For Date Formatting

// Import project files
import '../services/firebase_service.dart';
import '../providers/locale_provider.dart';
import '../app_strings.dart';
import '../models/user_profile.dart';
import '../models/visa_application.dart';

// Screen Imports for Navigation
import 'profile_screen.dart';
import 'setting_screen.dart';
import 'login_screen.dart';
import 'visa_applications_screen.dart';
import 'visa_recommendations_screen.dart';

// --- Constants for Styling & Layout ---
class _AppStyle {
  static const double cardRadius = 18.0;
  static const double hPadding = 20.0;
  static const double vPadding = 16.0;
  static const double sectionSpacing = 24.0;

  // Colors (Refined Palette)
  static const Color primaryAccent = Color(
    0xFF26C6DA,
  ); // Slightly brighter cyan
  static const Color secondaryAccent = Color(0xFFFFD54F); // Amber
  static const Color bgColor = Color(0xFF0A191E); // Very dark blue/teal base
  static const Color cardBg = Color(0xFF182C33); // Darker, less blue card
  static const Color cardBgSubtle = Color(0xFF14252A); // Even subtler card bg
  static const Color cardBorder = Color(0xFF37474F); // BlueGrey border
  static const Color textColor = Color(0xFFE0E0E0); // Off-white
  static const Color textColorMuted = Color(0xFF9E9E9E); // Grey
  static const Color success = Color(0xFF66BB6A); // Softer green
  static const Color error = Color(0xFFEF5350); // Softer red
  static const Color pending = Color(0xFF42A5F5); // Softer blue
  static const Color warning = Color(
    0xFFFFCA28,
  ); // Use secondary accent for warning
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --- Services & State ---
  final FirebaseService _firebaseService = FirebaseService();
  late AppStrings _strings;
  UserProfile? _userProfile;
  List<VisaApplication> _applications = [];
  Stream<QuerySnapshot>? _notificationStream;
  bool _isLoading = true;
  bool _isHighContrast = false; // Keep for accessibility option
  bool _isMenuOpen = false;
  String _selectedMenuItem = 'Dashboard';

  // --- Animation Controllers ---
  late AnimationController _staggerController;
  late AnimationController _menuController;
  late AnimationController _buttonPulseController;

  // --- Animations ---
  late Animation<double> _menuAnimation;
  late Animation<double> _buttonPulseAnimation;

  // --- Lifecycle & Data Fetching ---
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _menuController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 350),
    );
    _menuAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeInOutCubic),
    );
    _buttonPulseAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeData() async {
    await _loadPreferences();
    await _fetchData();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted)
        setState(
          () => _isHighContrast = prefs.getBool('high_contrast') ?? false,
        );
    } catch (e) {
      if (mounted) _showErrorSnackbar(_strings.errorCouldNotSavePrefs);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('high_contrast', _isHighContrast);
    } catch (e) {
      if (mounted) _showErrorSnackbar(_strings.errorCouldNotSavePrefs);
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _firebaseService.getCurrentUser();
      if (user != null) {
        final results = await Future.wait([
          _firebaseService.getUserProfile(user.uid),
          _firebaseService
              .getUserApplications(user.uid)
              .catchError(
                (_) => <VisaApplication>[],
              ) /* Catch app fetch error */,
        ]);
        _userProfile = results[0] as UserProfile?;
        _applications = results[1] as List<VisaApplication>;
        _notificationStream = _firebaseService
            .getUserNotificationsStream(user.uid, limit: 5)
            .handleError((_) {
              /* Handle stream error */
            });
        if (_userProfile == null && mounted) {
          await _logout();
          return;
        }
        if (mounted) {
          _staggerController.forward(from: 0.0);
        }
      } else {
        if (mounted) await _logout();
        return;
      }
    } catch (e) {
      debugPrint("Fetch Data Error: $e");
      if (mounted) _showErrorSnackbar(_strings.errorGeneric);
      _userProfile = null;
      _applications = [];
      _notificationStream = Stream.error(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    /* ... (Keep previous logout logic with localization) ... */
    String confirmTitle =
        _strings.locale.languageCode == 'am' ? 'መውጣት ያረጋግጡ' : 'Confirm Logout';
    String confirmContent =
        _strings.locale.languageCode == 'am'
            ? 'ከመለያዎ መውጣት እርግጠኛ ነዎት?'
            : 'Are you sure?';
    String cancelButton =
        _strings.locale.languageCode == 'am' ? 'ይቅር' : 'Cancel';
    String logoutButton =
        _strings.locale.languageCode == 'am' ? 'ውጣ' : 'Logout';
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              confirmTitle,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              confirmContent,
              style: GoogleFonts.montserrat(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  cancelButton,
                  style: GoogleFonts.montserrat(
                    color: _AppStyle.secondaryAccent,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  logoutButton,
                  style: GoogleFonts.montserrat(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await _firebaseService.signOut();
        if (mounted)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
      } catch (e) {
        if (mounted)
          _showErrorSnackbar('${_strings.errorActionFailed} (Logout)');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- Helpers ---
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: _AppStyle.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.grey[900])),
        backgroundColor: _AppStyle.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateTo(String routeName) {
    Widget? targetScreen;
    switch (routeName) {
      case '/profile':
        targetScreen = const ProfileScreen();
        break;
      case '/settings':
        targetScreen = const SettingScreen();
        break;
      case '/visa_progress':
        targetScreen = const VisaApplicationsScreen();
        break;
      case '/recommendations':
        targetScreen = VisaRecommendationsScreen();
        break;
      default:
        debugPrint("Unknown route: $routeName");
    }
    if (targetScreen != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      ).then((_) {
        if (routeName == '/settings') _loadPreferences();
      });
    }
  }

  void _pulseButton() {
    if (!mounted) return;
    _buttonPulseController.forward().then((_) {
      if (mounted) _buttonPulseController.reverse();
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    String langCode = _strings.locale.languageCode;
    if (diff.inDays > 7)
      return DateFormat('MMM dd, yyyy', langCode).format(dateTime);
    if (diff.inDays >= 1)
      return '${diff.inDays}${langCode == 'am' ? 'ቀ' : 'd'} ago';
    if (diff.inHours >= 1)
      return '${diff.inHours}${langCode == 'am' ? 'ሰ' : 'h'} ago';
    if (diff.inMinutes >= 1)
      return '${diff.inMinutes}${langCode == 'am' ? 'ደ' : 'm'} ago';
    return _strings.locale.languageCode == 'am' ? 'አሁን' : 'Just now';
  }

  Future<void> _markAllNotificationsRead() async {
    if (_userProfile != null) {
      try {
        await _firebaseService.markAllNotificationsAsRead(_userProfile!.uid);
        if (mounted)
          _showSuccessSnackbar(
            'Notifications marked read' /* TODO: Localize */,
          );
      } catch (e) {
        if (mounted)
          _showErrorSnackbar(
            'Failed to mark notifications read' /* TODO: Localize */,
          );
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    _strings = AppLocalizations.getStrings(localeProvider.locale);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isWeb = MediaQuery.of(context).size.width >= 900;
    final textTheme = _strings.textTheme.apply(
      bodyColor: _AppStyle.textColor,
      displayColor: _AppStyle.textColor,
    );

    if (_isLoading) return _buildLoadingScreen();
    if (_userProfile == null) return _buildErrorScreen(textTheme);

    return Scaffold(
      backgroundColor: _AppStyle.bgColorStart, // Set base background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                _isHighContrast
                    ? [Colors.black, Colors.black87]
                    : [_AppStyle.bgColorStart, _AppStyle.bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWeb) _buildFixedSidebar(textTheme),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchData,
                      color: _AppStyle.primaryAccent,
                      backgroundColor: _AppStyle.cardBg,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          _buildSliverAppBar(
                            isSmallScreen,
                            textTheme,
                            localeProvider,
                            isWeb,
                          ),
                          // Use a single SliverPadding with SliverLayoutBuilder for dynamic grid/list
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _AppStyle.hPadding,
                              vertical: _AppStyle.sectionSpacing,
                            ),
                            sliver: _buildDashboardContent(
                              isSmallScreen,
                              textTheme,
                            ), // New method for content
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isWeb && _isMenuOpen) _buildCollapsibleDrawer(textTheme),
            ],
          ),
        ),
      ),
    );
  }

  // --- Loading & Error Screens ---
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                _isHighContrast
                    ? [Colors.black, Colors.black87]
                    : [_AppStyle.bgColorStart, _AppStyle.bgColorEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SpinKitChasingDots(
            color: _AppStyle.secondaryAccent,
            size: 50.0,
          ),
        ),
      ),
    );
  } // Changed Loader

  Widget _buildErrorScreen(TextTheme textTheme) {
    return Scaffold(
      backgroundColor: _AppStyle.bgColorStart,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: _AppStyle.error,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                _strings.errorGeneric,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: _AppStyle.textColorMuted,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text(_strings.retryButton),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: _logout,
                child: Text(
                  'Logout' /* TODO: Localize */,
                  style: TextStyle(color: _AppStyle.secondaryAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- AppBar, Sidebar, Drawer ---
  SliverAppBar _buildSliverAppBar(
    bool isSmallScreen,
    TextTheme textTheme,
    LocaleProvider localeProvider,
    bool isWeb,
  ) {
    /* ... Same as previous good version ... */
    String appBarTitle = 'Dashboard' /* TODO: Localize */;
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      stretch: true,
      expandedHeight: isSmallScreen ? 160 : 200,
      /* Slightly smaller */ leading:
          !isWeb
              ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _toggleDrawer,
                tooltip: 'Menu' /*TODO:Localize*/,
              )
              : null,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: isWeb,
        titlePadding: EdgeInsets.only(
          left: isWeb ? 0 : (isSmallScreen ? 60 : 70),
          bottom: 16,
        ),
        title: Text(
          appBarTitle,
          style: textTheme.headlineSmall?.copyWith(
            color: _AppStyle.textColor,
            fontWeight: FontWeight.w600,
            /* Bolder */ letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1536514904658-89522b5f3195?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MTV8fGFic3RyYWN0JTIwZGFyayUyMGJsdWV8ZW58MHx8MHx8&w=1000&q=80',
              fit: BoxFit.cover,
              loadingBuilder:
                  (c, ch, p) => p == null ? ch : Container(color: _bgColorEnd),
              errorBuilder: (c, e, s) => Container(color: _bgColorEnd),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgColorStart.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment(0.0, 0.5),
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isHighContrast ? Icons.tonality : Icons.brightness_6_outlined,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() => _isHighContrast = !_isHighContrast);
            _savePreferences();
          },
          tooltip: _strings.highContrastTooltip,
        ),
        IconButton(
          icon: const Icon(Icons.translate_rounded, color: Colors.white),
          onPressed: () {
            context.read<LocaleProvider>().toggleLocale();
            HapticFeedback.lightImpact();
          },
          tooltip: _strings.languageToggleTooltip,
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  void _toggleDrawer() {
    if (!mounted) return;
    setState(() => _isMenuOpen = !_isMenuOpen);
    if (_isMenuOpen)
      _menuController.forward();
    else
      _menuController.reverse();
  }

  Widget _buildFixedSidebar(TextTheme textTheme) {
    /* ... Keep the Sidebar Implementation ... */
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: _bgColorStart.withOpacity(0.7),
        border: Border(
          right: BorderSide(color: _primaryAccent.withOpacity(0.3), width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(textTheme),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuItems(textTheme, isDrawer: false),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            /*TODO: Localize*/ textTheme: textTheme,
            onTap: _logout,
            color: _errorColor,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDrawer(TextTheme textTheme) {
    /* ... Keep the Drawer Implementation ... */
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder:
          (context, child) => Transform.translate(
            offset: Offset(_menuAnimation.value * 250, 0),
            child: Material(
              elevation: 16,
              shadowColor: Colors.black54,
              color: _bgColorStart,
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: _primaryAccent.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildDrawerHeader(textTheme),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: _buildMenuItems(textTheme, isDrawer: true),
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      /*TODO: Localize*/ textTheme: textTheme,
                      onTap: _handleDrawerLogout,
                      color: _errorColor,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDrawerHeader(TextTheme textTheme) {
    /* ... Keep the Drawer Header Implementation ... */
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryAccent.withOpacity(0.5),
            _primaryAccent.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: _secondaryAccent.withOpacity(0.9),
            backgroundImage:
                _userProfile?.profilePictureUrl != null &&
                        _userProfile!.profilePictureUrl!.isNotEmpty
                    ? NetworkImage(_userProfile!.profilePictureUrl!)
                    : null,
            child:
                (_userProfile?.profilePictureUrl == null ||
                        _userProfile!.profilePictureUrl!.isEmpty)
                    ? Text(
                      _userProfile?.username.isNotEmpty ?? false
                          ? _userProfile!.username[0].toUpperCase()
                          : '?',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Text(
            _userProfile?.username ?? 'User',
            style: textTheme.titleMedium?.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (_userProfile?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              _userProfile!.email,
              style: textTheme.bodySmall?.copyWith(color: _textColorMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(TextTheme textTheme, {required bool isDrawer}) {
    /* ... Keep Menu Items List ... */
    VoidCallback createTapHandler(String targetRoute, {String? selectionKey}) {
      return () {
        _pulseButton();
        if (selectionKey != null)
          setState(() => _selectedMenuItem = selectionKey);
        if (isDrawer) _toggleDrawer();
        _navigateTo(targetRoute);
      };
    }

    return [
      _buildMenuItem(
        icon: Icons.dashboard_rounded,
        title: 'Dashboard' /*TODO: Localize*/,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Dashboard',
        onTap: () {
          if (isDrawer) _toggleDrawer();
        },
      ),
      _buildMenuItem(
        icon: Icons.person_rounded,
        title: 'Profile' /*TODO: Localize*/,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Profile',
        onTap: createTapHandler('/profile', selectionKey: 'Profile'),
      ),
      _buildMenuItem(
        icon: Icons.assignment_ind_rounded,
        title: 'Applications' /*TODO: Localize*/,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Applications',
        onTap: createTapHandler('/visa_progress', selectionKey: 'Applications'),
      ),
      _buildMenuItem(
        icon: Icons.recommend_rounded,
        title: 'Recommendations' /*TODO: Localize*/,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Recommendations',
        onTap: createTapHandler(
          '/recommendations',
          selectionKey: 'Recommendations',
        ),
      ),
      _buildMenuItem(
        icon: Icons.settings_rounded,
        title: 'Settings' /*TODO: Localize*/,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Settings',
        onTap: createTapHandler('/settings', selectionKey: 'Settings'),
      ),
    ];
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required TextTheme textTheme,
    bool isSelected = false,
    Color? color,
  }) {
    /* ... Keep Menu Item Widget ... */
    Color activeColor = color ?? _secondaryAccent;
    Color itemColor = isSelected ? activeColor : _textColorMuted;
    FontWeight itemWeight = isSelected ? FontWeight.w600 : FontWeight.normal;
    return Material(
      color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: activeColor.withOpacity(0.2),
        highlightColor: activeColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(icon, color: itemColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: itemColor,
                    fontWeight: itemWeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDrawerLogout() {
    if (mounted) {
      _toggleDrawer();
      Future.delayed(const Duration(milliseconds: 250), _logout);
    } else {
      _logout();
    }
  }

  // --- Animated Card Wrapper ---
  Widget _buildAnimatedCard(int index, Widget child) {
    const totalDuration = 900;
    const delayPerItem = 110;
    final startDelay = (index * delayPerItem).clamp(0, totalDuration - 500);
    final endDelay = (startDelay + 500).clamp(startDelay, totalDuration);
    final interval = Interval(
      startDelay / totalDuration,
      endDelay / totalDuration,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, childWidget) {
        final animationValue = interval.transform(_staggerController.value);
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(
              0.0,
              _HomeScreenConstants.itemSlideOffset * (1.0 - animationValue),
            ),
            child: Transform.scale(
              scale: 0.98 + (animationValue * 0.02),
              child: childWidget,
            ),
          ),
        );
      },
      child: child,
    );
  }

  // --- Card Base ---
  Widget _buildBaseCard({
    required Widget child,
    Color? backgroundColor,
    EdgeInsets? padding,
  }) {
    return Card(
      elevation: 2.0, // Subtle elevation
      margin: EdgeInsets.zero, // Grid handles spacing
      color: backgroundColor ?? _AppStyle.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_AppStyle.cardRadius),
        side: BorderSide(
          color: _AppStyle.cardBorder,
          width: 0.5,
        ), // Subtle border
      ),
      clipBehavior: Clip.antiAlias, // Clip content to rounded corners
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: _AppStyle.cardHPadding,
              vertical: _AppStyle.vPadding,
            ),
        child: child,
      ),
    );
  }

  // --- Dashboard Card Widget Implementations ---

  Widget _buildWelcomeSection(bool isSmallScreen, TextTheme textTheme) {
    String welcomeMsg = "Welcome back, ";
    if (_strings.locale.languageCode == 'am') {
      welcomeMsg = "እንኳን ደህና መጡ, ";
    }
    return _buildBaseCard(
      backgroundColor: _AppStyle.cardBgSubtle, // Slightly different bg
      padding: const EdgeInsets.all(20), // Custom padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 28 : 32,
            backgroundColor: _AppStyle.secondaryAccent.withOpacity(0.1),
            backgroundImage:
                _userProfile?.profilePictureUrl != null &&
                        _userProfile!.profilePictureUrl!.isNotEmpty
                    ? NetworkImage(_userProfile!.profilePictureUrl!)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider /* Default Asset */,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$welcomeMsg${_userProfile?.username ?? 'User'}!',
                  style: textTheme.titleLarge?.copyWith(
                    color: _AppStyle.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your visa journey here.' /* TODO: Localize */,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _AppStyle.textColorMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: _AppStyle.secondaryAccent,
            ),
            tooltip: 'View Profile' /* TODO: Localize */,
            onPressed: () => _navigateTo('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisaProgressCard(bool isSmallScreen, TextTheme textTheme) {
    final int approvedCount =
        _applications.where((a) => a.status.toLowerCase() == 'approved').length;
    final int pendingCount =
        _applications
            .where(
              (a) => [
                'submitted',
                'processing',
                'pending',
              ].contains(a.status.toLowerCase()),
            )
            .length;
    final int rejectedCount =
        _applications.where((a) => a.status.toLowerCase() == 'rejected').length;
    final int total = _applications.length;
    double approvedPercent = total == 0 ? 0 : (approvedCount / total * 100);
    double pendingPercent = total == 0 ? 0 : (pendingCount / total * 100);
    double rejectedPercent = total == 0 ? 0 : (rejectedCount / total * 100);
    String title = "Application Status" /*TODO:Localize*/;
    String totalSuffix = "Total" /*TODO:Localize*/;
    if (_strings.locale.languageCode == 'am') {
      title = "የማመልከቻ ሁኔታ";
      totalSuffix = "ጠቅላላ";
    }
    int? touchedIndex;
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title ($total $totalSuffix)',
            style: textTheme.titleMedium?.copyWith(
              color: _AppStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          StatefulBuilder(
            builder: (context, setCardState) {
              return SizedBox(
                height: isSmallScreen ? 150 : 170,
                child:
                    total == 0
                        ? Center(
                          child: Text(
                            "No applications yet." /*TODO: Localize*/,
                            style: textTheme.bodyMedium?.copyWith(
                              color: _AppStyle.textColorMuted,
                            ),
                          ),
                        )
                        : Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (
                                      FlTouchEvent event,
                                      pieTouchResponse,
                                    ) {
                                      setCardState(() {
                                        touchedIndex =
                                            (event.isInterestedForInteractions &&
                                                    pieTouchResponse
                                                            ?.touchedSection !=
                                                        null)
                                                ? pieTouchResponse!
                                                    .touchedSection!
                                                    .touchedSectionIndex
                                                : -1;
                                      });
                                    },
                                  ),
                                  sectionsSpace: 4,
                                  centerSpaceRadius: isSmallScreen ? 30 : 40,
                                  startDegreeOffset: -90,
                                  sections: [
                                    if (approvedPercent > 0)
                                      PieChartSectionData(
                                        value: approvedPercent,
                                        color: _AppStyle.success,
                                        title: '',
                                        radius: touchedIndex == 0 ? 60 : 50,
                                        borderWidth: touchedIndex == 0 ? 2 : 0,
                                        borderColor: Colors.white.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    if (pendingPercent > 0)
                                      PieChartSectionData(
                                        value: pendingPercent,
                                        color: _AppStyle.pendingColor,
                                        title: '',
                                        radius: touchedIndex == 1 ? 60 : 50,
                                        borderWidth: touchedIndex == 1 ? 2 : 0,
                                        borderColor: Colors.white.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    if (rejectedPercent > 0)
                                      PieChartSectionData(
                                        value: rejectedPercent,
                                        color: _AppStyle.error,
                                        title: '',
                                        radius: touchedIndex == 2 ? 60 : 50,
                                        borderWidth: touchedIndex == 2 ? 2 : 0,
                                        borderColor: Colors.white.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                  ],
                                ),
                                swapAnimationDuration: const Duration(
                                  milliseconds: 300,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildDetailedLegend(
                                textTheme,
                                approvedCount,
                                pendingCount,
                                rejectedCount,
                              ),
                            ),
                          ],
                        ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: _buildActionButton(
              title: 'View Applications' /* TODO: Localize */,
              onTap: () => _navigateTo('/visa_progress'),
              isSmallScreen: isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedLegend(
    TextTheme textTheme,
    int approved,
    int pending,
    int rejected,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailedLegendItem(
          _AppStyle.success,
          'Approved' /*TODO:Localize*/,
          approved,
          textTheme,
        ),
        const SizedBox(height: 8),
        _detailedLegendItem(
          _AppStyle.pendingColor,
          'Pending' /*TODO:Localize*/,
          pending,
          textTheme,
        ),
        const SizedBox(height: 8),
        _detailedLegendItem(
          _AppStyle.error,
          'Rejected' /*TODO:Localize*/,
          rejected,
          textTheme,
        ),
      ],
    );
  }

  Widget _detailedLegendItem(
    Color color,
    String text,
    int count,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$text ($count)',
            style: textTheme.bodySmall?.copyWith(
              color: _AppStyle.textColorMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsPanel(bool isSmallScreen, TextTheme textTheme) {
    final List<VisaApplication> recentApps = _applications.take(3).toList();
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Applications' /* TODO: Localize */,
            style: textTheme.titleMedium?.copyWith(
              color: _AppStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _applications.isEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Center(
                  child: Text(
                    'No recent applications found.' /* TODO: Localize */,
                    style: textTheme.bodyMedium?.copyWith(
                      color: _AppStyle.textColorMuted,
                    ),
                  ),
                ),
              )
              : Column(
                children: List.generate(recentApps.length * 2 - 1, (index) {
                  if (index.isEven)
                    return _buildApplicationTile(
                      recentApps[index ~/ 2],
                      textTheme,
                    );
                  return Divider(
                    color: _AppStyle.cardBorder,
                    height: 12,
                    thickness: 0.5,
                  );
                }),
              ),
          const SizedBox(height: 10),
          if (_applications.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _navigateTo('/visa_progress'),
                child: Text(
                  'View All (${_applications.length})' /* TODO: Localize */,
                  style: textTheme.bodySmall?.copyWith(
                    color: _AppStyle.secondaryAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationTile(VisaApplication app, TextTheme textTheme) {
    final DateFormat formatter = DateFormat(
      'MMM dd, yyyy',
      _strings.locale.languageCode,
    );
    final String formattedDate = formatter.format(app.createdAt.toDate());
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      leading: CircleAvatar(
        backgroundColor: _AppStyle.primaryAccent.withOpacity(0.15),
        child: Icon(
          _getVisaTypeIcon(app.visaType),
          color: _AppStyle.primaryAccent,
          size: 24,
        ),
      ),
      title: Text(
        app.visaType,
        style: textTheme.titleSmall?.copyWith(
          color: _AppStyle.textColor,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${'Submitted:' /* TODO: Localize */} $formattedDate',
        style: textTheme.bodySmall?.copyWith(color: _AppStyle.textColorMuted),
      ),
      trailing: _buildStatusChip(app.status, textTheme),
      onTap: () {
        /* TODO: Navigate */
        _showErrorSnackbar('Navigate to details for ${app.id}');
      },
    );
  }

  IconData _getVisaTypeIcon(String visaType) {
    if (visaType.toLowerCase().contains('student') ||
        visaType.startsWith('F-') ||
        visaType.startsWith('M-'))
      return Icons.school_rounded;
    if (visaType.toLowerCase().contains('work') ||
        visaType.startsWith('H-') ||
        visaType.startsWith('L-'))
      return Icons.work_rounded;
    if (visaType.toLowerCase().contains('tourist') || visaType.startsWith('B'))
      return Icons.beach_access_rounded;
    if (visaType.toLowerCase().contains('family') || visaType.startsWith('K-'))
      return Icons.family_restroom_rounded;
    return Icons.article_rounded;
  }

  Widget _buildStatusChip(String status, TextTheme textTheme) {
    Color chipColor;
    Color textColor = Colors.white;
    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = _AppStyle.success.withOpacity(0.8);
        break;
      case 'rejected':
        chipColor = _AppStyle.error.withOpacity(0.8);
        break;
      case 'processing':
        chipColor = _AppStyle.secondaryAccent.withOpacity(0.8);
        textColor = Colors.black87;
        break;
      case 'submitted':
      case 'pending':
        chipColor = _AppStyle.pendingColor.withOpacity(0.8);
        break;
      default:
        chipColor = Colors.grey.shade600;
    }
    return Chip(
      label: Text(
        status /* TODO: Localize status */,
        style: textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildNotificationsCard(bool isSmallScreen, TextTheme textTheme) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications' /* TODO: Localize */,
                style: textTheme.titleMedium?.copyWith(
                  color: _AppStyle.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.mark_chat_read_outlined,
                  color: _AppStyle.textColorMuted,
                  size: 20,
                ),
                onPressed: _markAllNotificationsRead,
                tooltip: 'Mark all as read' /*TODO: Localize*/,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 190,
            child: StreamBuilder<QuerySnapshot>(
              stream: _notificationStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _applications.isEmpty)
                  return const Center(
                    child: SizedBox(
                      height: 50,
                      child: SpinKitThreeBounce(
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  );
                if (snapshot.hasError)
                  return Center(
                    child: Text(
                      'Could not load notifications.' /* TODO: Localize */,
                      style: textTheme.bodyMedium?.copyWith(
                        color: _AppStyle.error,
                      ),
                    ),
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'No new notifications.' /* TODO: Localize */,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _AppStyle.textColorMuted,
                        ),
                      ),
                    ),
                  );
                final notifications = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    bool isRead = data['isRead'] ?? false;
                    return _buildNotificationTile(
                      data,
                      doc.id,
                      isRead,
                      textTheme,
                    );
                  },
                  separatorBuilder:
                      (c, i) =>
                          Divider(color: _AppStyle.cardBorder, height: 0.5),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    Map<String, dynamic> data,
    String id,
    bool isRead,
    TextTheme textTheme,
  ) {
    final String message =
        data['message'] ?? 'Update available' /* TODO: Localize */;
    final String type = data['type'] ?? 'General';
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    IconData iconData = Icons.notifications_none_rounded;
    Color iconColor =
        isRead ? _AppStyle.textColorMuted : _AppStyle.primaryAccent;
    switch (type) {
      case 'ApplicationUpdate':
        iconData = Icons.article_rounded;
        break;
      case 'ApplicationSubmitted':
        iconData = Icons.check_circle_rounded;
        iconColor = isRead ? Colors.grey.shade600 : _AppStyle.success;
        break;
      case 'Welcome':
        iconData = Icons.celebration_rounded;
        iconColor = isRead ? Colors.grey.shade600 : _AppStyle.secondaryAccent;
        break;
      case 'ActionRequired':
        iconData = Icons.warning_amber_rounded;
        iconColor = isRead ? Colors.grey.shade600 : _AppStyle.error;
        break;
    }
    String timeAgo =
        timestamp != null ? _formatTimeAgo(timestamp.toDate()) : '';
    return Opacity(
      opacity: isRead ? 0.65 : 1.0,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 0,
        ),
        leading: Icon(iconData, color: iconColor, size: 26),
        title: Text(
          message,
          style: textTheme.bodyMedium?.copyWith(
            color: isRead ? _AppStyle.textColorMuted : _AppStyle.textColor,
            fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          timeAgo,
          style: textTheme.labelSmall?.copyWith(color: Colors.white54),
        ),
        trailing:
            isRead
                ? null
                : Container(
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                    color: _AppStyle.pendingColor,
                    shape: BoxShape.circle,
                  ),
                ),
        onTap: () {
          if (!isRead && _userProfile != null)
            _firebaseService.markNotificationAsRead(
              _userProfile!.uid,
              id,
            ); /* TODO: Add navigation based on type/ID */
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped: $message')));
        },
      ),
    );
  }

  Widget _buildAdditionalStatsCard(bool isSmallScreen, TextTheme textTheme) {
    String avgProcessingDays = "14d";
    String successRate = "93%";
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Insights' /* TODO: Localize */,
            style: textTheme.titleMedium?.copyWith(
              color: _AppStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(
            color: _AppStyle.cardBorder,
            height: 25,
            thickness: 0.5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.timelapse_rounded,
                'Avg. Processing' /* TODO: Localize */,
                avgProcessingDays,
                textTheme,
              ),
              _buildStatItem(
                Icons.verified_user_outlined,
                'Est. Success Rate' /* TODO: Localize */,
                successRate,
                textTheme,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Based on historical data.' /* TODO: Localize Disclaimer */,
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white54,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        Icon(icon, color: _AppStyle.primaryAccent, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            color: _AppStyle.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: _AppStyle.textColorMuted),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(bool isSmallScreen, TextTheme textTheme) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions' /* TODO: Localize */,
            style: textTheme.titleMedium?.copyWith(
              color: _AppStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isSmallScreen ? 2 : 3,
            childAspectRatio: isSmallScreen ? 2.8 : 3.0,
            /* Adjusted Ratio */ mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildActionTile(
                Icons.add_circle_outline_rounded,
                'New App' /* TODO: Localize */,
                () {
                  _showErrorSnackbar("Start New Application Tapped");
                },
                textTheme,
              ),
              _buildActionTile(
                Icons.description_rounded,
                'My Docs' /* TODO: Localize */,
                () {
                  _showErrorSnackbar("My Documents Tapped");
                },
                textTheme,
              ),
              _buildActionTile(
                Icons.calendar_month_rounded,
                'Book Meeting' /* TODO: Localize */,
                () {
                  _showErrorSnackbar("Book Consultation Tapped");
                },
                textTheme,
              ),
              _buildActionTile(
                Icons.headset_mic_rounded,
                'Support' /* TODO: Localize */,
                () {
                  _showErrorSnackbar("Contact Support Tapped");
                },
                textTheme,
              ),
              _buildActionTile(
                Icons.upload_file_rounded,
                'Upload' /* TODO: Localize */,
                () {
                  _showErrorSnackbar("Trigger Document Upload");
                },
                textTheme,
              ),
              _buildActionTile(
                Icons.account_circle_rounded,
                'My Profile' /* TODO: Localize */,
                () => _navigateTo('/profile'),
                textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String label,
    VoidCallback onTap,
    TextTheme textTheme,
  ) {
    return InkWell(
      onTap: () {
        _pulseButton();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      splashColor: _AppStyle.primaryAccent.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.08),
          /* Brighter tile */ border: Border.all(
            color: _AppStyle.cardBorder.withOpacity(0.7),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _AppStyle.secondaryAccent, size: 32),
            /* Larger Icon */ const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: _AppStyle.textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(bool isSmallScreen, TextTheme textTheme) {
    return Tilt(
      tiltConfig: const TiltConfig(angle: 6, reverse: true),
      lightConfig: const LightConfig(minIntensity: 0.1, maxIntensity: 0.5),
      shadowConfig: const ShadowConfig(offset: Offset(1, 1), spreadFactor: 2),
      child: _buildBaseCard(
        backgroundColor: _AppStyle.cardBg.withBlue(55),
        /* Slightly bluer tint */ child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: _AppStyle.secondaryAccent,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Personalized Suggestions' /* TODO: Localize */,
                  style: textTheme.titleMedium?.copyWith(
                    color: _AppStyle.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Options you might be interested in:' /* TODO: Localize */,
              style: textTheme.bodyMedium?.copyWith(
                color: _AppStyle.textColorMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecommendationItem(
              icon: Icons.work_history_rounded,
              title: 'Skilled Worker Visa - Express Entry',
              description:
                  'High demand based on your profile.' /* TODO: Dynamize/Localize */,
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            _buildRecommendationItem(
              icon: Icons.school_rounded,
              title: 'Master\'s Program (STEM)',
              description:
                  'Strong academic match found.' /* TODO: Dynamize/Localize */,
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButton(
                title: 'See Details' /* TODO: Localize */,
                onTap: () => _navigateTo('/recommendations'),
                isSmallScreen: isSmallScreen,
                backgroundColor: _AppStyle.secondaryAccent.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isSmallScreen,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _AppStyle.secondaryAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _AppStyle.secondaryAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: _AppStyle.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: _AppStyle.textColorMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isSmallScreen, TextTheme textTheme) {
    String phoneDisplay =
        _userProfile?.phone?.isNotEmpty ?? false
            ? _userProfile!.phone!
            : 'Not set' /* TODO: Localize */;
    return Tilt(
      tiltConfig: const TiltConfig(angle: 10, reverse: true),
      lightConfig: const LightConfig(minIntensity: 0.2, maxIntensity: 0.5),
      shadowConfig: const ShadowConfig(offset: Offset(1, 3), spreadFactor: 4),
      child: _buildBaseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 20,
                  color: _AppStyle.secondaryAccent,
                ),
                SizedBox(width: 8),
                Text(
                  'Profile Snapshot' /* TODO: Localize */,
                  style: textTheme.titleMedium?.copyWith(
                    color: _AppStyle.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(
              color: _AppStyle.cardBorder,
              height: 25,
              thickness: 0.5,
            ),
            _buildProfileRow(
              icon: Icons.badge_outlined,
              label: 'Username' /* TODO: Localize */,
              value: _userProfile?.username ?? '-',
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            _buildProfileRow(
              icon: Icons.alternate_email_rounded,
              label: 'Email' /* TODO: Localize */,
              value: _userProfile?.email ?? '-',
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            _buildProfileRow(
              icon: Icons.phone_iphone_rounded,
              label: 'Phone' /* TODO: Localize */,
              value: phoneDisplay,
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  title: 'Full Profile' /* TODO: Localize */,
                  onTap: () => _navigateTo('/profile'),
                  isSmallScreen: isSmallScreen,
                  backgroundColor: _AppStyle.primaryAccent.withOpacity(0.2),
                ),
                _buildActionButton(
                  title: 'Settings' /* TODO: Localize */,
                  onTap: () => _navigateTo('/settings'),
                  isSmallScreen: isSmallScreen,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: _AppStyle.secondaryAccent,
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: _AppStyle.textColorMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _AppStyle.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required VoidCallback onTap,
    required bool isSmallScreen,
    Color? backgroundColor,
  }) {
    return ScaleTransition(
      scale: _buttonPulseAnimation,
      child: ElevatedButton(
        onPressed: () {
          _pulseButton();
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ?? _AppStyle.primaryAccent.withOpacity(0.9),
          foregroundColor:
              backgroundColor == null ? Colors.black : _AppStyle.textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 12,
            horizontal: isSmallScreen ? 16 : 20,
          ),
          elevation: 3,
          shadowColor: _AppStyle.primaryAccent.withOpacity(0.3),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} // End of _HomeScreenState
