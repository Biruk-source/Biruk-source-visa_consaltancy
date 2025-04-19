// lib/screens/profile.dart

import 'dart:io'; // Needed for File if implementing image picker
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserProfile;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart'; // Add image_picker to pubspec.yaml
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For image upload

// Import project files
import '../services/firebase_service.dart';
import '../models/user_profile.dart';
import '../providers/locale_provider.dart';
import 'app_strings.dart';
import 'login_screen.dart';

// --- Styles ---
class _ProfileStyle {
  static const Color primaryAccent = Color(0xFF00ACC1);
  static const Color secondaryAccent = Color(0xFFFFCA28);
  static const Color bgColor = Color(0xFF011015);
  static const Color appBarColor = Color(0xFF0A191E);
  static const Color cardBg = Color(0xFF102027);
  static const Color listTileColor = Color(0xFF162D36); // For settings items
  static const Color inputFillColor = Color(
    0xDD162D36,
  ); // Slightly different input background
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xB3E0E0E0);
  static const Color iconColor = Color(0xFF90A4AE);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color warningColor = Color(0xFFFFCA28);
  static const double defaultPadding = 16.0;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for editing form validation
  final FirebaseService _firebaseService = FirebaseService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isLoggingOut = false;

  // --- Controllers for Editing ---
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  // --- State for Preferences ---
  bool _notificationsEnabled = true;

  // --- State for Image Picker ---
  File? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers (will be populated in _fetchUserProfile)
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final AppStrings tempStrings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );

    try {
      final user = _firebaseService.getCurrentUser();
      if (user == null)
        throw Exception(tempStrings.loginErrorGenericLoginFailed);

      _userProfile = await _firebaseService.getUserProfile(user.uid);

      if (_userProfile == null && mounted) {
        _errorMessage = tempStrings.settingsErrorProfileNotFound;
        // Optionally create a fallback object if essential for UI, but error is better
      } else if (mounted) {
        // --- Populate Controllers and Preferences ---
        _usernameController.text = _userProfile!.username;
        _phoneController.text = _userProfile!.phone ?? '';
        _bioController.text = _userProfile!.bio ?? '';
        _notificationsEnabled = _userProfile!.notificationsEnabled;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        _errorMessage =
            e is Exception &&
                    e.toString().contains(
                      tempStrings.loginErrorGenericLoginFailed,
                    )
                ? e.toString().replaceFirst("Exception: ", "")
                : tempStrings.profileErrorLoading;
      }
    } finally {
      // Delay hiding loader slightly to avoid flicker if fetch is very fast
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  // --- Image Picking ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedXFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image slightly
        maxWidth: 800, // Limit width
      );

      if (pickedXFile != null) {
        setState(() {
          _pickedImageFile = File(pickedXFile.path);
        });
        // Automatically trigger save after picking an image? Optional.
        _saveProfileChanges();
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
      if (mounted) {
        final AppStrings strings = AppLocalizations.getStrings(
          Provider.of<LocaleProvider>(context, listen: false).locale,
        );
        _showSnackbar(
          strings.errorActionFailed,
          strings,
          isError: true,
        ); // Use localized string
      }
    }
  }

  void _showImageSourceDialog(BuildContext context, AppStrings strings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _ProfileStyle.cardBg,
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: _ProfileStyle.iconColor,
                  ),
                  title: Text(
                    'Gallery' /* TODO: Localize */,
                    style: TextStyle(color: _ProfileStyle.textColor),
                  ),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera,
                    color: _ProfileStyle.iconColor,
                  ),
                  title: Text(
                    'Camera' /* TODO: Localize */,
                    style: TextStyle(color: _ProfileStyle.textColor),
                  ),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.of(ctx).pop();
                  },
                ),
                if (_pickedImageFile != null ||
                    (_userProfile?.profilePictureUrl?.isNotEmpty ??
                        false)) // Show remove option if image exists
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: _ProfileStyle.errorColor,
                    ),
                    title: Text(
                      'Remove Photo' /* TODO: Localize */,
                      style: TextStyle(color: _ProfileStyle.errorColor),
                    ),
                    onTap: () {
                      setState(
                        () => _pickedImageFile = null,
                      ); // Clear picked file
                      // Also trigger save to update URL to null in Firestore
                      _saveProfileChanges(removePhoto: true);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  // --- Save Changes ---
  Future<void> _saveProfileChanges({bool removePhoto = false}) async {
    final AppStrings strings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );

    if (!_formKey.currentState!.validate()) {
      _showSnackbar(strings.formErrorCheckForm, strings, isError: true);
      return;
    }
    if (!mounted || _isSaving) return;
    setState(() => _isSaving = true);

    final user = _firebaseService.getCurrentUser();
    if (user == null) {
      _showSnackbar(
        strings.loginErrorGenericLoginFailed,
        strings,
        isError: true,
      );
      setState(() => _isSaving = false);
      return;
    }

    Map<String, dynamic> dataToUpdate = {
      'username': _usernameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'bio': _bioController.text.trim(),
      // 'notificationsEnabled': _notificationsEnabled, // Preferences saved separately
    };

    try {
      String? newImageUrl;
      // --- Image Upload Logic ---
      if (removePhoto) {
        dataToUpdate['profilePictureUrl'] =
            FieldValue.delete(); // Remove the field
        // Update local object too
        _pickedImageFile = null; // Clear picked file
        // Optional: Delete existing image from Storage
        // if (oldUrl != null) await _deleteOldProfilePicture(oldUrl);
      } else if (_pickedImageFile != null) {
        debugPrint("Uploading new profile picture...");
        newImageUrl = await _uploadProfilePicture(_pickedImageFile!, user.uid);
        if (newImageUrl != null) {
          dataToUpdate['profilePictureUrl'] = newImageUrl;
          // Update local object
        } else {
          throw Exception("Image upload failed.");
        }
      }
      // --- End Image Upload ---

      if (dataToUpdate.isNotEmpty) {
        // Only update if there are changes
        await _firebaseService.updateUserProfile(user.uid, dataToUpdate);
        if (mounted)
          _showSnackbar(strings.successPrefsSaved, strings); // Generic success
      } else {
        if (mounted)
          _showSnackbar("No changes to save.", strings); // TODO: Localize
      }
      if (mounted)
        setState(() {
          _pickedImageFile = null;
        }); // Clear picked file after successful save/upload
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted)
        _showSnackbar(strings.errorActionFailed, strings, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Helper to upload image to Firebase Storage ---
  Future<String?> _uploadProfilePicture(File imageFile, String uid) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures') // Folder in Storage
          .child('$uid.jpg'); // File name (use UID)

      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'), // Set content type
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint("Profile picture uploaded: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading profile picture: $e");
      return null;
    }
  }

  // --- Logout, Change Password, Delete Account Handlers (Similar to Settings Screen) ---
  Future<void> _handleLogout() async {
    final AppStrings strings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
    if (!mounted || _isLoggingOut) return;
    final bool? confirm = await _showConfirmationDialog(
      context: context, // Pass context here
      strings: strings, // Pass strings here
      title: strings.logoutConfirmTitle,
      content: strings.logoutConfirmContent,
      confirmText: strings.generalLogout,
      confirmColor: _ProfileStyle.errorColor,
    );
    if (confirm == true) {
      setState(() => _isLoggingOut = true);
      try {
        await _firebaseService.signOut();
        if (mounted)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
      } catch (e) {
        if (mounted)
          _showSnackbar(strings.errorActionFailed, strings, isError: true);
      } finally {
        Future.delayed(Duration.zero, () {
          if (mounted) setState(() => _isLoggingOut = false);
        });
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final AppStrings strings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
    if (_userProfile?.email == null || _userProfile!.email.isEmpty) {
      _showSnackbar(
        strings.settingsErrorCannotSendReset,
        strings,
        isError: true,
      );
      return;
    }
    try {
      await _firebaseService.sendPasswordResetEmail(_userProfile!.email);
      _showSnackbar(
        "${strings.loginSuccessPasswordResetSent} ${_userProfile!.email}.",
        strings,
      );
    } on FirebaseAuthException catch (e) {
      _showSnackbar(
        "${strings.settingsErrorFailedToSendReset}: ${e.message ?? ''}",
        strings,
        isError: true,
      );
    } catch (e) {
      _showSnackbar(strings.errorActionFailed, strings, isError: true);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final AppStrings strings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
    if (!mounted || _isDeleting || _userProfile == null) return;
    final bool? confirm1 = await _showConfirmationDialog(
      context: context,
      strings: strings,
      title: strings.settingsDeleteConfirmTitle,
      content: strings.settingsDeleteConfirmContent,
      confirmText: strings.settingsDeleteConfirmAction,
      confirmColor: Colors.red.shade900,
    );
    if (confirm1 != true) return;
    final bool? confirm2 = await _showConfirmationDialog(
      context: context,
      strings: strings,
      title: strings.settingsDeleteConfirmTitle2,
      content: strings.settingsDeleteConfirmInputPrompt,
      confirmText: strings.settingsDeleteConfirmActionFinal,
      confirmColor: Colors.red.shade900,
    );
    if (confirm2 != true) return;

    setState(() => _isDeleting = true);
    try {
      _showSnackbar(
        strings.settingsErrorReauthRequired,
        strings,
        isError: true,
      ); // REMINDER TO IMPLEMENT
      // await _showReauthDialogAndExecute(() async { // Wrap delete in re-auth logic
      // await _firebaseService.deleteUserAccount(); // Call AFTER successful re-auth
      // _showSnackbar(strings.settingsSuccessAccountDeleted, strings);
      // if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()),(route) => false);
      // });
      await Future.delayed(const Duration(seconds: 2)); // Placeholder
    } on FirebaseAuthException catch (e) {
      /* ... Error handling like in SettingScreen ... */
      if (mounted)
        _showSnackbar(
          e.code == 'requires-recent-login'
              ? strings.settingsErrorRequiresRecentLogin
              : "${strings.settingsErrorDeleteFailed}: ${e.message ?? ''}",
          strings,
          isError: true,
        );
    } catch (e) {
      /* ... Error handling like in SettingScreen ... */
      if (mounted)
        _showSnackbar(strings.errorActionFailed, strings, isError: true);
    } finally {
      Future.delayed(Duration.zero, () {
        if (mounted) setState(() => _isDeleting = false);
      });
    }
  }

  // --- Preference Handlers ---
  Future<void> _handleNotificationToggle(bool newValue) async {
    final AppStrings strings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
    if (_userProfile == null || !mounted) return;

    // Optimistically update UI
    setState(() => _notificationsEnabled = newValue);

    try {
      await _firebaseService.updateUserProfile(_userProfile!.uid, {
        'notificationsEnabled': newValue,
      });
      // No snackbar needed maybe, toggle is feedback enough
    } catch (e) {
      if (mounted) {
        _showSnackbar(strings.errorCouldNotSavePrefs, strings, isError: true);
        setState(() => _notificationsEnabled = !newValue); // Revert
      }
    }
  }

  // --- Launch URL ---
  Future<void> _launchUrlHelper(String urlString, AppStrings strings) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted)
        _showSnackbar(strings.errorCouldNotLaunchUrl, strings, isError: true);
    }
  }

  // --- Dialog and Snackbar Helpers ---
  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required AppStrings strings,
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _ProfileStyle.listTileColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: _ProfileStyle.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: GoogleFonts.poppins(color: _ProfileStyle.textColorMuted),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                cancelText ?? strings.generalCancel,
                style: GoogleFonts.poppins(color: _ProfileStyle.textColorMuted),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: confirmColor),
              child: Text(
                confirmText,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(
    String message,
    AppStrings strings, {
    bool isError = false,
  }) {
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
                ? _ProfileStyle.errorColor
                : _ProfileStyle.successColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final AppStrings strings = AppLocalizations.getStrings(
      localeProvider.locale,
    );
    final textTheme = strings.textTheme.apply(
      bodyColor: _ProfileStyle.textColor,
      displayColor: _ProfileStyle.textColor,
    );

    return Scaffold(
      backgroundColor: _ProfileStyle.bgColor,
      appBar: AppBar(
        backgroundColor: _ProfileStyle.appBarColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.3),
        title: Text(
          strings.profileTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Show Save button only when profile is loaded
          if (_userProfile != null && !_isLoading)
            _isSaving
                ? Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _ProfileStyle.secondaryAccent,
                      ),
                    ),
                  ),
                )
                : IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: strings.editAppSaveChangesButton,
                  onPressed: _saveProfileChanges,
                ), // Save Changes
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(textTheme, strings),
    );
  }

  Widget _buildBody(TextTheme textTheme, AppStrings strings) {
    if (_isLoading) {
      return const Center(
        child: SpinKitFadingCube(
          color: _ProfileStyle.secondaryAccent,
          size: 50,
        ),
      );
    }
    if (_errorMessage != null || _userProfile == null) {
      return _buildErrorState(
        textTheme,
        _errorMessage ?? strings.profileErrorLoading,
        strings,
      );
    }

    // --- Main Content: Single Scrollable Form ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_ProfileStyle.defaultPadding),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header ---
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildAvatar(
                    65,
                    _userProfile!,
                    _pickedImageFile,
                  ), // Larger Avatar
                  Material(
                    // Circular background for button
                    color: _ProfileStyle.secondaryAccent,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showImageSourceDialog(context, strings),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: _ProfileStyle.bgColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _userProfile!.email,
                style: textTheme.bodyLarge?.copyWith(
                  color: _ProfileStyle.textColorMuted,
                ),
              ),
            ), // Static email display
            const SizedBox(height: 24),

            // --- Editable Profile Section ---
            _buildSectionHeader(textTheme, strings.settingsProfileSection),
            _buildTextFormField(
              controller: _usernameController,
              label: strings.homeProfileLabelUsername, // Reuse label
              icon: Icons.person_outline,
              validator:
                  (v) =>
                      (v == null || v.isEmpty || v.length < 3)
                          ? strings.signupErrorUsernameMinLength
                          : null, // Add validation
              strings: strings,
            ),
            _buildTextFormField(
              controller: _phoneController,
              label: strings.profilePhoneLabel, // Use specific label
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator:
                  (v) =>
                      (v == null || v.isEmpty)
                          ? strings.signupErrorPhoneRequired
                          : null, // Basic validation
              strings: strings,
            ),
            _buildTextFormField(
              controller: _bioController,
              label: strings.profileBioLabel, // Use specific label
              icon: Icons.info_outline,
              maxLines: 3, // Allow multi-line bio
              strings: strings,
            ),

            _buildSectionDivider(),

            // --- Preferences Section ---
            _buildSectionHeader(textTheme, strings.settingsPreferencesSection),
            _buildSwitchTile(
              // Reusing helper from settings code
              icon: Icons.notifications_active_outlined,
              title: strings.settingsNotificationsPref,
              value: _notificationsEnabled,
              onChanged: _handleNotificationToggle,
              strings: strings,
            ),
            _buildNavigationTile(
              // Reusing helper from settings code
              icon: Icons.language_outlined,
              title: strings.languageToggleTooltip,
              trailing: Text(
                strings.locale.languageCode == 'en' ? "English" : "አማርኛ",
                style: textTheme.bodyMedium?.copyWith(
                  color: _ProfileStyle.textColorMuted,
                ),
              ),
              onTap: () => context.read<LocaleProvider>().toggleLocale(),
              strings: strings,
            ),

            _buildSectionDivider(),

            // --- Account Actions Section ---
            _buildSectionHeader(textTheme, strings.settingsAccountSection),
            _buildActionTile(
              // Reusing helper
              icon: Icons.lock_reset_outlined,
              title: strings.settingsChangePassword,
              onTap: _handleChangePassword,
              iconColor: _ProfileStyle.primaryAccent,
              strings: strings,
            ),
            _buildActionTile(
              icon: Icons.logout_outlined,
              title: strings.settingsLogoutAction,
              onTap: _handleLogout,
              iconColor: _ProfileStyle.warningColor,
              isLoading: _isLoggingOut,
              strings: strings,
            ),
            _buildActionTile(
              icon: Icons.delete_forever_outlined,
              title: strings.settingsDeleteAccountAction,
              onTap: _handleDeleteAccount,
              iconColor: _ProfileStyle.errorColor,
              titleColor: _ProfileStyle.errorColor,
              isLoading: _isDeleting,
              isDestructive: true,
              strings: strings,
            ),

            _buildSectionDivider(),

            // --- Support & Info Section ---
            _buildSectionHeader(textTheme, strings.settingsSupportSection),
            _buildNavigationTile(
              icon: Icons.help_outline,
              title: strings.settingsHelpCenter,
              onTap:
                  () => _launchUrlHelper(
                    'https://your-help-center-url.com',
                    strings,
                  ),
              strings: strings,
            ), // Pass strings
            _buildNavigationTile(
              icon: Icons.privacy_tip_outlined,
              title: strings.settingsPrivacyPolicy,
              onTap:
                  () => _launchUrlHelper(
                    'https://your-privacy-policy-url.com',
                    strings,
                  ),
              strings: strings,
            ),
            _buildNavigationTile(
              icon: Icons.gavel_outlined,
              title: strings.settingsTerms,
              onTap:
                  () => _launchUrlHelper('https://your-terms-url.com', strings),
              strings: strings,
            ),
            _buildNavigationTile(
              icon: Icons.info_outline,
              title: strings.settingsAbout,
              onTap:
                  () => showAboutDialog(
                    context: context,
                    applicationName: strings.appName,
                    applicationVersion: "1.0.1",
                    /* ... */ children: [
                      Text(
                        strings.settingsAboutDialogContent,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
              strings: strings,
            ),

            const SizedBox(height: 40), // Bottom Padding
          ],
        ),
      ),
    );
  }

  // --- Error State Widget ---
  Widget _buildErrorState(
    TextTheme textTheme,
    String message,
    AppStrings strings,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: _ProfileStyle.errorColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: _ProfileStyle.textColorMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchUserProfile,
              icon: const Icon(Icons.refresh),
              label: Text(strings.retryButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ProfileStyle.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Combined Helper Widgets ---
  // (Using updated versions from SettingScreen for consistency)

  Widget _buildAvatar(double radius, UserProfile user, File? pickedImage) {
    ImageProvider<Object>? backgroundImage;
    if (pickedImage != null) {
      backgroundImage = FileImage(pickedImage);
    } else if (user.profilePictureUrl != null &&
        user.profilePictureUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(user.profilePictureUrl!);
    } else {
      backgroundImage = const AssetImage(
        'assets/default_avatar.png',
      ); // Fallback asset
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _ProfileStyle.primaryAccent,
            _ProfileStyle.secondaryAccent.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _ProfileStyle.cardBg,
        backgroundImage: backgroundImage,
        onBackgroundImageError: (exception, stackTrace) {
          // Handle image load errors
          print("Error loading profile image: $exception");
          // Optionally show placeholder / initials on error
        },
        child:
            (backgroundImage is AssetImage ||
                        (pickedImage == null &&
                            (user.profilePictureUrl == null ||
                                user.profilePictureUrl!.isEmpty))) &&
                    user.username.isNotEmpty
                ? Text(
                  user.username[0].toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: radius * 0.7,
                    color: _ProfileStyle.secondaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildSectionHeader(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4.0,
        right: 4.0,
        top: 24.0,
        bottom: 8.0,
      ), // Reduced horizontal padding
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelLarge?.copyWith(
          // Bolder label
          color: _ProfileStyle.textColorMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 16.0,
      ), // More space around divider
      child: Divider(
        color: _ProfileStyle.cardBorder.withOpacity(0.5),
        height: 1,
        thickness: 1,
      ),
    );
  }

  // Updated TextFormField Helper
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppStrings strings,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          color:
              enabled ? _ProfileStyle.textColor : _ProfileStyle.textColorMuted,
        ),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _ProfileStyle.textColorMuted),
          // hintText: strings.someHintKey, // Add hint text from strings if needed
          prefixIcon: Icon(
            icon,
            color: _ProfileStyle.primaryAccent.withOpacity(0.8),
            size: 20,
          ), // Softer icon color
          filled: true,
          fillColor: _ProfileStyle.inputFillColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          // Consistent border style
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _ProfileStyle.cardBorder, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _ProfileStyle.cardBorder.withOpacity(0.7),
              width: 0.8,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _ProfileStyle.primaryAccent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _ProfileStyle.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _ProfileStyle.errorColor, width: 1.5),
          ),
          errorStyle: TextStyle(
            color: _ProfileStyle.errorColor.withOpacity(0.9),
          ),
        ),
        validator: enabled ? validator : null,
      ),
    );
  }

  // Reusing Settings Helper Tiles for Consistency

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    required AppStrings strings,
  }) {
    final textTheme = strings.textTheme.apply(
      bodyColor: _ProfileStyle.textColor,
      displayColor: _ProfileStyle.textColor,
    );
    return ListTile(
      tileColor: _ProfileStyle.listTileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon, color: _ProfileStyle.iconColor),
      title: Text(title, style: textTheme.bodyLarge), // Slightly larger text
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: _ProfileStyle.textColorMuted,
          ),
      onTap: onTap,
      dense: false, // Less dense
      contentPadding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 16,
      ), // Adjust padding
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
    required AppStrings strings,
  }) {
    final Color effectiveColor = titleColor ?? _ProfileStyle.textColor;
    final textTheme = strings.textTheme.apply(
      bodyColor: effectiveColor,
      displayColor: effectiveColor,
    );
    return ListTile(
      tileColor: _ProfileStyle.listTileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon, color: iconColor ?? _ProfileStyle.iconColor),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
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
      onTap: isLoading ? null : onTap,
      dense: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    required AppStrings strings,
  }) {
    final textTheme = strings.textTheme.apply(
      bodyColor:
          enabled ? _ProfileStyle.textColor : _ProfileStyle.textColorMuted,
    );
    return SwitchListTile.adaptive(
      tileColor: _ProfileStyle.listTileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      secondary: Icon(icon, color: _ProfileStyle.iconColor),
      title: Text(title, style: textTheme.bodyLarge),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: _ProfileStyle.secondaryAccent,
      inactiveTrackColor: Colors.grey.shade700,
      inactiveThumbColor: Colors.grey.shade400,
      contentPadding: const EdgeInsets.only(
        left: 16.0,
        right: 6.0,
        top: 4,
        bottom: 4,
      ),
      dense: false,
    );
  }
} // End _ProfileScreenState
