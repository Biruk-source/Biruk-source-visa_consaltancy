// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:firebase_auth/firebase_auth.dart'
    hide UserProfile; // Use hide to avoid conflict
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tilt/flutter_tilt.dart'; // *** IMPORT flutter_tilt ***
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // For ImageFilter
import 'package:intl/intl.dart';
import 'visa_application_detail_screen.dart';
import 'notifications_screen.dart';
import 'welcome_screen.dart';

// Import project files
import '../services/firebase_service.dart';
import '../providers/locale_provider.dart';
import 'app_strings.dart';
import '../models/user_profile.dart'; // Import UserProfile model
import '../models/visa_application.dart'; // Import VisaApplication model

// Screen Imports for Navigation
import 'profile.dart';
import 'setting.dart';
import 'login_screen.dart';
import 'visa_application.dart';
import 'visa_recommendations_screen.dart';

// --- Constants ---
class _AppStyle {
  // Renamed from _AppStyle to avoid confusion
  static const Color primaryAccent = Color(0xFF00ACC1);
  static const Color secondaryAccent = Color(0xFFFFCA28);
  static const Color bgColorStart = Color(0xFF0A191E);
  static const Color bgColorEnd = Color(0xFF00333A);
  static const Color cardBg = Color(0xFF1F3035);
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xFF9E9E9E);
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const double sectionSpacing = 24.0;
  static const Color pendingColor = Color(0xFF42A5F5);
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
  UserProfile? _userProfile; // Use the model
  List<VisaApplication> _applications = []; // Use the model
  Stream<QuerySnapshot>? _notificationStream;
  bool _isLoading = true;
  bool _isHighContrast = false; // Keep for accessibility
  bool _isMenuOpen = false;
  String _selectedMenuItem = 'Dashboard'; // TODO: Localize if needed

  // --- Animation Controllers ---
  late AnimationController _staggerController;
  late AnimationController _menuController;
  late AnimationController
  _buttonPulseController; // Renamed from _scaleController

  // --- Animations ---
  late Animation<double> _staggerAnimation; // Renamed from _fadeAnimation
  late Animation<double> _menuAnimation;
  late Animation<double> _buttonPulseAnimation; // Renamed from _scaleAnimation

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Strings initialized in didChangeDependencies
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
  }

  void _setupAnimations() {
    // Use durations consistent with original file if preferred
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    ); // For card stagger
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 350),
    );

    // Stagger animation for cards (similar to original fade)
    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic),
    );
    _menuAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeInOutCubic),
    );
    _buttonPulseAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );

    // Don't start stagger controller until data is loaded
  }

  Future<void> _initializeData() async {
    await _loadPreferences();
    await _fetchData();
  }

  Future<void> _loadPreferences() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (mounted)
        setState(() => _isHighContrast = p.getBool('high_contrast') ?? false);
    } catch (e) {
      if (mounted) _showErrorSnackbar(_strings.errorCouldNotSavePrefs);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('high_contrast', _isHighContrast);
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
              .catchError((_) => <VisaApplication>[]),
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

  @override
  void dispose() {
    _staggerController.dispose();
    _menuController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    /* ... Keep previous logout logic ... */
    String confirmTitle = _strings.logoutConfirmTitle;
    String confirmContent = _strings.logoutConfirmContent;
    String cancelButton = _strings.generalCancel;
    String logoutButton = _strings.generalLogout;
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
      case '/notifications':
        targetScreen = const NotificationsScreen();

        break;
      case '/welcome':
        targetScreen = const WelcomeScreen();

        break;
      default:
        debugPrint("Unknown route: $routeName");
    }
    if (targetScreen != null && mounted) {
      final Widget screenToPush = targetScreen;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screenToPush),
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
    /* ... Keep implementation ... */
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
    return langCode == 'am' ? 'አሁን' : 'Just now';
  }

  Future<void> _markAllNotificationsRead() async {
    if (_userProfile != null) {
      try {
        await _firebaseService.markAllNotificationsAsRead(_userProfile!.uid);
        if (mounted)
          _showErrorSnackbar(
            'Notifications marked as read' /* TODO: Localize */,
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
    ); // Use defined colors

    if (_isLoading) return _buildLoadingScreen(textTheme);
    if (_userProfile == null) return _buildErrorScreen(textTheme);

    return Scaffold(
      backgroundColor: _AppStyle.bgColorStart, // Base background
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
                          // ** Using Original Structure **
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              // Stagger the column content
                              child: AnimatedBuilder(
                                animation: _staggerController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity:
                                        _staggerAnimation
                                            .value, // Use the stagger animation directly
                                    child: Transform.translate(
                                      offset: Offset(
                                        0.0,
                                        50.0 * (1.0 - _staggerAnimation.value),
                                      ), // Slide up effect
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  // Original Column layout
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildWelcomeSection(
                                      isSmallScreen,
                                      textTheme,
                                    ),
                                    const SizedBox(
                                      height: _AppStyle.sectionSpacing,
                                    ),
                                    _buildVisaProgressCard(
                                      isSmallScreen,
                                      textTheme,
                                    ),
                                    const SizedBox(
                                      height: _AppStyle.sectionSpacing,
                                    ),
                                    _buildApplicationsPanel(
                                      isSmallScreen,
                                      textTheme,
                                    ),
                                    const SizedBox(
                                      height: _AppStyle.sectionSpacing,
                                    ),
                                    _buildNotificationsCard(
                                      isSmallScreen,
                                      textTheme,
                                    ),
                                    const SizedBox(
                                      height: _AppStyle.sectionSpacing,
                                    ),
                                    _buildRecommendationsCard(
                                      isSmallScreen,
                                      textTheme,
                                    ),
                                    const SizedBox(
                                      height: _AppStyle.sectionSpacing,
                                    ),
                                    _buildProfileCard(isSmallScreen, textTheme),
                                    const SizedBox(
                                      height: _AppStyle.sectionSpacing,
                                    ), // Bottom spacing
                                  ],
                                ),
                              ),
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/recommendations'),
        label: Text('New Application' /* TODO: Localize */),
        icon: const Icon(Icons.add),
        backgroundColor: _AppStyle.secondaryAccent,
        foregroundColor: Colors.black,
      ),
    );
  }

  // --- Loading & Error Screens ---
  Widget _buildLoadingScreen(TextTheme textTheme) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitFadingCube(color: _AppStyle.secondaryAccent, size: 50.0),
              SizedBox(height: 20),
              Text(
                _strings.loading,
                style: textTheme.bodyMedium?.copyWith(
                  color: _AppStyle.textColorMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  _strings.generalLogout,
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
    String appBarTitle = _strings.homeDashboardTitle;
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      stretch: true,
      expandedHeight: isSmallScreen ? 160 : 200,
      leading:
          !isWeb
              ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _toggleDrawer,
                tooltip: _strings.tooltipMenu,
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
            letterSpacing: 0.5,
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
                  (c, ch, p) =>
                      p == null ? ch : Container(color: _AppStyle.bgColorEnd),
              errorBuilder: (c, e, s) => Container(color: _AppStyle.bgColorEnd),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _AppStyle.bgColorStart.withOpacity(0.8),
                    Colors.transparent,
                  ],
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
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: _AppStyle.bgColorStart.withOpacity(0.7),
        border: Border(
          right: BorderSide(
            color: _AppStyle.primaryAccent.withOpacity(0.3),
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
              children: _buildMenuItems(textTheme, isDrawer: false),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: _strings.sidebarLogout,
            textTheme: textTheme,
            onTap: _logout,
            color: _AppStyle.error,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDrawer(TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder:
          (context, child) => Transform.translate(
            offset: Offset(_menuAnimation.value * 250, 0),
            child: Material(
              elevation: 16,
              shadowColor: Colors.black54,
              color: _AppStyle.bgColorStart,
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: _AppStyle.primaryAccent.withOpacity(0.5),
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
                      title: _strings.sidebarLogout,
                      textTheme: textTheme,
                      onTap: _handleDrawerLogout,
                      color: _AppStyle.error,
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
    /* ... Keep implementation ... */
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _AppStyle.primaryAccent.withOpacity(0.5),
            _AppStyle.primaryAccent.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: _AppStyle.secondaryAccent.withOpacity(0.9),
            backgroundImage:
                _userProfile?.profilePictureUrl != null &&
                        _userProfile!.profilePictureUrl!.isNotEmpty
                    ? NetworkImage(_userProfile!.profilePictureUrl!)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
            /* Default Asset */ child:
                (_userProfile?.profilePictureUrl == null ||
                        _userProfile!.profilePictureUrl!.isEmpty)
                    ? Text(
                      _userProfile?.username.isNotEmpty ?? false
                          ? _userProfile!.username[0].toUpperCase()
                          : 'U',
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
              color: _AppStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (_userProfile?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              _userProfile!.email,
              style: textTheme.bodySmall?.copyWith(
                color: _AppStyle.textColorMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(TextTheme textTheme, {required bool isDrawer}) {
    /* ... Keep implementation ... */
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
        title: _strings.sidebarDashboard,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Dashboard',
        onTap: () {
          if (isDrawer) _toggleDrawer();
        },
      ),
      _buildMenuItem(
        icon: Icons.person_rounded,
        title: _strings.sidebarProfile,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Profile',
        onTap: createTapHandler('/profile', selectionKey: 'Profile'),
      ),
      _buildMenuItem(
        icon: Icons.assignment_ind_rounded,
        title: 'Applications' /*TODO:Localize*/,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Applications',
        onTap: createTapHandler('/visa_progress', selectionKey: 'Applications'),
      ),
      _buildMenuItem(
        icon: Icons.recommend_rounded,
        title: 'Recommendations' /*TODO:Localize*/,
        textTheme: textTheme,
        isSelected: _selectedMenuItem == 'Recommendations',
        onTap: createTapHandler(
          '/recommendations',
          selectionKey: 'Recommendations',
        ),
      ),
      _buildMenuItem(
        icon: Icons.settings_rounded,
        title: _strings.sidebarSettings,
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
    /* ... Keep implementation ... */
    Color activeColor = color ?? _AppStyle.secondaryAccent;
    Color itemColor = isSelected ? activeColor : _AppStyle.textColorMuted;
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
    // Use the same animation logic as original file but reference constants correctly
    const totalDuration = 1000; // Adjusted duration for smoother feel
    const delayPerItem = 120; // Adjusted delay
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
              30.0 * (1.0 - animationValue),
            ), // Use 30.0 or _HomeScreenConstants.itemSlideOffset
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }

  // --- Base Card Style (Using Original File's Approach) ---
  Widget _buildGlassCard({
    required Widget child,
    Color? backgroundColor,
    double blurSigma = 5.0,
    BorderRadius? borderRadius,
  }) {
    // This is similar to the original style but slightly refined
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (_isHighContrast
                    ? Colors.black.withOpacity(0.8)
                    : Colors.grey[900]!.withOpacity(0.7)),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: Border.all(
              color: _AppStyle.primaryAccent.withOpacity(0.2),
              width: 1,
            ), // Subtle border
            boxShadow: [
              // Subtle shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // --- Dashboard Card Widgets (Implementations based on ORIGINAL structure) ---

  Widget _buildWelcomeSection(bool isSmallScreen, TextTheme textTheme) {
    String welcomeMsg =
        _strings.locale.languageCode == 'am' ? "እንኳን ደህና መጡ, " : "Welcome, ";
    return GestureDetector(
      onTap: () => _navigateTo('/profile'), // Navigate to profile
      child: Tilt(
        // ** FIX flutter_tilt parameters **
        tiltConfig: const TiltConfig(angle: 10), // Removed invalid intensity
        lightConfig: const LightConfig(
          color: Colors.white,
          minIntensity: 0.3,
          maxIntensity: 0.6,
        ), // Use min/max
        shadowConfig: const ShadowConfig(
          color: Colors.black54,
          offsetInitial: Offset(2, 2),
          spreadFactor: 5.0,
        ), // Use offset/spread
        child: _buildGlassCard(
          // Use the base card style
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$welcomeMsg${_userProfile?.username ?? 'User'}!',
                style: textTheme.headlineSmall?.copyWith(
                  color: _AppStyle.textColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _strings.homeWelcomeSubtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: _AppStyle.textColorMuted,
                ),
              ),
            ],
          ),
        ),
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
    int? touchedIndex;
    return GestureDetector(
      onTap: () => _navigateTo('/visa_progress'),
      child: Tilt(
        // ** FIX flutter_tilt parameters **
        tiltConfig: const TiltConfig(angle: 10),
        lightConfig: const LightConfig(minIntensity: 0.2, maxIntensity: 0.5),
        shadowConfig: const ShadowConfig(
          offsetInitial: Offset(0, 2),
          spreadFactor: 3,
        ),
        child: _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _strings.homeVisaProgressTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: _AppStyle.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: isSmallScreen ? 150 : 180, // Adjusted height
                child:
                    total == 0
                        ? _buildEmptyStatePlaceholder(
                          icon: Icons.pie_chart_outline_rounded,
                          message: _strings.homeAppsChartNoApps,
                          textTheme: textTheme,
                        )
                        : StatefulBuilder(
                          // Manage touchedIndex locally
                          builder:
                              (context, setCardState) => PieChart(
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
                                  sectionsSpace: 2,
                                  centerSpaceRadius: isSmallScreen ? 30 : 40,
                                  sections: [
                                    if (approvedPercent > 0)
                                      PieChartSectionData(
                                        value: approvedPercent,
                                        color: _AppStyle.success,
                                        title:
                                            '${approvedPercent.toStringAsFixed(0)}%',
                                        radius:
                                            touchedIndex == 0
                                                ? (isSmallScreen ? 55 : 65)
                                                : (isSmallScreen ? 50 : 60),
                                        titleStyle: textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                    if (pendingPercent > 0)
                                      PieChartSectionData(
                                        value: pendingPercent,
                                        color: _AppStyle.pendingColor,
                                        title:
                                            '${pendingPercent.toStringAsFixed(0)}%',
                                        radius:
                                            touchedIndex == 1
                                                ? (isSmallScreen ? 55 : 65)
                                                : (isSmallScreen ? 50 : 60),
                                        titleStyle: textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                    if (rejectedPercent > 0)
                                      PieChartSectionData(
                                        value: rejectedPercent,
                                        color: _AppStyle.error,
                                        title:
                                            '${rejectedPercent.toStringAsFixed(0)}%',
                                        radius:
                                            touchedIndex == 2
                                                ? (isSmallScreen ? 55 : 65)
                                                : (isSmallScreen ? 50 : 60),
                                        titleStyle: textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                  ],
                                ),
                                swapAnimationDuration: const Duration(
                                  milliseconds: 250,
                                ),
                              ),
                        ),
              ),
              const SizedBox(height: 16),
              _buildLegend(
                textTheme,
                approvedCount,
                pendingCount,
                rejectedCount,
              ), // Use detailed legend
              const SizedBox(height: 16),
              Row(
                // Keep original action buttons layout
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    title: _strings.homeActionViewDetails,
                    onTap: () => _navigateTo('/visa_progress'),
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildActionButton(
                    title: _strings.homeActionUpdateStatus,
                    onTap:
                        () => _showErrorSnackbar(
                          'Update Status: Not Implemented',
                        ),
                    isSmallScreen: isSmallScreen,
                    backgroundColor: _AppStyle.secondaryAccent.withOpacity(0.8),
                  ), // Example action
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(
    TextTheme textTheme,
    int approved,
    int pending,
    int rejected,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween, // Distribute space, allow wrapping
      spacing: 12.0, // Horizontal space between buttons
      runSpacing: 8.0,
      children: [
        _detailedLegendItem(
          _AppStyle.success,
          _strings.homeAppsChartLegendApproved,
          approved,
          textTheme,
        ),
        _detailedLegendItem(
          _AppStyle.pendingColor,
          _strings.homeAppsChartLegendPending,
          pending,
          textTheme,
        ),
        _detailedLegendItem(
          _AppStyle.error,
          _strings.homeAppsChartLegendRejected,
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
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$text ($count)',
          style: textTheme.bodySmall?.copyWith(color: _AppStyle.textColorMuted),
        ),
      ],
    );
  }

  Widget _buildApplicationsPanel(bool isSmallScreen, TextTheme textTheme) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _strings.homeRecentApplicationsTitle,
            style: textTheme.titleLarge?.copyWith(
              color: _AppStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _applications.isEmpty
              ? _buildEmptyStatePlaceholder(
                icon: Icons.folder_off_outlined,
                message: _strings.homeAppsChartNoApps,
                textTheme: textTheme,
                verticalPadding: 30,
              )
              : Column(
                // Use column instead of ListView for fixed height
                children:
                    _applications
                        .map((app) => _buildApplicationTile(app, textTheme))
                        .toList(),
              ),
          if (_applications.length > 5) // Check original limit
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _navigateTo('/visa_progress'),
                child: Text(
                  '${_strings.homeActionViewAll} (${_applications.length})',
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
        '${_strings.homeStatusSubmitted}: $formattedDate',
        style: textTheme.bodySmall?.copyWith(color: _AppStyle.textColorMuted),
      ),
      trailing: _buildStatusChip(app.status, textTheme),
      onTap: () {
        /* TODO: Navigate to app details */
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisaApplicationDetailScreen(applicationId: app.id),
          ),
        );
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
    Color textColor = _AppStyle.textColor;
    String statusText = status;
    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = _AppStyle.success.withOpacity(0.2);
        textColor = _AppStyle.success;
        statusText = _strings.homeStatusApproved;
        break;
      case 'rejected':
        chipColor = _AppStyle.error.withOpacity(0.2);
        textColor = _AppStyle.error;
        statusText = _strings.homeStatusRejected;
        break;
      case 'processing':
        chipColor = _AppStyle.secondaryAccent.withOpacity(0.2);
        textColor = _AppStyle.secondaryAccent;
        statusText = _strings.homeStatusProcessing;
        break;
      case 'submitted':
      case 'pending':
        chipColor = _AppStyle.pendingColor.withOpacity(0.2);
        textColor = _AppStyle.pendingColor;
        statusText = _strings.homeStatusPending;
        break;
      default:
        chipColor = Colors.grey.shade800;
        textColor = _AppStyle.textColorMuted;
        statusText = _strings.homeStatusUnknown;
    }
    return Chip(
      side: BorderSide.none,
      label: Text(
        statusText,
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
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _strings.homeNotificationsTitle,
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
                tooltip: _strings.tooltipMarkAllRead,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 180,
            /* Fixed height */ child: StreamBuilder<QuerySnapshot>(
              stream: _notificationStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
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
                  return _buildEmptyStatePlaceholder(
                    icon: Icons.error_outline,
                    message: _strings.homeNotificationsError,
                    textTheme: textTheme,
                    isError: true,
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return _buildEmptyStatePlaceholder(
                    icon: Icons.notifications_off_outlined,
                    message: _strings.homeNotificationsNone,
                    textTheme: textTheme,
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
          const SizedBox(height: 10),
          Center(
            child: _buildActionButton(
              title: _strings.homeActionViewAll,
              onTap: () => _navigateTo('/notifications'),
              isSmallScreen: isSmallScreen,
            ),
          ), // View All Button
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
    /* ... Keep detailed implementation from previous answer ... */
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
                    color: Colors.blueAccent.shade100,
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

  Widget _buildRecommendationsCard(bool isSmallScreen, TextTheme textTheme) {
    // Restoring original style logic but using _buildGlassCard and localized strings
    return Tilt(
      tiltConfig: const TiltConfig(angle: 10), // Corrected Tilt Params
      lightConfig: const LightConfig(minIntensity: 0.2, maxIntensity: 0.5),
      shadowConfig: const ShadowConfig(
        offsetInitial: Offset(1, 3),
        spreadFactor: 4.0,
      ),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.homeRecommendationsTitle,
              style: textTheme.titleMedium?.copyWith(
                color: _AppStyle.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _strings.homeRecommendationsSubtext,
              style: textTheme.bodyMedium?.copyWith(
                color: _AppStyle.textColorMuted,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecommendationItem(
              title: 'Skilled Worker Visa',
              /* TODO: Localize/Dynamize */ description:
                  'Ideal for professionals with job offers.',
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            _buildRecommendationItem(
              title: 'Student Visa',
              /* TODO: Localize/Dynamize */ description:
                  'Perfect for pursuing higher education.',
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButton(
                title: _strings.homeActionExploreMore,
                onTap: () => _navigateTo('/recommendations'),
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem({
    required String title,
    required String description,
    required bool isSmallScreen,
    required TextTheme textTheme,
  }) {
    // Restore original recommendation item style
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.star, color: _AppStyle.secondaryAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: _AppStyle.textColor,
                    fontWeight: FontWeight.bold,
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
            : _strings.homeProfileValueNotSet;
    return Tilt(
      tiltConfig: const TiltConfig(angle: 10), // Corrected Tilt Params
      lightConfig: const LightConfig(minIntensity: 0.2, maxIntensity: 0.5),
      shadowConfig: const ShadowConfig(
        offsetInitial: Offset(1, 3),
        spreadFactor: 4.0,
      ),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.homeProfileOverviewTitle,
              style: textTheme.titleMedium?.copyWith(
                color: _AppStyle.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileRow(
              icon: Icons.person,
              label: _strings.homeProfileLabelUsername,
              value: _userProfile?.username ?? 'N/A',
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            const SizedBox(height: 8),
            _buildProfileRow(
              icon: Icons.email,
              label: _strings.homeProfileLabelEmail,
              value: _userProfile?.email ?? 'N/A',
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            const SizedBox(height: 8),
            _buildProfileRow(
              icon: Icons.phone,
              label: _strings.homeProfileLabelPhone,
              value: phoneDisplay,
              isSmallScreen: isSmallScreen,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment:
                  WrapAlignment
                      .spaceBetween, // Distribute space, allow wrapping
              spacing: 12.0, // Horizontal space between buttons
              runSpacing: 8.0,
              children: [
                _buildActionButton(
                  title: _strings.homeActionEditProfile,
                  onTap: () => _navigateTo('/profile'),
                  isSmallScreen: isSmallScreen,
                ),
                _buildActionButton(
                  title: _strings.homeActionViewDetails,
                  onTap: () => _navigateTo('/welcome'),
                  isSmallScreen: isSmallScreen,
                ),
                // Navigate to full profile
                _buildActionButton(
                  title: _strings.homeActionSecurity,
                  onTap: () => _navigateTo("/setting"),
                  isSmallScreen: isSmallScreen,
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
    // Restore original profile row style
    return Row(
      children: [
        Icon(
          icon,
          color: _AppStyle.secondaryAccent,
          size: isSmallScreen ? 20 : 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: textTheme.bodyLarge?.copyWith(color: _AppStyle.textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- Action Button Helper (Restored original style approach) ---
  Widget _buildActionButton({
    required String title,
    required VoidCallback onTap,
    required bool isSmallScreen,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets? padding,
    IconData? icon,
  }) {
    return ScaleTransition(
      scale: _buttonPulseAnimation,
      child: ElevatedButton.icon(
        icon:
            icon != null
                ? Icon(icon, size: isSmallScreen ? 14 : 16)
                : const SizedBox.shrink(),
        label: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          _pulseButton();
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ?? _AppStyle.primaryAccent, // Use defined color
          foregroundColor:
              foregroundColor ??
              (backgroundColor == null
                  ? Colors.black
                  : _AppStyle.textColor), // Use defined color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Original rounding
          padding:
              padding ??
              EdgeInsets.symmetric(
                vertical: isSmallScreen ? 10 : 12,
                horizontal: isSmallScreen ? 16 : 20,
              ), // Original padding
          elevation: 5, // Original elevation
          shadowColor: _AppStyle.primaryAccent.withOpacity(
            0.5,
          ), // Original shadow
        ),
      ),
    );
  }

  // --- Helper for empty states in cards ---
  Widget _buildEmptyStatePlaceholder({
    required IconData icon,
    required String message,
    required TextTheme textTheme,
    double verticalPadding = 20.0,
    bool isError = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color:
                  isError
                      ? _AppStyle.error.withOpacity(0.6)
                      : _AppStyle.textColorMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: _AppStyle.textColorMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} // End of _HomeScreenState
