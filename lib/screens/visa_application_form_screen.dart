// lib/screens/visa_application_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../services/firebase_service.dart';
import '../providers/locale_provider.dart';
import 'app_strings.dart';
// Import models if needed for defaults or validation
// import '../models/user_profile.dart';

// Constants matching HomeScreen style
class _AppStyle {
  static const double cardRadius = 18.0;
  static const double hPadding = 20.0;
  static const double vPadding = 16.0;
  static const Color primaryAccent = Color(0xFF26C6DA);
  static const Color secondaryAccent = Color(0xFFFFD54F);
  static const Color bgColorStart = Color(0xFF0A191E);
  static const Color bgColorEnd = Color(0xFF00333A);
  static const Color cardBg = Color(0xFF1F3035);
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xFF9E9E9E);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Colors.greenAccent;
  static const double sectionSpacing = 10;
  static const Color cardBgSubtle = Color.fromARGB(
    153,
    1,
    46,
    24,
  ); // Keep this one maybe
}

class VisaApplicationFormScreen extends StatefulWidget {
  final String? initialVisaTypeKey;

  const VisaApplicationFormScreen({super.key, this.initialVisaTypeKey});

  @override
  State<VisaApplicationFormScreen> createState() =>
      _VisaApplicationFormScreenState();
}

