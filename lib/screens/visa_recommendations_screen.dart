// lib/screens/visa_recommendations_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tilt/flutter_tilt.dart'; // Keep Tilt
import 'dart:ui'; // For blur

// Import project files
import '../models/visa_info.dart'; // Import the model
import '../providers/locale_provider.dart';
import 'app_strings.dart';
import 'visa_application_form_screen.dart'; // To navigate to the form
// import '../models/user_profile.dart'; // Import if needed for personalization logic

// Constants for Styling
class _RecScreenStyle {
  static const double cardRadius = 16.0;
  static const double hPadding = 18.0;
  static const double vPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const Color primaryAccent = Color(0xFF26C6DA); // Cyan
  static const Color secondaryAccent = Color(0xFFFFD54F); // Amber
  static const Color bgColorStart = Color(0xFF0A191E); // Dark teal/blue base
  static const Color bgColorEnd = Color(0xFF00333A); // Dark teal
  static const Color cardBg = Color(
    0xFF1F3035,
  ); // Dark desaturated cyan card bg
  static const Color cardBorder = Color(0xFF37474F); // BlueGrey border
  static const Color textColor = Color(0xFFE0E0E0); // Off-white
  static const Color textColorMuted = Color(0xFF9E9E9E); // Grey
  static const Color successColor = Colors.greenAccent;
  static const Color shade300 = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFEF5350);
}

class VisaRecommendationsScreen extends StatefulWidget {
  // TODO: Optionally pass UserProfile for real recommendations
  // final UserProfile? userProfile;
  // const VisaRecommendationsScreen({super.key, this.userProfile});

  const VisaRecommendationsScreen({super.key});

  @override
  State<VisaRecommendationsScreen> createState() =>
      _VisaRecommendationsScreenState();
}

class _VisaRecommendationsScreenState extends State<VisaRecommendationsScreen> {
  late AppStrings _strings;
  List<VisaInfo> _visaInfoList = []; // Initialize as empty list
  bool _isLoading = true;
  String? _recommendedVisaKey; // Key of the top recommended visa
  String? _errorMessage; // To store potential loading errors

  @override
  void initState() {
    super.initState();
    // Defer string initialization until didChangeDependencies
    _loadAndRecommendVisaData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
    // Re-initialize list if strings change AFTER initial load
    if (!_isLoading) {
      _initializeVisaListWithStrings();
      if (mounted) setState(() {}); // Refresh UI with new localized names
    }
  }

  // --- Data Loading and Recommendation Logic ---
  Future<void> _loadAndRecommendVisaData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      // ** Simulate fetching data - Replace with actual fetch **
      // Option 1: Fetch pre-defined list from Firestore config?
      // Option 2: Build list locally (as done here for demo)
      await Future.delayed(const Duration(milliseconds: 700)); // Simulate delay

      _initializeVisaListWithStrings(); // Build the list using current strings

