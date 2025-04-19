// lib/screens/setting.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserProfile;
import 'package:url_launcher/url_launcher.dart';

// Import project files
import '../services/firebase_service.dart';
import '../models/user_profile.dart';
import '../providers/locale_provider.dart';
import 'app_strings.dart'; // Import AppStrings
import 'login_screen.dart';
import 'profile.dart'; // Ensure this screen exists for editing profile

// --- Local Styles ---
class _SettingsStyle {
  static const Color primaryAccent = Color(0xFF26C6DA);
  static const Color secondaryAccent = Color(0xFFFFD54F);
  static const Color bgColorStart = Color(0xFF0A191E);
  static const Color bgColorEnd = Color(0xFF00333A);
  static const Color cardBg = Color(0xFF1F3035);
  static const Color listTileColor = Color(0xFF1A2A2F);
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xFF9E9E9E);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color warningColor = Color(0xFFFFCA28);
  static const Color iconColor = Color(0xFFB0BEC5);
}

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late AppStrings _strings; // Will hold localized strings
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDeleting = false;
  bool _isLoggingOut = false;

  // State for preferences
  bool _notificationsEnabled = true; // Will be updated from _userProfile

  @override
  void initState() {
    super.initState();
    // Initialize strings AFTER the first frame in didChangeDependencies
    _fetchUserProfile();
  }

  // --- ADDED: Helper to check if strings are initialized ---
  bool _stringsInitialized = false;
  void _ensureStringsInitialized() {
    if (!_stringsInitialized && mounted) {
      final localeProvider = Provider.of<LocaleProvider>(
        context,
        listen: false,
      );
      _strings = AppLocalizations.getStrings(localeProvider.locale);
      _stringsInitialized = true;
    }
  }
  // --- END ADDED HELPER ---

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize or update strings when dependencies change (like locale)
    final localeProvider = Provider.of<LocaleProvider>(
      context,
    ); // Listen for changes
    _strings = AppLocalizations.getStrings(localeProvider.locale);
    _stringsInitialized = true; // Mark as initialized
    // No need to call setState here unless something else depends on locale directly in build apart from strings
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _ensureStringsInitialized(); // Ensure strings are ready for error messages
      final user = _firebaseService.getCurrentUser();
      if (user == null) {
        throw Exception(
          _strings.loginErrorGenericLoginFailed,
        ); // Use localized error
      }
      _userProfile = await _firebaseService.getUserProfile(user.uid);
      if (_userProfile == null && mounted) {
        _errorMessage = _strings.settingsErrorProfileNotFound;
      } else if (mounted) {
        setState(() {
          _notificationsEnabled = _userProfile?.notificationsEnabled ?? true;
          // Load other preferences here...
        });
      }
    } catch (e) {
      debugPrint("Error fetching user profile for settings: $e");
      if (mounted) {
        _ensureStringsInitialized(); // Ensure strings are available for the error message
        _errorMessage =
            e is Exception &&
                    e.toString().contains(_strings.loginErrorGenericLoginFailed)
                ? e.toString().replaceFirst("Exception: ", "")
                : _strings.errorGeneric;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Action Handlers ---

  Future<void> _handleLogout() async {
    _ensureStringsInitialized();
    if (!mounted || _isLoggingOut) return;

    final bool? confirm = await _showConfirmationDialog(
      title: _strings.logoutConfirmTitle,
      content: _strings.logoutConfirmContent,
      confirmText: _strings.generalLogout,
      confirmColor: _SettingsStyle.errorColor,
    );

    if (confirm == true) {
      setState(() => _isLoggingOut = true);
      try {
        await _firebaseService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint("Logout error: $e");
        if (mounted) {
          _showSnackbar(_strings.errorActionFailed, isError: true);
        }
      } finally {
        Future.delayed(Duration.zero, () {
          if (mounted) setState(() => _isLoggingOut = false);
        });
      }
    }
  }

  Future<void> _handleChangePassword() async {
    _ensureStringsInitialized();
    if (_userProfile?.email == null || _userProfile!.email.isEmpty) {
      _showSnackbar(_strings.settingsErrorCannotSendReset, isError: true);
      return;
    }

    try {
      await _firebaseService.sendPasswordResetEmail(_userProfile!.email);
      _showSnackbar(
        "${_strings.loginSuccessPasswordResetSent} ${_userProfile!.email}.",
        isError: false,
      ); // Combined message
    } on FirebaseAuthException catch (e) {
      debugPrint("Password Reset Error: ${e.code}");
      _showSnackbar(
        "${_strings.settingsErrorFailedToSendReset}: ${e.message ?? ''}",
        isError: true,
      );
    } catch (e) {
      debugPrint("Password Reset Error: $e");
      _showSnackbar(_strings.errorActionFailed, isError: true);
    }
  }

  Future<void> _handleDeleteAccount() async {
    _ensureStringsInitialized();
    if (!mounted || _isDeleting || _userProfile == null) return;

    // --- **VERY IMPORTANT WARNING DIALOG** ---
    final bool? confirm1 = await _showConfirmationDialog(
      title: _strings.settingsDeleteConfirmTitle,
      content: _strings.settingsDeleteConfirmContent,
      confirmText: _strings.settingsDeleteConfirmAction,
      confirmColor: Colors.red.shade900,
      cancelText: _strings.generalCancel,
    );

    if (confirm1 != true) return;

    // --- **SECOND CONFIRMATION ---
    // Consider adding an input field here in a real app
    final bool? confirm2 = await _showConfirmationDialog(
      title: _strings.settingsDeleteConfirmTitle2,
      content:
          _strings.settingsDeleteConfirmInputPrompt, // Adapt prompt if needed
      confirmText: _strings.settingsDeleteConfirmActionFinal,
      confirmColor: Colors.red.shade900,
      cancelText: _strings.generalCancel,
    );

    if (confirm2 != true) return;

    // --- Proceed with Deletion Attempt ---
    setState(() => _isDeleting = true);
    try {
      // !!! Implement Re-authentication !!!
      // This is a placeholder - real implementation needed
      _showSnackbar(_strings.settingsErrorReauthRequired, isError: true);
      // Example: bool reauthenticated = await showReauthDialog(); // Your re-auth logic
      // if (!reauthenticated) {
      //   setState(() => _isDeleting = false);
      //   return;
      // }
      // Simulate delay if not implementing re-auth yet for testing
      await Future.delayed(const Duration(seconds: 2));
      // --- END Placeholder ---

      // --- Call Firebase delete AFTER successful re-auth ---
      // await _firebaseService.deleteUserAccount(); // UNCOMMENT AFTER RE-AUTH

      _showSnackbar(
        _strings.settingsSuccessAccountDeleted,
        isError: false,
      ); // Move this inside try AFTER successful delete
      if (mounted) {
        // Navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Delete Account Error (Auth): ${e.code} - ${e.message}");
      String errorMessage = _strings.errorActionFailed;
      if (e.code == 'requires-recent-login') {
        errorMessage = _strings.settingsErrorRequiresRecentLogin;
      } else {
        errorMessage =
            "${_strings.settingsErrorDeleteFailed}: ${e.message ?? ''}";
      }
      if (mounted) _showSnackbar(errorMessage, isError: true);
    } catch (e) {
      debugPrint("Delete Account Error (General): $e");
      if (mounted) _showSnackbar(_strings.errorActionFailed, isError: true);
    } finally {
      Future.delayed(Duration.zero, () {
        if (mounted) setState(() => _isDeleting = false);
      });
    }
  }

  Future<void> _handleNotificationToggle(bool newValue) async {
    _ensureStringsInitialized();
    if (_userProfile == null) return;

    setState(() {
      _notificationsEnabled = newValue;
    });

    try {
      await _firebaseService.updateUserProfile(_userProfile!.uid, {
        'notificationsEnabled': newValue,
      });
      _showSnackbar(_strings.settingsSuccessPreferenceSaved, isError: false);
    } catch (e) {
      debugPrint("Error updating notification preference: $e");
      _showSnackbar(_strings.errorCouldNotSavePrefs, isError: true);
      if (mounted) {
        setState(() {
          _notificationsEnabled = !newValue; // Revert UI
        });
      }
    }
  }

  Future<void> _launchUrlHelper(String urlString) async {
    _ensureStringsInitialized();
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showSnackbar(_strings.errorCouldNotLaunchUrl, isError: true);
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    String? cancelText,
  }) {
    _ensureStringsInitialized();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _SettingsStyle.listTileColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: _SettingsStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: GoogleFonts.poppins(color: _SettingsStyle.textColorMuted),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                cancelText ?? _strings.generalCancel,
                style: GoogleFonts.poppins(
                  color: _SettingsStyle.textColorMuted,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: confirmColor),
              child: Text(
                confirmText,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? Colors.white : Colors.black),
        ),
        backgroundColor:
            isError
                ? _SettingsStyle.errorColor
                : _SettingsStyle.successColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Ensure strings are initialized before building UI that depends on them
    _ensureStringsInitialized();

    final textTheme = _strings.textTheme.apply(
      bodyColor: _SettingsStyle.textColor,
      displayColor: _SettingsStyle.textColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _stringsInitialized
              ? _strings.sidebarSettings
              : "Settings", // Use fallback if needed
          style: textTheme.titleLarge,
        ),
        backgroundColor: _SettingsStyle.bgColorStart,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.5),
        iconTheme: IconThemeData(color: _SettingsStyle.textColor),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_SettingsStyle.bgColorStart, _SettingsStyle.bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildContent(textTheme),
      ),
    );
  }

  // --- Content Building Logic ---
  Widget _buildContent(TextTheme textTheme) {
    if (_isLoading) {
      return Center(
        child: SpinKitFadingCube(
          color: _SettingsStyle.secondaryAccent,
          size: 40.0,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(textTheme, _errorMessage!);
    }

    if (_userProfile == null) {
      return _buildErrorState(textTheme, _strings.settingsErrorProfileNotFound);
    }

    // Build the settings list
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      children: [
        _buildSectionHeader(textTheme, _strings.settingsProfileSection),
        _buildInfoTile(
          icon: Icons.person_outline,
          title: _strings.homeProfileLabelUsername,
          subtitle: _userProfile!.username,
        ),
        _buildInfoTile(
          icon: Icons.email_outlined,
          title: _strings.homeProfileLabelEmail,
          subtitle: _userProfile!.email,
        ),
        _buildNavigationTile(
          icon: Icons.edit_outlined,
          title: _strings.settingsEditProfile,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),

        _buildSectionDivider(),

        _buildSectionHeader(textTheme, _strings.settingsPreferencesSection),
        _buildSwitchTile(
          icon: Icons.notifications_active_outlined,
          title: _strings.settingsNotificationsPref,
          value: _notificationsEnabled,
          onChanged: _handleNotificationToggle,
        ),
        _buildNavigationTile(
          icon: Icons.language_outlined,
          title: _strings.languageToggleTooltip,
          trailing: Text(
            _strings.locale.languageCode == 'en'
                ? "English"
                : "አማርኛ", // Use actual language names
            style: textTheme.bodyMedium?.copyWith(
              color: _SettingsStyle.textColorMuted,
            ),
          ),
          onTap: () => context.read<LocaleProvider>().toggleLocale(),
        ),

        // TODO: Add Theme toggle (Light/Dark/System) here if implemented
        _buildSectionDivider(),

        _buildSectionHeader(textTheme, _strings.settingsAccountSection),
        _buildActionTile(
          icon: Icons.lock_reset_outlined,
          title: _strings.settingsChangePassword,
          onTap: _handleChangePassword,
          iconColor: _SettingsStyle.primaryAccent,
        ),
        _buildActionTile(
          icon: Icons.logout_outlined,
          title: _strings.settingsLogoutAction, // Specific action string
          onTap: _handleLogout,
          iconColor: _SettingsStyle.warningColor,
          isLoading: _isLoggingOut,
        ),
        _buildActionTile(
          icon: Icons.delete_forever_outlined,
          title: _strings.settingsDeleteAccountAction, // Specific action string
          onTap: _handleDeleteAccount,
          iconColor: _SettingsStyle.errorColor,
          titleColor: _SettingsStyle.errorColor,
          isLoading: _isDeleting,
          isDestructive: true,
        ),

        _buildSectionDivider(),

        _buildSectionHeader(textTheme, _strings.settingsSupportSection),
        _buildNavigationTile(
          icon: Icons.help_outline,
          title: _strings.settingsHelpCenter,
          onTap:
              () =>
                  _launchUrlHelper('https://t.me/AbduKD'), // TODO: Replace URL
        ),
        _buildNavigationTile(
          icon: Icons.privacy_tip_outlined,
          title: _strings.settingsPrivacyPolicy,
          onTap:
              () =>
                  _launchUrlHelper('https://t.me/AbduKD'), // TODO: Replace URL
        ),
        _buildNavigationTile(
          icon: Icons.gavel_outlined,
          title: _strings.settingsTerms,
          onTap:
              () =>
                  _launchUrlHelper('https://t.me/AbduKD'), // TODO: Replace URL
        ),
        _buildNavigationTile(
          icon: Icons.info_outline,
          title: _strings.settingsAbout,
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName:
                  _strings.appName, // Use a general app name string
              applicationVersion: "1.0.0", // TODO: Get dynamically
              applicationIcon: Icon(
                Icons.travel_explore,
                size: 40,
                color: _SettingsStyle.primaryAccent,
              ),
              children: [
                Text(
                  _strings.settingsAboutDialogContent,
                  style: textTheme.bodyMedium,
                ),
              ], // Use localized content
            );
          },
        ),

        const SizedBox(height: 40), // Bottom padding
      ],
    );
  }

  // --- Helper Widgets for Settings List ---

  Widget _buildSectionHeader(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 24.0,
        bottom: 8.0,
      ),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: _SettingsStyle.textColorMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(
        color: _SettingsStyle.cardBorder.withOpacity(0.5),
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      tileColor: _SettingsStyle.listTileColor,
      leading: Icon(icon, color: _SettingsStyle.iconColor),
      title: Text(title, style: TextStyle(color: _SettingsStyle.textColor)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: _SettingsStyle.textColorMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      dense: true,
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      tileColor: _SettingsStyle.listTileColor,
      leading: Icon(icon, color: _SettingsStyle.iconColor),
      title: Text(title, style: TextStyle(color: _SettingsStyle.textColor)),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: _SettingsStyle.textColorMuted,
          ),
      onTap: onTap,
      dense: true,
      splashColor: _SettingsStyle.primaryAccent.withOpacity(0.1),
      focusColor: _SettingsStyle.primaryAccent.withOpacity(0.2),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    final Color effectiveColor = titleColor ?? _SettingsStyle.textColor;
    return ListTile(
      tileColor: _SettingsStyle.listTileColor,
      leading: Icon(icon, color: iconColor ?? _SettingsStyle.iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                ),
              )
              : null,
      onTap: isLoading ? null : onTap, // Disable tap when loading
      dense: true,
      splashColor: effectiveColor.withOpacity(0.1),
      focusColor: effectiveColor.withOpacity(0.2),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile.adaptive(
      tileColor: _SettingsStyle.listTileColor,
      secondary: Icon(icon, color: _SettingsStyle.iconColor),
      title: Text(
        title,
        style: TextStyle(
          color:
              enabled
                  ? _SettingsStyle.textColor
                  : _SettingsStyle.textColorMuted,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: _SettingsStyle.secondaryAccent,
      inactiveTrackColor: Colors.grey.shade700,
      inactiveThumbColor: Colors.grey.shade400,
      contentPadding: const EdgeInsets.only(left: 16.0, right: 6.0),
      dense: true,
    );
  }

  Widget _buildErrorState(TextTheme textTheme, String message) {
    _ensureStringsInitialized(); // Make sure strings are ready
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: _SettingsStyle.errorColor,
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: _SettingsStyle.textColorMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _SettingsStyle.primaryAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: _fetchUserProfile,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_strings.retryButton),
            ),
          ],
        ),
      ),
    );
  }
} // End _SettingScreenState
