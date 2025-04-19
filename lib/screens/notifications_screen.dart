// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../services/firebase_service.dart';
import '../providers/locale_provider.dart';
import 'app_strings.dart';
import 'visa_application_detail_screen.dart';
// Import detail screen if needed for navigation
// import 'visa_application_detail_screen.dart';

// Use consistent styling constants
class _AppStyle {
  static const Color primaryAccent = Color(0xFF26C6DA);
  static const Color secondaryAccent = Color(0xFFFFD54F);
  static const Color bgColorStart = Color(0xFF0A191E);
  static const Color bgColorEnd = Color(0xFF00333A);
  static const Color cardBg = Color(
    0xFF1F3035,
  ); // Use card bg for list items maybe
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xFF9E9E9E);
  static const Color successColor = Colors.greenAccent;
  static const Color errorColor = Color(0xFFEF5350);
  static const Color unreadIndicator = Colors.blueAccent;
  static const double hPadding = 8.0;
  static const double vPadding = 8.0;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late AppStrings _strings;
  Stream<QuerySnapshot>? _notificationStream;
  String? _userId;
  String notificationsMarkAllReadError = "error marking as read";
  String notificationsMarkAllReadSuccess = "marked as read";

  @override
  void initState() {
    super.initState();
    // Strings initialized in didChangeDependencies
    _userId = _firebaseService.getCurrentUser()?.uid;
    if (_userId != null) {
      // Fetch a larger number of notifications for this screen
      _notificationStream = _firebaseService.getUserNotificationsStream(
        _userId!,
        limit: 100,
      );
    } else {
      // Handle case where user is somehow not logged in when reaching this screen
      _notificationStream = Stream.error(
        "User not logged in",
      ); // TODO: Localize
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
  }

  // --- Helper Methods ---
  Future<void> _markNotificationAsRead(String notificationId) async {
    if (_userId != null && notificationId.isNotEmpty) {
      try {
        // Optimistic UI update could be done here if needed (visually change tile)
        await _firebaseService.markNotificationAsRead(_userId!, notificationId);
        // No need for snackbar on single mark read? Optional.
      } catch (e) {
        _showErrorSnackbar("Failed to mark as read."); // TODO: Localize
      }
    }
  }

  Future<void> _markAllNotificationsRead() async {
    if (_userId != null) {
      try {
        // Show loading maybe?
        await _firebaseService.markAllNotificationsAsRead(_userId!);
        if (mounted)
          _showSuccessSnackbar(_strings.notificationsMarkAllReadSuccess);
      } catch (e) {
        if (mounted) _showErrorSnackbar(_strings.notificationsMarkAllReadError);
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    String langCode = _strings.locale.languageCode;
    if (diff.inDays > 7)
      return DateFormat(
        'MMM dd, yyyy - hh:mm a',
        langCode,
      ).format(dateTime); // Show time for older ones
    if (diff.inDays >= 1)
      return '${diff.inDays}${langCode == 'am' ? 'ቀ' : 'd'} ago';
    if (diff.inHours >= 1)
      return '${diff.inHours}${langCode == 'am' ? 'ሰ' : 'h'} ago';
    if (diff.inMinutes >= 1)
      return '${diff.inMinutes}${langCode == 'am' ? 'ደ' : 'm'} ago';
    return langCode == 'am' ? 'አሁን' : 'Just now';
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'applicationupdate':
        return Icons.article_rounded;
      case 'applicationsubmitted':
        return Icons.check_circle_rounded;
      case 'welcome':
        return Icons.celebration_rounded;
      case 'actionrequired':
        return Icons.warning_amber_rounded;
      case 'message':
        return Icons.mail_outline_rounded; // Example for messages
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationIconColor(String type, bool isRead) {
    if (isRead) return _AppStyle.textColorMuted;
    switch (type.toLowerCase()) {
      case 'applicationsubmitted':
        return _AppStyle.successColor;
      case 'welcome':
        return _AppStyle.secondaryAccent;
      case 'actionrequired':
        return _AppStyle.errorColor;
      default:
        return _AppStyle.primaryAccent;
    }
  }

  void _handleNotificationTap(
    Map<String, dynamic> data,
    String id,
    bool isRead,
  ) {
    // 1. Mark as read (if not already)
    if (!isRead) {
      _markNotificationAsRead(id);
    }
    // 2. Navigate if applicable
    String? relatedDocId = data['relatedDocId'] as String?;
    String type = data['type'] ?? 'General';

    if (type.toLowerCase().contains('application') && relatedDocId != null) {
      // Navigate to the specific application detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => VisaApplicationDetailScreen(applicationId: relatedDocId),
        ),
      );
    } else {
      // Show message or navigate to a general notification area if needed
      _showSuccessSnackbar(
        "Notification: ${data['message'] ?? ''}",
      ); // Example feedback
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: _AppStyle.errorColor,
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
        backgroundColor: _AppStyle.successColor,
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
    _strings = AppLocalizations.getStrings(localeProvider.locale);
    final textTheme = _strings.textTheme.apply(
      bodyColor: _AppStyle.textColor,
      displayColor: _AppStyle.textColor,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _strings.notificationsTitle,
          style: textTheme.headlineSmall?.copyWith(color: _AppStyle.textColor),
        ),
        backgroundColor: _AppStyle.bgColorStart.withOpacity(
          0.9,
        ), // Slightly more opaque AppBar
        elevation: 0,
        iconTheme: IconThemeData(color: _AppStyle.textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rtl_rounded),
            tooltip: _strings.notificationsMarkAllReadTooltip,
            onPressed: _markAllNotificationsRead,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.translate_rounded),
              tooltip: _strings.languageToggleTooltip,
              onPressed: () => context.read<LocaleProvider>().toggleLocale(),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_AppStyle.bgColorStart, _AppStyle.bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _notificationStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitFadingCube(
                    color: _AppStyle.secondaryAccent,
                    size: 40.0,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    _strings.notificationsError,
                    style: textTheme.titleMedium?.copyWith(
                      color: _AppStyle.errorColor,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    _strings.notificationsEmpty,
                    style: textTheme.titleMedium?.copyWith(
                      color: _AppStyle.textColorMuted,
                    ),
                  ),
                );
              }

              final notifications = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(_AppStyle.hPadding),
                itemCount: notifications.length,
                separatorBuilder:
                    (context, index) => Divider(
                      color: _AppStyle.cardBorder.withOpacity(0.5),
                      height: 1,
                    ),
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
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Notification Tile Widget ---
  Widget _buildNotificationTile(
    Map<String, dynamic> data,
    String id,
    bool isRead,
    TextTheme textTheme,
  ) {
    final String message =
        data['message'] ?? 'No message content.' /* TODO: Localize */;
    final String type = data['type'] ?? 'General';
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final IconData iconData = _getNotificationIcon(type);
    final Color iconColor = _getNotificationIconColor(type, isRead);
    final String timeAgo =
        timestamp != null ? _formatTimeAgo(timestamp.toDate()) : '';

    return Material(
      // Wrap with Material for InkWell effect
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationTap(data, id, isRead),
        splashColor: _AppStyle.primaryAccent.withOpacity(0.1),
        highlightColor: _AppStyle.primaryAccent.withOpacity(0.05),
        child: Opacity(
          opacity: isRead ? 0.65 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: _AppStyle.vPadding,
              horizontal: 4.0,
            ), // Add horizontal padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  iconData,
                  color: iconColor,
                  size: 28,
                ), // Slightly larger icon
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: textTheme.bodyLarge?.copyWith(
                          // Use larger font for message
                          color:
                              isRead
                                  ? _AppStyle.textColorMuted
                                  : _AppStyle.textColor,
                          fontWeight:
                              isRead
                                  ? FontWeight.normal
                                  : FontWeight.w500, // Bold if unread
                        ),
                        maxLines: 3, // Allow more lines
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        timeAgo,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 12),
                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: _AppStyle.unreadIndicator,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _AppStyle.unreadIndicator.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ], // Glow effect
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
