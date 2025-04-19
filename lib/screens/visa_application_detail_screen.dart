// lib/screens/visa_application_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp

// Import project files
import '../services/firebase_service.dart';
import '../models/visa_application.dart'; // Use the updated model
import '../providers/locale_provider.dart';
import 'app_strings.dart'; // Ensure this has ALL keys defined
import 'visa_application_edit_screen.dart'; // Import the edit screen

// --- Local Styles ---
class _DetailScreenStyle {
  static const double cardRadius = 16.0;
  static const double hPadding = 18.0;
  static const double vPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const Color primaryAccent = Color(0xFF26C6DA);
  static const Color secondaryAccent = Color(0xFFFFD54F);
  static const Color bgColorStart = Color(0xFF0A191E);
  static const Color bgColorEnd = Color(0xFF00333A);
  static const Color cardBg = Color(0xFF1F3035);
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xFF9E9E9E);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color pendingColor = Color(0xFF42A5F5);
  static const Color warningColor = Color(0xFFFFCA28);
}

class VisaApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  const VisaApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<VisaApplicationDetailScreen> createState() =>
      _VisaApplicationDetailScreenState();
}

class _VisaApplicationDetailScreenState
    extends State<VisaApplicationDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  // REMOVED: late AppStrings _strings;
  VisaApplication? _application;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch data on initial load
    _fetchApplicationDetails();
  }

  // REMOVED: didChangeDependencies for initializing _strings

  Future<void> _fetchApplicationDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Get strings temporarily ONLY for potential errors DURING fetch
    // This uses listen: false because we don't need to rebuild here for locale changes
    final AppStrings tempStrings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );

    try {
      final user = _firebaseService.getCurrentUser();
      if (user == null) {
        throw Exception(
          tempStrings.loginErrorGenericLoginFailed,
        ); // Use temp strings
      }

      _application = await _firebaseService.getApplicationDetails(
        user.uid,
        widget.applicationId,
      );

      if (_application == null && mounted) {
        _errorMessage = tempStrings.appDetailsErrorNotFound; // Use temp strings
      }
    } catch (e) {
      debugPrint("Error fetching app details (${widget.applicationId}): $e");
      if (mounted) {
        // Determine the error message using temp strings
        _errorMessage =
            e is Exception &&
                    e.toString().contains(
                      tempStrings.loginErrorGenericLoginFailed,
                    )
                ? e.toString().replaceFirst("Exception: ", "")
                : tempStrings.errorGeneric;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // REMOVED: _stringsInitialized() helper method

  Future<void> _navigateToEditScreen() async {
    if (_application == null) return;

    final bool? didUpdate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VisaApplicationEditScreen(application: _application!),
      ),
    );

    if (didUpdate == true && mounted) {
      _fetchApplicationDetails();
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // --- Get Provider and Strings HERE using context.watch ---
    // This makes the build method re-run when the locale changes
    final localeProvider = context.watch<LocaleProvider>();
    final AppStrings strings = AppLocalizations.getStrings(
      localeProvider.locale,
    );
    // --- Use the local 'strings' variable below ---

    final textTheme = strings.textTheme.apply(
      bodyColor: _DetailScreenStyle.textColor,
      displayColor: _DetailScreenStyle.textColor,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          strings.appDetailsTitle, // Use local 'strings'
          style: textTheme.headlineSmall?.copyWith(
            color: _DetailScreenStyle.textColor,
          ),
        ),
        backgroundColor: _DetailScreenStyle.bgColorStart.withOpacity(0.85),
        elevation: 0,
        iconTheme: IconThemeData(color: _DetailScreenStyle.textColor),
        actions: [
          if (_application != null && !_isLoading && _errorMessage == null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip:
                  strings
                      .settingsEditProfile, // Use appropriate localized string
              onPressed: _navigateToEditScreen,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.translate_rounded),
              tooltip: strings.languageToggleTooltip, // Use local 'strings'
              // Use context.read for actions that don't need to listen
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
            colors: [
              _DetailScreenStyle.bgColorStart,
              _DetailScreenStyle.bgColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // Pass the local 'strings' object down to _buildContent
        child: SafeArea(child: _buildContent(textTheme, strings)),
      ),
    );
  }

  // --- Content Building Logic ---
  // Update _buildContent to accept and use the 'strings' parameter
  Widget _buildContent(TextTheme textTheme, AppStrings strings) {
    // 1. Handle Loading State
    if (_isLoading) {
      return _buildLoadingState(textTheme, strings); // Pass strings
    }

    // 2. Handle Error State
    if (_errorMessage != null) {
      return _buildErrorState(
        textTheme,
        _errorMessage!,
        strings,
      ); // Pass strings
    }

    // 3. Handle Case where Application is Null
    if (_application == null) {
      return _buildErrorState(
        textTheme,
        strings.appDetailsErrorNotFound,
        strings,
      ); // Pass strings
    }

    // 4. Display Application Details
    return RefreshIndicator(
      onRefresh: _fetchApplicationDetails,
      color: _DetailScreenStyle.primaryAccent,
      backgroundColor: _DetailScreenStyle.cardBg,
      child: ListView(
        padding: const EdgeInsets.all(_DetailScreenStyle.hPadding),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          // --- Status Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: strings.appDetailsCurrentStatus,
            titleIcon: Icons.flag_circle_outlined,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusChip(
                  _application!.status,
                  textTheme,
                  strings,
                ), // Pass strings
              ),
              const SizedBox(height: 12),
              if (_application!.statusUpdatedAt != null)
                _buildInfoChip(
                  Icons.update_outlined,
                  "${strings.appDetailsLastUpdate}: ${_formatTimeAgo(_application!.statusUpdatedAt!.toDate(), strings)}", // Pass strings
                  textTheme,
                ),
              if (_application!.status.toLowerCase() == 'rejected' &&
                  _application!.rejectionReason != null &&
                  _application!.rejectionReason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: _buildDetailItem(
                    textTheme,
                    Icons.report_problem_outlined,
                    "Rejection Reason", // TODO: Use strings.rejectionReasonLabel
                    _application!.rejectionReason!,
                    iconColor: _DetailScreenStyle.errorColor,
                  ),
                ),
              if (_application!.consultantNotes != null &&
                  _application!.consultantNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: _buildDetailItem(
                    textTheme,
                    Icons.note_alt_outlined,
                    "Consultant Notes", // TODO: Use strings.consultantNotesLabel
                    _application!.consultantNotes!,
                    iconColor: _DetailScreenStyle.secondaryAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: _DetailScreenStyle.sectionSpacing),

          // --- Visa Info Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: strings.appFormSectionVisaDetails,
            titleIcon: Icons.article_outlined,
            children: [
              _buildDetailItem(
                textTheme,
                Icons.category_outlined,
                strings.appDetailVisaType,
                _application!.visaType,
              ),
              _buildDetailItem(
                textTheme,
                Icons.flag_outlined,
                strings.appDetailDestination,
                _application!.destinationCountry ?? '-',
              ),
              _buildDetailItem(
                textTheme,
                Icons.event_note_outlined,
                strings.appFormEntryDateLabel,
                _formatDate(_application!.proposedEntryDate, strings),
              ), // Pass strings
              _buildDetailItem(
                textTheme,
                Icons.timelapse_outlined,
                strings.appFormStayDurationLabel,
                _application!.proposedStayDuration ?? '-',
              ),
              _buildDetailItem(
                textTheme,
                Icons.info_outline,
                strings.appDetailPurpose,
                _application!.purposeOfVisit ?? '-',
              ),
              if (_application!.studentUniversity?.isNotEmpty ?? false)
                _buildDetailItem(
                  textTheme,
                  Icons.school_outlined,
                  strings.appFormStudentUniversityLabel,
                  _application!.studentUniversity!,
                ),
              if (_application!.studentCourse?.isNotEmpty ?? false)
                _buildDetailItem(
                  textTheme,
                  Icons.book_outlined,
                  strings.appFormStudentCourseLabel,
                  _application!.studentCourse!,
                ),
              if (_application!.workEmployer?.isNotEmpty ?? false)
                _buildDetailItem(
                  textTheme,
                  Icons.business_center_outlined,
                  strings.appFormWorkEmployerLabel,
                  _application!.workEmployer!,
                ),
              if (_application!.workJobTitle?.isNotEmpty ?? false)
                _buildDetailItem(
                  textTheme,
                  Icons.badge_outlined,
                  strings.appFormWorkJobTitleLabel,
                  _application!.workJobTitle!,
                ),
              if (_application!.touristItinerary?.isNotEmpty ?? false)
                _buildDetailItem(
                  textTheme,
                  Icons.map_outlined,
                  strings.appFormTouristItineraryLabel,
                  _application!.touristItinerary!,
                ),
            ],
          ),
          const SizedBox(height: _DetailScreenStyle.sectionSpacing),

          // --- Personal Info Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: strings.appFormSectionPersonalInfo,
            titleIcon: Icons.person_outline,
            children: [
              _buildDetailItem(
                textTheme,
                Icons.badge_outlined,
                strings.appDetailFullName,
                _application!.fullName ?? '-',
              ),
              _buildDetailItem(
                textTheme,
                Icons.cake_outlined,
                strings.appDetailDOB,
                _formatDate(_application!.dateOfBirth, strings),
              ), // Pass strings
              _buildDetailItem(
                textTheme,
                Icons.public_outlined,
                strings.appDetailNationality,
                _application!.nationality ?? '-',
              ),
              _buildDetailItem(
                textTheme,
                Icons.contact_mail_outlined,
                strings.appDetailPassportNo,
                _application!.passportNumber ?? '-',
              ),
              _buildDetailItem(
                textTheme,
                Icons.event_busy_outlined,
                strings.appFormPassportExpiryLabel,
                _formatDate(_application!.passportExpiryDate, strings),
              ), // Pass strings
            ],
          ),
          const SizedBox(height: _DetailScreenStyle.sectionSpacing),

          // --- Contact Info Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: strings.appFormSectionContactAddress,
            titleIcon: Icons.contact_page_outlined,
            children: [
              _buildDetailItem(
                textTheme,
                Icons.phone_iphone_rounded,
                strings.appDetailPhone,
                _application!.phoneNumber ?? '-',
              ),
              _buildDetailItem(
                textTheme,
                Icons.home_work_outlined,
                strings.appFormAddressStreetLabel,
                _application!.addressStreet ?? '-',
              ),
              _buildDetailItem(
                textTheme,
                Icons.location_city_outlined,
                strings.appFormAddressCityLabel,
                _application!.addressCity ?? '-',
              ),
              if (_application!.addressState?.isNotEmpty ?? false)
                _buildDetailItem(
                  textTheme,
                  Icons.map,
                  strings.appFormAddressStateLabel,
                  _application!.addressState!,
                ),
              if (_application!.addressZip?.isNotEmpty ?? false)
                _buildDetailItem(
                  textTheme,
                  Icons.markunread_mailbox_outlined,
                  strings.appFormAddressZipLabel,
                  _application!.addressZip!,
                ),
              _buildDetailItem(
                textTheme,
                Icons.map_outlined,
                strings.appFormAddressCountryLabel,
                _application!.addressCountry ?? '-',
              ),
            ],
          ),
          const SizedBox(height: _DetailScreenStyle.sectionSpacing),

          // --- Travel History Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: strings.appFormSectionTravelHistory,
            titleIcon: Icons.history_edu_outlined,
            children: [
              _buildDetailItem(
                textTheme,
                Icons.flight_takeoff_outlined,
                strings.appFormPreviousVisitsLabel,
                _formatYesNo(_application!.hasPreviousVisits, strings),
              ), // Pass strings
              if (_application!.hasPreviousVisits == true)
                _buildDetailItem(
                  textTheme,
                  Icons.description_outlined,
                  strings.appFormPreviousVisasLabel,
                  _application!.previousVisasDetails ?? '-',
                ),
              _buildDetailItem(
                textTheme,
                Icons.report_problem_outlined,
                strings.appFormVisaDenialsLabel,
                _formatYesNo(_application!.hasVisaDenials, strings),
              ), // Pass strings
              if (_application!.hasVisaDenials == true)
                _buildDetailItem(
                  textTheme,
                  Icons.gavel_outlined,
                  strings.appFormDenialDetailsLabel,
                  _application!.denialDetails ?? '-',
                ),
            ],
          ),
          const SizedBox(height: _DetailScreenStyle.sectionSpacing),

          // --- Financials Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: strings.appFormSectionFinancials,
            titleIcon: Icons.account_balance_wallet_outlined,
            children: [
              _buildDetailItem(
                textTheme,
                Icons.credit_card,
                strings.appFormFundingSourceLabel,
                _getLocalizedFundingSource(
                      _application!.fundingSource,
                      strings,
                    ) ??
                    '-',
              ), // Pass strings
            ],
          ),
          const SizedBox(height: _DetailScreenStyle.sectionSpacing),

          // --- Background Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: strings.appFormSectionBackground,
            titleIcon: Icons.shield_outlined,
            children: [
              _buildDetailItem(
                textTheme,
                Icons.gavel_rounded,
                strings.appFormCriminalRecordLabel,
                _formatYesNo(_application!.hasCriminalRecord, strings),
              ), // Pass strings
            ],
          ),
          const SizedBox(height: _DetailScreenStyle.sectionSpacing),

          // --- Submission Timestamp Card ---
          _buildDetailCard(
            // Pass strings down
            textTheme,
            strings,
            title: "Submission Info", // TODO: Use strings.submissionInfoTitle
            titleIcon: Icons.timer_outlined,
            children: [
              _buildDetailItem(
                textTheme,
                Icons.calendar_today,
                strings.appDetailsSubmitted,
                _formatFullDateTime(_application!.createdAt.toDate(), strings),
              ), // Pass strings
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  // Update helpers to accept 'strings' when needed

  Widget _buildLoadingState(TextTheme textTheme, AppStrings strings) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpinKitFadingCube(
            color: _DetailScreenStyle.secondaryAccent,
            size: 40.0,
          ),
          const SizedBox(height: 16),
          Text(
            strings.loading, // Use passed strings
            style: textTheme.bodyMedium?.copyWith(
              color: _DetailScreenStyle.textColorMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    TextTheme textTheme,
    String message,
    AppStrings strings,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: _DetailScreenStyle.errorColor,
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: _DetailScreenStyle.textColorMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _DetailScreenStyle.primaryAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: _fetchApplicationDetails,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(strings.retryButton), // Use passed strings
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    TextTheme textTheme,
    AppStrings strings, { // Accept strings
    required String title,
    required IconData titleIcon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      color: _DetailScreenStyle.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_DetailScreenStyle.cardRadius),
        side: BorderSide(color: _DetailScreenStyle.cardBorder.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(_DetailScreenStyle.vPadding + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  titleIcon,
                  color: _DetailScreenStyle.secondaryAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: _DetailScreenStyle.secondaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
              color: _DetailScreenStyle.cardBorder,
              height: 24,
              thickness: 0.8,
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    TextTheme textTheme,
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? _DetailScreenStyle.primaryAccent,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: _DetailScreenStyle.textColorMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? '-' : value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: _DetailScreenStyle.textColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String status,
    TextTheme textTheme,
    AppStrings strings,
  ) {
    Color chipColor;
    Color textColor = _DetailScreenStyle.textColor;
    String statusText = status;
    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = _DetailScreenStyle.successColor.withOpacity(0.2);
        textColor = _DetailScreenStyle.successColor;
        statusText = strings.homeStatusApproved;
        break;
      case 'rejected':
        chipColor = _DetailScreenStyle.errorColor.withOpacity(0.2);
        textColor = _DetailScreenStyle.errorColor;
        statusText = strings.homeStatusRejected;
        break;
      case 'processing':
        chipColor = _DetailScreenStyle.secondaryAccent.withOpacity(0.2);
        textColor = _DetailScreenStyle.secondaryAccent;
        statusText = strings.homeStatusProcessing;
        break;
      case 'submitted':
      case 'pending':
        chipColor = _DetailScreenStyle.pendingColor.withOpacity(0.2);
        textColor = _DetailScreenStyle.pendingColor;
        statusText = strings.homeStatusPending;
        break;
      case 'requires information':
        chipColor = _DetailScreenStyle.warningColor.withOpacity(0.25);
        textColor = _DetailScreenStyle.warningColor;
        statusText = strings.statusRequiresInfo;
        break;
      case 'on hold':
        chipColor = Colors.grey.shade700.withOpacity(0.3);
        textColor = Colors.grey.shade400;
        statusText = strings.statusOnHold;
        break;
      default:
        chipColor = Colors.grey.shade800;
        textColor = _DetailScreenStyle.textColorMuted;
        statusText = strings.homeStatusUnknown;
        break;
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

  String _formatDate(String? dateString, AppStrings strings) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateString);
      return DateFormat(
        'MMMM dd, yyyy',
        strings.locale.languageCode,
      ).format(dt);
    } catch (e) {
      debugPrint("Error parsing date '$dateString': $e");
      return dateString;
    }
  }

  String _formatFullDateTime(DateTime? dateTime, AppStrings strings) {
    if (dateTime == null) return '-';
    try {
      return DateFormat(
        'MMM dd, yyyy, hh:mm a',
        strings.locale.languageCode,
      ).format(dateTime);
    } catch (e) {
      debugPrint("Error formatting DateTime '$dateTime': $e");
      return dateTime.toIso8601String();
    }
  }

  String _formatYesNo(bool? value, AppStrings strings) {
    if (value == null) return '-';
    return value
        ? strings.appFormPreviousVisitsYes
        : strings.appFormPreviousVisitsNo;
  }

  String _formatTimeAgo(DateTime dateTime, AppStrings strings) {
    final Duration diff = DateTime.now().difference(dateTime);
    String langCode = strings.locale.languageCode;
    if (diff.inDays > 7) {
      return DateFormat('MMM dd, yyyy', langCode).format(dateTime);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}${langCode == 'am' ? 'ቀ' : 'd'} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}${langCode == 'am' ? 'ሰ' : 'h'} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}${langCode == 'am' ? 'ደ' : 'm'} ago';
    } else {
      return langCode == 'am' ? 'አሁን' : 'Just now'; // TODO: Use strings.justNow
    }
  }

  Widget _buildInfoChip(IconData icon, String text, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _DetailScreenStyle.textColorMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: _DetailScreenStyle.textColorMuted,
            ),
          ),
        ],
      ),
    );
  }

  String? _getLocalizedFundingSource(String? key, AppStrings strings) {
    if (key == null) return null;
    switch (key.toLowerCase()) {
      case 'self':
        return strings.appFormFundingSourceSelf;
      case 'sponsor':
        return strings.appFormFundingSourceSponsor;
      case 'scholarship':
        return strings.appFormFundingSourceScholarship;
      case 'other':
        return strings.appFormFundingSourceOther;
      default:
        return key;
    }
  }
} // End State