class _VisaApplicationFormScreenState extends State<VisaApplicationFormScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  late AppStrings _strings;

  // --- Form Controllers ---
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _stayDurationController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _passportNumberController =
      TextEditingController();
  final TextEditingController _addressStreetController =
      TextEditingController();
  final TextEditingController _addressCityController = TextEditingController();
  final TextEditingController _addressStateController = TextEditingController();
  final TextEditingController _addressZipController = TextEditingController();
  final TextEditingController _addressCountryController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _previousVisasController =
      TextEditingController();
  final TextEditingController _denialDetailsController =
      TextEditingController();
  final TextEditingController _studentUniversityController =
      TextEditingController();
  final TextEditingController _studentCourseController =
      TextEditingController();
  final TextEditingController _workEmployerController = TextEditingController();
  final TextEditingController _workJobTitleController = TextEditingController();
  final TextEditingController _touristItineraryController =
      TextEditingController();
  final TextEditingController _purposeController =
      TextEditingController(); // General purpose if needed

  // --- State Variables ---
  String? _selectedVisaType;
  DateTime? _selectedEntryDate;
  DateTime? _selectedDob;
  DateTime? _selectedPassportExpiry;
  bool? _hasPreviousVisits; // Use nullable bool for radio buttons
  bool? _hasVisaDenials;
  bool? _hasCriminalRecord;
  String? _selectedFundingSource;
  bool _isLoading = false;

  // --- Dropdown Options ---
  late List<MapEntry<String, String>> _visaTypes;
  late List<MapEntry<String, String>> _fundingSources;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
    _initializeOptions(); // Initialize localized options
  }

  void _initializeOptions() {
    _visaTypes = [
      MapEntry('student', _strings.visaTypeStudent),
      MapEntry('work', _strings.visaTypeWork),
      MapEntry('tourist', _strings.visaTypeTourist),
      MapEntry('other', _strings.visaTypeOther),
    ];
    _fundingSources = [
      MapEntry('self', _strings.appFormFundingSourceSelf),
      MapEntry('sponsor', _strings.appFormFundingSourceSponsor),
      MapEntry('scholarship', _strings.appFormFundingSourceScholarship),
      MapEntry('other', _strings.appFormFundingSourceOther),
    ];
    // Reset selected value if it's no longer valid after locale change (optional)
    if (_selectedVisaType != null &&
        !_visaTypes.any((e) => e.key == _selectedVisaType)) {
      _selectedVisaType = null;
    }
    if (_selectedFundingSource != null &&
        !_fundingSources.any((e) => e.key == _selectedFundingSource)) {
      _selectedFundingSource = null;
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _destinationController.dispose();
    _stayDurationController.dispose();
    _fullNameController.dispose();
    _nationalityController.dispose();
    _passportNumberController.dispose();
    _addressStreetController.dispose();
    _addressCityController.dispose();
    _addressStateController.dispose();
    _addressZipController.dispose();
    _addressCountryController.dispose();
    _phoneController.dispose();
    _previousVisasController.dispose();
    _denialDetailsController.dispose();
    _studentUniversityController.dispose();
    _studentCourseController.dispose();
    _workEmployerController.dispose();
    _workJobTitleController.dispose();
    _touristItineraryController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  // --- Date Picker ---
  Future<void> _selectDate(
    BuildContext context,
    ValueChanged<DateTime> onDateSelected, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1920),
      lastDate: lastDate ?? DateTime(2101),
      builder: (context, child) {
        // Optional: Theme the date picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _AppStyle.primaryAccent,
              onPrimary: Colors.black,
              surface: _AppStyle.cardBg,
              onSurface: _AppStyle.textColor,
            ),
            dialogBackgroundColor: _AppStyle.cardBgSubtle,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  // --- Form Submission ---
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar(_strings.formErrorCheckForm, isError: true);
      return;
    }

    final user = _firebaseService.getCurrentUser();
    if (user == null) {
      _showSnackbar("User not logged in.", isError: true); // TODO: Localize
      return;
    }

    setState(() => _isLoading = true);

    // Format dates for storage (e.g., ISO 8601 string)
    String? entryDateStr = _selectedEntryDate?.toIso8601String();
    String? dobStr = _selectedDob?.toIso8601String();
    String? passportExpiryStr = _selectedPassportExpiry?.toIso8601String();

    // Construct the detailed data map
    final applicationData = {
      // Section 1
      'visaType': _selectedVisaType,
      'destinationCountry': _destinationController.text.trim(),
      'proposedEntryDate': entryDateStr,
      'proposedStayDuration': _stayDurationController.text.trim(),
      // Section 2
      'fullName': _fullNameController.text.trim(),
      'dateOfBirth': dobStr,
      'nationality': _nationalityController.text.trim(),
      'passportNumber': _passportNumberController.text.trim(),
      'passportExpiryDate': passportExpiryStr,
      // Section 3
      'addressStreet': _addressStreetController.text.trim(),
      'addressCity': _addressCityController.text.trim(),
      'addressState': _addressStateController.text.trim(),
      'addressZip': _addressZipController.text.trim(),
      'addressCountry': _addressCountryController.text.trim(),
      'phoneNumber': _phoneController.text.trim(), // Consistent key
      // Section 4
      'hasPreviousVisits': _hasPreviousVisits,
      'previousVisasDetails': _previousVisasController.text.trim(),
      'hasVisaDenials': _hasVisaDenials,
      'denialDetails': _denialDetailsController.text.trim(),
      // Section 5 (Purpose - include based on visa type or all optionally)
      'purposeOfVisit': _purposeController.text.trim(), // Keep general purpose?
      if (_selectedVisaType == 'student') ...{
        'studentUniversity': _studentUniversityController.text.trim(),
        'studentCourse': _studentCourseController.text.trim(),
      },
      if (_selectedVisaType == 'work') ...{
        'workEmployer': _workEmployerController.text.trim(),
        'workJobTitle': _workJobTitleController.text.trim(),
      },
      if (_selectedVisaType == 'tourist') ...{
        'touristItinerary': _touristItineraryController.text.trim(),
      },
      // Section 6
      'fundingSource': _selectedFundingSource,
      // Add sponsor fields if _selectedFundingSource == 'sponsor'
      // Section 7
      'hasCriminalRecord': _hasCriminalRecord,
      // Add more background fields
    };

    try {
      final docRef = await _firebaseService.addVisaApplication(
        user.uid,
        applicationData,
      );
      if (docRef != null) {
        _showSnackbar(_strings.appFormSuccessMessage);
        if (mounted) Navigator.pop(context); // Go back on success
      } else {
        throw Exception('Failed to submit.');
      }
    } catch (e) {
      debugPrint("Application Submission Error: $e");
      if (mounted) _showSnackbar(_strings.appFormFailureMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Helpers ---
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? Colors.white : Colors.black),
        ),
        backgroundColor:
            isError ? _AppStyle.errorColor : _AppStyle.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData? icon, {
    String? hint,
  }) {
    // Allow nullable icon
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _AppStyle.primaryAccent.withOpacity(0.8),
        fontSize: 14,
      ), // Smaller label
      hintText: hint ?? label,
      hintStyle: TextStyle(
        color: _AppStyle.textColorMuted.withOpacity(0.5),
        fontSize: 14,
      ),
      prefixIcon:
          icon != null
              ? Icon(icon, color: _AppStyle.primaryAccent, size: 20)
              : null, // Conditional icon
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ), // Adjusted padding
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _AppStyle.cardBorder.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _AppStyle.primaryAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _AppStyle.errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _AppStyle.errorColor, width: 1.5),
      ),
      errorStyle: TextStyle(
        color: _AppStyle.errorColor.withOpacity(0.9),
        fontSize: 11,
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    _strings = AppLocalizations.getStrings(localeProvider.locale);
    _initializeOptions(); // Ensure options are updated if locale changes

    final textTheme = _strings.textTheme.apply(
      bodyColor: _AppStyle.textColor,
      displayColor: _AppStyle.textColor,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _strings.appFormTitle,
          style: textTheme.headlineSmall?.copyWith(
            color: _AppStyle.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _AppStyle.bgColorStart.withOpacity(
          0.8,
        ), // Semi-transparent AppBar
        elevation: 0,
        iconTheme: IconThemeData(color: _AppStyle.textColor),
        actions: [
          // Add language toggle to AppBar
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: _AppStyle.hPadding,
              vertical: 20,
            ),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Section 1: Visa Details ---
                  _buildSectionHeader(
                    _strings.appFormSectionVisaDetails,
                    textTheme,
                  ),
                  _buildDropdownField(
                    _strings.appFormVisaTypeLabel,
                    _strings.appFormVisaTypeHint,
                    _selectedVisaType,
                    _visaTypes,
                    (value) => setState(() => _selectedVisaType = value),
                    (value) =>
                        value == null
                            ? _strings.appFormErrorVisaTypeRequired
                            : null,
                  ),
                  _buildTextField(
                    _destinationController,
                    _strings.appFormDestinationLabel,
                    _strings.appFormDestinationHint,
                    Icons.public_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorDestinationRequired
                            : null,
                  ),
                  _buildDateField(
                    context,
                    _strings.appFormEntryDateLabel,
                    _selectedEntryDate,
                    (date) => setState(() => _selectedEntryDate = date),
                  ),
                  _buildTextField(
                    _stayDurationController,
                    _strings.appFormStayDurationLabel,
                    _strings.appFormStayDurationHint,
                    Icons.timelapse_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ), // Basic validation
                  // --- Section 2: Personal Info ---
                  _buildSectionHeader(
                    _strings.appFormSectionPersonalInfo,
                    textTheme,
                  ),
                  _buildTextField(
                    _fullNameController,
                    _strings.appFormFullNameLabel,
                    _strings.appFormFullNameHint,
                    Icons.person_outline_rounded,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ),
                  _buildDateField(
                    context,
                    _strings.appFormDOBLabel,
                    _selectedDob,
                    (date) => setState(() => _selectedDob = date),
                    lastDate: DateTime.now(),
                  ), // Cannot be born in future
                  _buildTextField(
                    _nationalityController,
                    _strings.appFormNationalityLabel,
                    _strings.appFormNationalityHint,
                    Icons.flag_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ),
                  _buildTextField(
                    _passportNumberController,
                    _strings.appFormPassportNumberLabel,
                    _strings.appFormPassportNumberHint,
                    Icons.badge_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ), // Add regex validation if needed
                  _buildDateField(
                    context,
                    _strings.appFormPassportExpiryLabel,
                    _selectedPassportExpiry,
                    (date) => setState(() => _selectedPassportExpiry = date),
                    firstDate: DateTime.now(),
                  ), // Must expire in future
                  // --- Section 3: Contact/Address ---
                  _buildSectionHeader(
                    _strings.appFormSectionContactAddress,
                    textTheme,
                  ),
                  _buildTextField(
                    _phoneController,
                    _strings.appFormPhoneNumberLabel,
                    _strings.appFormPhoneNumberHint,
                    Icons.phone_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.signupErrorPhoneRequired
                            : null /* Add better phone validation */,
                  ),
                  _buildTextField(
                    _addressStreetController,
                    _strings.appFormAddressStreetLabel,
                    _strings.appFormAddressStreetHint,
                    Icons.home_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ),
                  _buildTextField(
                    _addressCityController,
                    _strings.appFormAddressCityLabel,
                    _strings.appFormAddressCityHint,
                    Icons.location_city_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ),
                  // Add State, Zip, Country similarly
                  _buildTextField(
                    _addressCountryController,
                    _strings.appFormAddressCountryLabel,
                    _strings.appFormAddressCountryHint,
                    Icons.map_outlined,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ),

                  // --- Section 4: Travel History ---
                  _buildSectionHeader(
                    _strings.appFormSectionTravelHistory,
                    textTheme,
                  ),
                  _buildRadioGroupField(
                    _strings.appFormPreviousVisitsLabel,
                    _hasPreviousVisits,
                    (val) => setState(() => _hasPreviousVisits = val),
                    textTheme,
                    yesText: _strings.appFormPreviousVisitsYes,
                    noText: _strings.appFormPreviousVisitsNo,
                  ),
                  if (_hasPreviousVisits == true) // Conditional field
                    _buildTextField(
                      _previousVisasController,
                      _strings.appFormPreviousVisasLabel,
                      _strings.appFormPreviousVisasHint,
                      Icons.history_edu_outlined,
                      null,
                      maxLines: 3,
                    ), // Optional details
                  _buildRadioGroupField(
                    _strings.appFormVisaDenialsLabel,
                    _hasVisaDenials,
                    (val) => setState(() => _hasVisaDenials = val),
                    textTheme,
                    yesText: _strings.appFormVisaDenialsYes,
                    noText: _strings.appFormVisaDenialsNo,
                  ),
                  if (_hasVisaDenials == true) // Conditional field
                    _buildTextField(
                      _denialDetailsController,
                      _strings.appFormDenialDetailsLabel,
                      _strings.appFormDenialDetailsHint,
                      Icons.report_problem_outlined,
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? _strings.appFormErrorFieldRequired
                              : null,
                      maxLines: 3,
                    ), // Required if denied
                  // --- Section 5: Purpose Details ---
                  _buildSectionHeader(
                    _strings.appFormSectionPurposeDetails,
                    textTheme,
                  ),
                  // General Purpose (optional if type specific is enough)
                  _buildTextField(
                    _purposeController,
                    _strings.appFormPurposeLabel,
                    _strings.appFormPurposeHint,
                    Icons.info_outline,
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? _strings.appFormErrorPurposeRequired
                            : null,
                    maxLines: 3,
                  ),
                  // --- Type Specific Fields (Consider hiding/showing based on _selectedVisaType) ---
                  if (_selectedVisaType == 'student') ...[
                    const SizedBox(height: _AppStyle.sectionSpacing / 2),
                    _buildTextField(
                      _studentUniversityController,
                      _strings.appFormStudentUniversityLabel,
                      null,
                      Icons.school_outlined,
                      (v) =>
                          (v == null || v.isEmpty)
                              ? _strings.appFormErrorFieldRequired
                              : null,
                    ),
                    const SizedBox(height: _AppStyle.vPadding),
                    _buildTextField(
                      _studentCourseController,
                      _strings.appFormStudentCourseLabel,
                      null,
                      Icons.book_outlined,
                      (v) =>
                          (v == null || v.isEmpty)
                              ? _strings.appFormErrorFieldRequired
                              : null,
                    ),
                  ],
                  if (_selectedVisaType == 'work') ...[
                    const SizedBox(height: _AppStyle.sectionSpacing / 2),
                    _buildTextField(
                      _workEmployerController,
                      _strings.appFormWorkEmployerLabel,
                      null,
                      Icons.business_center_outlined,
                      (v) =>
                          (v == null || v.isEmpty)
                              ? _strings.appFormErrorFieldRequired
                              : null,
                    ),
                    const SizedBox(height: _AppStyle.vPadding),
                    _buildTextField(
                      _workJobTitleController,
                      _strings.appFormWorkJobTitleLabel,
                      null,
                      Icons.badge_outlined,
                      (v) =>
                          (v == null || v.isEmpty)
                              ? _strings.appFormErrorFieldRequired
                              : null,
                    ),
                  ],
                  if (_selectedVisaType == 'tourist') ...[
                    const SizedBox(height: _AppStyle.sectionSpacing / 2),
                    _buildTextField(
                      _touristItineraryController,
                      _strings.appFormTouristItineraryLabel,
                      null,
                      Icons.map_outlined,
                      (v) =>
                          (v == null || v.isEmpty)
                              ? _strings.appFormErrorFieldRequired
                              : null,
                      maxLines: 4,
                    ),
                  ],

                  // --- Section 6: Financials ---
                  _buildSectionHeader(
                    _strings.appFormSectionFinancials,
                    textTheme,
                  ),
                  _buildDropdownField(
                    _strings.appFormFundingSourceLabel,
                    _strings.appFormFundingSourceHint,
                    _selectedFundingSource,
                    _fundingSources,
                    (value) => setState(() => _selectedFundingSource = value),
                    (value) =>
                        value == null
                            ? _strings.appFormErrorFieldRequired
                            : null,
                  ),
                  // TODO: Add conditional fields for Sponsor details if _selectedFundingSource == 'sponsor'

                  // --- Section 7: Background ---
                  _buildSectionHeader(
                    _strings.appFormSectionBackground,
                    textTheme,
                  ),
                  _buildRadioGroupField(
                    _strings.appFormCriminalRecordLabel,
                    _hasCriminalRecord,
                    (val) => setState(() => _hasCriminalRecord = val),
                    textTheme,
                    yesText: _strings.appFormCriminalRecordYes,
                    noText: _strings.appFormCriminalRecordNo,
                  ),
                  // Add more questions similarly...

                  // --- Section 8: Documents ---
                  _buildSectionHeader(
                    _strings.appFormSectionDocuments,
                    textTheme,
                  ),
                  Text(
                    _strings.appFormDocsInstruction,
                    style: textTheme.bodyMedium?.copyWith(
                      color: _AppStyle.textColorMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    // Display required docs as chips
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Chip(
                        label: Text(_strings.appFormDocsPassport),
                        backgroundColor: _AppStyle.cardBgSubtle,
                        labelStyle: textTheme.labelSmall,
                      ),
                      Chip(
                        label: Text(_strings.appFormDocsPhoto),
                        backgroundColor: _AppStyle.cardBgSubtle,
                        labelStyle: textTheme.labelSmall,
                      ),
                      Chip(
                        label: Text(_strings.appFormDocsFinancials),
                        backgroundColor: _AppStyle.cardBgSubtle,
                        labelStyle: textTheme.labelSmall,
                      ),
                      if (_selectedVisaType == 'student' ||
                          _selectedVisaType == 'work')
                        Chip(
                          label: Text(_strings.appFormDocsLetter),
                          backgroundColor: _AppStyle.cardBgSubtle,
                          labelStyle: textTheme.labelSmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.upload_file_rounded,
                        color: _AppStyle.secondaryAccent,
                      ),
                      label: Text(
                        _strings.appFormUploadDocsButton,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _AppStyle.secondaryAccent,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Document Upload Area - Not Implemented",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _AppStyle.secondaryAccent.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),

                  // --- Submit Button ---
                  const SizedBox(height: _AppStyle.sectionSpacing * 1.5),
                  Center(
                    child:
                        _isLoading
                            ? SpinKitFadingCube(
                              color: _AppStyle.secondaryAccent,
                              size: 40.0,
                            )
                            : ElevatedButton.icon(
                              icon: Icon(Icons.send_rounded, size: 18),
                              label: Text(_strings.appFormSubmitButton),
                              onPressed: _submitApplication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _AppStyle.primaryAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                textStyle: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Form Field Helper Widgets ---

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(
        top: _AppStyle.sectionSpacing,
        bottom: _AppStyle.vPadding * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: _AppStyle.secondaryAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(color: _AppStyle.cardBorder, height: 10, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String? hint,
    IconData? icon,
    FormFieldValidator<String>? validator, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _AppStyle.vPadding),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: _AppStyle.textColor), // Use theme later
        decoration: _inputDecoration(label, icon, hint: hint),
        validator: validator,
        maxLines: maxLines,
        keyboardType:
            maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    ValueChanged<DateTime> onDateSelected, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final DateFormat formatter = DateFormat(
      'yyyy-MM-dd',
      _strings.locale.languageCode,
    );
    final String displayDate =
        selectedDate == null ? '' : formatter.format(selectedDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: _AppStyle.vPadding),
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: displayDate,
        ), // Show formatted date
        style: TextStyle(color: _AppStyle.textColor),
        decoration: _inputDecoration(
          label,
          Icons.calendar_month_outlined,
        ).copyWith(
          hintText: 'YYYY-MM-DD', // Provide format hint
        ),
        onTap:
            () => _selectDate(
              context,
              onDateSelected,
              initialDate: selectedDate,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
        validator:
            (value) =>
                selectedDate == null
                    ? _strings.appFormErrorFieldRequired
                    : null, // Basic validation
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String hint,
    String? currentValue,
    List<MapEntry<String, String>> items,
    ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  ) {
    final textTheme = _strings.textTheme.apply(
      bodyColor: _AppStyle.textColor,
      displayColor: _AppStyle.textColor,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: _AppStyle.vPadding),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        items:
            items
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value, style: textTheme.bodyLarge),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: _inputDecoration(label, null, hint: hint).copyWith(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 12.0,
          ),
        ), // Adjust padding
        dropdownColor: _AppStyle.cardBg,
        style: textTheme.bodyLarge?.copyWith(color: _AppStyle.textColor),
        iconEnabledColor: _AppStyle.primaryAccent,
        isExpanded: true,
      ),
    );
  }

  Widget _buildRadioGroupField(
    String label,
    bool? groupValue,
    ValueChanged<bool?> onChanged,
    TextTheme textTheme, {
    required String yesText,
    required String noText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: _AppStyle.vPadding / 2,
      ), // Less vertical padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              color: _AppStyle.textColorMuted,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(yesText, style: textTheme.bodyMedium),
                  value: true,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: _AppStyle.primaryAccent,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(noText, style: textTheme.bodyMedium),
                  value: false,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: _AppStyle.primaryAccent,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          // Add validation feedback if needed (e.g., using FormField wrapper)
        ],
      ),
    );
  }

  // Helper for empty states in cards
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
                      ? _AppStyle.errorColor.withOpacity(0.6)
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
} // End of _VisaApplicationFormScreenState