      // ** Simulate Personalization Logic **
      // Replace this with logic based on widget.userProfile or fetched data
      // Example: If user indicated 'study' interest, recommend F-1
      // if (widget.userProfile?.interest == 'study') {
      //   _recommendedVisaKey = 'student_f1';
      // } else if (...) { ... }
      // else { _recommendedVisaKey = null; } // No specific recommendation
      _recommendedVisaKey = 'work_h1b'; // Hardcoded recommendation for demo
    } catch (e) {
      debugPrint("Error loading visa data: $e");
      _errorMessage = _strings.recInfoNoData; // Use localized error string
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Creates the VisaInfo list using the current _strings instance
  void _initializeVisaListWithStrings() {
    _visaInfoList = [
      VisaInfo(
        typeKey: 'student_f1',
        localizedName: _strings.visaTypeF1,
        eligibility:
            'Full-time student at SEVP-certified US institution. Proof of financial support. Intent to depart US after studies.',
        documents: [
          'Valid Passport',
          'Form I-20 (issued by school)',
          'SEVIS I-901 Fee Payment Confirmation',
          'DS-160 Confirmation Page',
          'Visa Interview Appointment Letter',
          'Financial Evidence (bank statements, sponsor letter)',
          'Academic Transcripts/Diplomas',
          'Standardized Test Scores (if applicable)',
          'Passport-style Photos',
        ],
        processingTime: 'Varies greatly by consulate (check website)',
        fees: '~ \$185 (MRV) + \$350 (SEVIS)',
        validity: 'Duration of Status (D/S) + grace period',
        description: 'For pursuing academic or language studies.',
      ),
      VisaInfo(
        typeKey: 'work_h1b',
        localizedName: _strings.visaTypeH1B,
        eligibility:
            'Requires a US employer sponsor. Job must be in a "specialty occupation" requiring a bachelor\'s degree or higher (or equivalent experience). Must have the required degree/experience. Subject to annual cap/lottery.',
        documents: [
          'Valid Passport',
          'Approved I-129 Petition Receipt Notice (I-797)',
          'Copy of Labor Condition Application (LCA)',
          'Job Offer Letter & Detailed Description',
          'Proof of Qualifications (Degree, Transcripts, Licenses)',
          'DS-160 Confirmation Page',
          'Visa Interview Appointment Letter',
          'Passport-style Photos',
          'Employment Verification Letter (optional but helpful)',
        ],
        processingTime:
            'Highly variable (Months, includes petition + visa processing)',
        fees:
            'Complex (Employer pays most, e.g., \$460 base + \$500 fraud + \$750/\$1500 ACWIA + optional premium processing)',
        validity:
            'Up to 3 years initially, renewable up to 6 years total (exceptions exist)',
        description: 'For temporary work in specialized professional roles.',
      ),
      VisaInfo(
        typeKey: 'tourist_b1b2',
        localizedName: _strings.visaTypeB1B2,
        eligibility:
            'Purpose must be temporary (tourism, business meetings, medical treatment, visiting family). Must demonstrate strong ties to home country and intent to return. Sufficient funds for the trip.',
        documents: [
          'Valid Passport',
          'DS-160 Confirmation Page',
          'Visa Interview Appointment Letter',
          'Passport-style Photos',
          'Proof of Financial Means',
          'Proof of Ties to Home Country (job letter, property ownership, family)',
          'Travel Itinerary / Hotel Bookings (optional but recommended)',
          'Letter of Invitation (if applicable)',
        ],
        processingTime: 'Varies by consulate (check website for wait times)',
        fees: '~ \$185 (MRV)',
        validity:
            'Often 5-10 years, but entry granted typically for max 6 months per visit.',
        description: 'For tourism, short business trips, or medical visits.',
      ),
      VisaInfo(
        // Example for Scholarship (could be J-1 or F-1 based)
        typeKey: 'scholarship_j1', // Example key
        localizedName:
            "J-1 Exchange Visitor (Scholarship)", // TODO: Add to AppStrings
        eligibility:
            'Accepted into a designated J-1 exchange program (e.g., Fulbright). Meets program requirements. Proof of funding (scholarship award letter).',
        documents: [
          'Valid Passport',
          'DS-2019 Form (issued by program sponsor)',
          'SEVIS I-901 Fee Payment Confirmation',
          'DS-160 Confirmation Page',
          'Visa Interview Appointment Letter',
          'Scholarship Award Letter / Financial Proof',
          'Academic Credentials',
          'Passport-style Photos',
        ],
        processingTime: 'Varies by program/consulate',
        fees: '~ \$185 (MRV) + \$220 (SEVIS, usually)',
        validity: 'Duration of program specified on DS-2019',
        description: 'For participation in approved exchange programs.',
      ),
    ];
  }

  // --- Navigation ---
  void _navigateToApplicationForm(String visaTypeKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VisaApplicationFormScreen(initialVisaTypeKey: visaTypeKey),
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    _strings = AppLocalizations.getStrings(localeProvider.locale);
    if (_visaInfoList != null)
      _initializeVisaListWithStrings(); // Refresh names on locale change

    final textTheme = _strings.textTheme.apply(
      bodyColor: _RecScreenStyle.textColor,
      displayColor: _RecScreenStyle.textColor,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _strings.recScreenTitle,
          style: textTheme.headlineSmall?.copyWith(
            color: _RecScreenStyle.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _RecScreenStyle.bgColorStart.withOpacity(0.85),
        elevation: 0,
        iconTheme: IconThemeData(color: _RecScreenStyle.textColor),
        actions: [
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
            colors: [_RecScreenStyle.bgColorStart, _RecScreenStyle.bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? Center(
                    child: SpinKitFadingCube(
                      color: _RecScreenStyle.secondaryAccent,
                      size: 40.0,
                    ),
                  )
                  : _errorMessage != null
                  ? _buildErrorState(
                    textTheme,
                    _errorMessage!,
                  ) // Show specific error
                  : _buildContent(textTheme),
        ),
      ),
    );
  }

  Widget _buildContent(TextTheme textTheme) {
    // Inside _buildContent method:
    VisaInfo? recommendedVisa; // Declare as nullable
    if (_visaInfoList != null && _visaInfoList!.isNotEmpty) {
      try {
        // Use firstWhere but catch the StateError if not found
        recommendedVisa = _visaInfoList!.firstWhere(
          (v) => v.typeKey == _recommendedVisaKey,
        );
      } catch (e) {
        // If not found, firstWhere throws an error. Catch it and keep recommendedVisa null.
        if (e is StateError) {
          recommendedVisa = null;
          debugPrint(
            "Recommended visa key '$_recommendedVisaKey' not found in the list.",
          );
        } else {
          // Re-throw other unexpected errors
          rethrow;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(_RecScreenStyle.hPadding),
      physics: const BouncingScrollPhysics(),
      children: [
        if (recommendedVisa != null) ...[
          _buildPersonalizedRecommendationCard(recommendedVisa, textTheme),
          const SizedBox(height: _RecScreenStyle.sectionSpacing * 1.5),
          Center(
            child: Text(
              "- ${_strings.loginOrDivider} -",
              style: textTheme.labelLarge?.copyWith(
                color: _RecScreenStyle.textColorMuted,
              ),
            ),
          ),
          const SizedBox(height: _RecScreenStyle.sectionSpacing * 1.5),
        ],
        // Title for the general list
        Padding(
          padding: const EdgeInsets.only(bottom: _RecScreenStyle.vPadding),
          child: Text(
            "Other Common Visa Types" /* TODO: Localize */,
            style: textTheme.headlineSmall?.copyWith(
              color: _RecScreenStyle.textColor,
            ),
          ),
        ),
        // List all other visa types
        ...?_visaInfoList // Use null-aware spread
            ?.where((v) => v.typeKey != _recommendedVisaKey)
            ?.map(
              (visa) => Padding(
                padding: const EdgeInsets.only(
                  bottom: _RecScreenStyle.sectionSpacing,
                ),
                child: _buildVisaTile(visa, textTheme),
              ),
            )
            .toList(),
        if (_visaInfoList == null ||
            _visaInfoList!
                .where((v) => v.typeKey != _recommendedVisaKey)
                .isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "No other visa types available.",
                style: textTheme.bodyMedium?.copyWith(
                  color: _RecScreenStyle.textColorMuted,
                ),
              ),
            ),
          ), // Handle case where only recommendation exists or list is empty
      ],
    );
  }

  Widget _buildErrorState(TextTheme textTheme, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: _RecScreenStyle.errorColor,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: textTheme.titleMedium?.copyWith(
              color: _RecScreenStyle.textColorMuted,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadAndRecommendVisaData,
            icon: Icon(Icons.refresh),
            label: Text(_strings.retryButton),
          ),
        ],
      ),
    );
  }

  // --- Builds the top "Personalized Recommendation" Card ---
  Widget _buildPersonalizedRecommendationCard(
    VisaInfo visa, // The recommended VisaInfo object
    TextTheme textTheme, // The localized text theme
  ) {
    return Card(
      elevation: 6.0, // Slightly more pronounced shadow
      margin: const EdgeInsets.only(
        bottom: _RecScreenStyle.sectionSpacing * 0.5, // Keep bottom margin
      ),
      clipBehavior: Clip.antiAlias, // Clip content to rounded corners
      color: _RecScreenStyle.primaryAccent.withOpacity(
        0.15, // Highlight background color
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          _RecScreenStyle.cardRadius,
        ), // Use style constant
        side: BorderSide(
          color: _RecScreenStyle.primaryAccent.withOpacity(
            0.6,
          ), // Highlight border
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          _RecScreenStyle.hPadding + 2,
        ), // Adjusted padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content left
          children: [
            // --- Card Header ---
            Row(
              children: [
                const Icon(
                  // Use const for static icons
                  Icons.star_rounded, // Recommendation icon
                  color: _RecScreenStyle.secondaryAccent,
                  size: 26,
                ),
                const SizedBox(width: 10), // Use const
                Expanded(
                  // Allow title to wrap if long
                  child: Text(
                    _strings.recPersonalizedTitle, // Localized title
                    style: textTheme.titleLarge?.copyWith(
                      color: _RecScreenStyle.secondaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Use const
            // --- Card Subtitle ---
            Text(
              _strings.recPersonalizedSubtext, // Localized subtext
              style: textTheme.bodyMedium?.copyWith(
                color: _RecScreenStyle.textColorMuted, // Use muted color
              ),
            ),
            const SizedBox(
              height: 16,
            ), // Use const (increased space before details)
            // --- Visa Details Content (using helper) ---
            _buildVisaTileContent(
              visa,
              textTheme,
              isRecommended: true,
            ), // Show details

            const SizedBox(height: 16), // Use const (space before buttons)
            // --- ACTION BUTTONS (Using Wrap for Responsiveness) ---
            Wrap(
              alignment:
                  WrapAlignment
                      .spaceBetween, // Distribute space, allow wrapping
              spacing: 12.0, // Horizontal space between buttons
              runSpacing: 8.0, // Vertical space if buttons wrap
              children: [
                // --- Update Profile Button ---
                TextButton.icon(
                  icon: Icon(
                    Icons.manage_accounts_outlined,
                    size: 18,
                    color: _RecScreenStyle.secondaryAccent.withOpacity(
                      0.9,
                    ), // Slightly brighter icon
                  ),
                  label: Text(
                    _strings
                        .recPersonalizedActionUpdateProfile, // Localized text
                    style: textTheme.labelMedium?.copyWith(
                      color: _RecScreenStyle.secondaryAccent.withOpacity(
                        0.9,
                      ), // Slightly brighter text
                    ),
                    overflow:
                        TextOverflow.ellipsis, // Prevent long text overflow
                  ),
                  onPressed: () {
                    _showSnackbar(
                      "Navigate to Profile Edit",
                    ); // Placeholder Action
                  },
                  style: TextButton.styleFrom(
                    // Add some padding for better tap area
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                // --- Apply Now Button ---
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ), // Changed icon, use const
                  label: Text(
                    _strings.recInfoApplyButton,
                  ), // Correct localized text
                  onPressed:
                      () => _navigateToApplicationForm(
                        visa.typeKey,
                      ), // Navigate to form with key
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _RecScreenStyle.primaryAccent, // Use primary color
                    foregroundColor: Colors.black, // Black text for contrast
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ), // Button padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ), // Rounded shape
                    textStyle: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ), // Button text style
                  ),
                ),
              ],
            ),
            // --- END ACTION BUTTONS ---
          ],
        ),
      ),
    );
  }

  Widget _buildVisaTile(VisaInfo visa, TextTheme textTheme) {
    return Tilt(
      // Add Tilt to individual cards
      tiltConfig: const TiltConfig(angle: 5, enableRevert: true),
      lightConfig: const LightConfig(
        color: Colors.white,
        minIntensity: 0.1,
        maxIntensity: 0.4,
      ),
      shadowConfig: const ShadowConfig(
        color: Colors.black38,
        spreadFactor: 2,
        minIntensity: 0.1,
        maxIntensity: 0.5,
      ),
      child: Card(
        elevation: 3.0,
        color: _RecScreenStyle.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_RecScreenStyle.cardRadius),
          side: BorderSide(color: _RecScreenStyle.cardBorder.withOpacity(0.5)),
        ),
        child: ExpansionTile(
          key: PageStorageKey(visa.typeKey), // Maintain expansion state
          tilePadding: const EdgeInsets.symmetric(
            horizontal: _RecScreenStyle.hPadding,
            vertical: _RecScreenStyle.vPadding * 0.7,
          ),
          collapsedIconColor: _RecScreenStyle.primaryAccent.withOpacity(0.7),
          iconColor: _RecScreenStyle.primaryAccent,
          title: Text(
            visa.localizedName,
            style: textTheme.titleLarge?.copyWith(
              color: _RecScreenStyle.primaryAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle:
              visa.description != null
                  ? Text(
                    visa.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: _RecScreenStyle.textColorMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                  : null,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: _RecScreenStyle.hPadding,
                right: _RecScreenStyle.hPadding,
                bottom: _RecScreenStyle.vPadding,
                top: 0,
              ),
              child: _buildVisaTileContent(visa, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisaTileContent(
    VisaInfo visa,
    TextTheme textTheme, {
    bool isRecommended = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
          color: _RecScreenStyle.cardBorder,
          height: 20,
          thickness: 0.8,
        ),
        _buildSection(
          _strings.recInfoEligibility,
          Text(
            visa.eligibility,
            style: textTheme.bodyMedium?.copyWith(
              color: _RecScreenStyle.textColorMuted,
              height: 1.4,
            ),
          ),
          Icons.check_circle_outline_rounded,
        ),
        _buildSection(
          _strings.recInfoDocuments,
          _buildDocumentList(visa.documents, textTheme),
          Icons.description_outlined,
        ),
        _buildSection(
          _strings.recInfoProcessingTime,
          Text(
            visa.processingTime,
            style: textTheme.bodyMedium?.copyWith(
              color: _RecScreenStyle.textColorMuted,
            ),
          ),
          Icons.hourglass_bottom_rounded,
        ), // Changed icon
        _buildSection(
          _strings.recInfoFees,
          Text(
            visa.fees,
            style: textTheme.bodyMedium?.copyWith(
              color: _RecScreenStyle.textColorMuted,
            ),
          ),
          Icons.price_check_rounded,
        ), // Changed icon
        _buildSection(
          _strings.recInfoValidity,
          Text(
            visa.validity,
            style: textTheme.bodyMedium?.copyWith(
              color: _RecScreenStyle.textColorMuted,
            ),
          ),
          Icons.event_repeat_outlined,
        ), // Changed icon
        if (!isRecommended) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward_ios_rounded, size: 16),
              label: Text(_strings.recInfoApplyButton),
              onPressed: () => _navigateToApplicationForm(visa.typeKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: _RecScreenStyle.primaryAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, Widget content, IconData icon) {
    final textTheme = _strings.textTheme.apply(
      bodyColor: _RecScreenStyle.textColor,
      displayColor: _RecScreenStyle.textColor,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _RecScreenStyle.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  /* Uppercase Title */ style: textTheme.labelLarge?.copyWith(
                    color: _RecScreenStyle.primaryAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(List<String> docs, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          docs
              .map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 8,
                        color: _RecScreenStyle.textColorMuted.withOpacity(0.5),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc,
                          style: textTheme.bodyMedium?.copyWith(
                            color: _RecScreenStyle.textColorMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  // Helper to show snackbar locally
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? Colors.white : Colors.black87),
        ),
        backgroundColor:
            isError
                ? _RecScreenStyle.errorColor
                : _RecScreenStyle.successColor, // Use defined color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
} // End of State
