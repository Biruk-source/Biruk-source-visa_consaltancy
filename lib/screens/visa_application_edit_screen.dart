// lib/screens/visa_application_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For Date Formatting

import '../models/visa_application.dart'; // Your application model
import '../services/firebase_service.dart'; // Your Firebase service
import '../providers/locale_provider.dart'; // Your locale provider
import 'app_strings.dart'; // Your localized strings

// --- Local Styles (Consistent with Detail Screen) ---
class _EditScreenStyle {
  static const Color primaryAccent = Color(0xFF26C6DA);
  static const Color secondaryAccent = Color(0xFFFFD54F);
  static const Color bgColorStart = Color(0xFF0A191E);
  static const Color bgColorEnd = Color(0xFF00333A);
  static const Color cardBg = Color(0xFF1F3035);
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xFF9E9E9E);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(
    0xFF66BB6A,
  ); // Use consistent naming if possible
}

class VisaApplicationEditScreen extends StatefulWidget {
  final VisaApplication application; // The application data to edit

  const VisaApplicationEditScreen({super.key, required this.application});

  @override
  State<VisaApplicationEditScreen> createState() =>
      _VisaApplicationEditScreenState();
}

class _VisaApplicationEditScreenState extends State<VisaApplicationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  // REMOVED: late AppStrings _strings; - Will get in build method
  bool _isLoading = false;

  // --- Text Editing Controllers ---
  late TextEditingController _visaTypeController;
  late TextEditingController _destinationController;
  late TextEditingController _stayDurationController;
  late TextEditingController _fullNameController;
  late TextEditingController _nationalityController;
  late TextEditingController _passportNumberController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;
  late TextEditingController _previousVisasDetailsController;
  late TextEditingController _denialDetailsController;
  late TextEditingController _purposeController;
  // Purpose-specific controllers
  late TextEditingController _studentUniversityController;
  late TextEditingController _studentCourseController;
  late TextEditingController _workEmployerController;
  late TextEditingController _workJobTitleController;
  late TextEditingController _touristItineraryController;

  // --- State for Non-Text Fields ---
  DateTime? _dob;
  DateTime? _entryDate;
  DateTime? _passportExpiry;
  bool? _hasPreviousVisits;
  bool? _hasVisaDenials;
  bool? _hasCriminalRecord;
  String? _fundingSource; // Stores the KEY ('self', 'sponsor', etc.)

  // Options will be populated in build using localized strings
  late List<MapEntry<String, String>> _visaTypesOptionsLocalized;
  late List<MapEntry<String, String>> _fundingSourceOptionsLocalized;

  @override
  void initState() {
    super.initState();
    _initializeControllersFromWidget();
    // Localized options requiring AppStrings will be initialized in build/didChange
  }

  // Initialize only controllers here
  void _initializeControllersFromWidget() {
    // Store the original key value from the database
    _visaTypeController = TextEditingController(
      text: widget.application.visaType,
    );

    // Initialize all other text controllers
    _destinationController = TextEditingController(
      text: widget.application.destinationCountry ?? '',
    );
    _stayDurationController = TextEditingController(
      text: widget.application.proposedStayDuration ?? '',
    );
    _fullNameController = TextEditingController(
      text: widget.application.fullName ?? '',
    );
    _nationalityController = TextEditingController(
      text: widget.application.nationality ?? '',
    );
    _passportNumberController = TextEditingController(
      text: widget.application.passportNumber ?? '',
    );
    _streetController = TextEditingController(
      text: widget.application.addressStreet ?? '',
    );
    _cityController = TextEditingController(
      text: widget.application.addressCity ?? '',
    );
    _stateController = TextEditingController(
      text: widget.application.addressState ?? '',
    );
    _zipController = TextEditingController(
      text: widget.application.addressZip ?? '',
    );
    _countryController = TextEditingController(
      text: widget.application.addressCountry ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.application.phoneNumber ?? '',
    );
    _previousVisasDetailsController = TextEditingController(
      text: widget.application.previousVisasDetails ?? '',
    );
    _denialDetailsController = TextEditingController(
      text: widget.application.denialDetails ?? '',
    );
    _purposeController = TextEditingController(
      text: widget.application.purposeOfVisit ?? '',
    );
    _studentUniversityController = TextEditingController(
      text: widget.application.studentUniversity ?? '',
    );
    _studentCourseController = TextEditingController(
      text: widget.application.studentCourse ?? '',
    );
    _workEmployerController = TextEditingController(
      text: widget.application.workEmployer ?? '',
    );
    _workJobTitleController = TextEditingController(
      text: widget.application.workJobTitle ?? '',
    );
    _touristItineraryController = TextEditingController(
      text: widget.application.touristItinerary ?? '',
    );

    // Initialize dates
    _dob = _parseDate(widget.application.dateOfBirth);
    _entryDate = _parseDate(widget.application.proposedEntryDate);
    _passportExpiry = _parseDate(widget.application.passportExpiryDate);

    // Initialize booleans and dropdown keys
    _hasPreviousVisits = widget.application.hasPreviousVisits;
    _hasVisaDenials = widget.application.hasVisaDenials;
    _hasCriminalRecord = widget.application.hasCriminalRecord;
    _fundingSource = widget.application.fundingSource; // Store the key
  }

  // Initialize dropdown options based on current locale's strings
  void _initializeLocalizedOptions(AppStrings strings) {
    _visaTypesOptionsLocalized = [
      MapEntry('student', strings.visaTypeStudent),
      MapEntry('work', strings.visaTypeWork),
      MapEntry('tourist', strings.visaTypeTourist),
      MapEntry(
        'family',
        strings.visaTypeOther,
      ), // Assuming 'Family Visa' uses 'other' key for now
      MapEntry('other', strings.visaTypeOther),
    ];
    _fundingSourceOptionsLocalized = [
      MapEntry('self', strings.appFormFundingSourceSelf),
      MapEntry('sponsor', strings.appFormFundingSourceSponsor),
      MapEntry('scholarship', strings.appFormFundingSourceScholarship),
      MapEntry('other', strings.appFormFundingSourceOther),
    ];

    // Check if the stored key for funding source is valid in the current options
    if (_fundingSource != null &&
        !_fundingSourceOptionsLocalized.any((e) => e.key == _fundingSource)) {
      debugPrint(
        "Warning: Stored funding source key '$_fundingSource' not found in localized options. Resetting selection.",
      );
      _fundingSource =
          null; // Reset if key becomes invalid (e.g., after locale change if keys differ)
    }
    // A similar check for visa type happens within the build method before rendering the dropdown
  }

  // Helper to safely parse date strings
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint("Error parsing date for edit screen: '$dateString' - $e");
      return null;
    }
  }

  @override
  void dispose() {
    // Dispose ALL controllers
    _visaTypeController.dispose();
    _destinationController.dispose();
    _stayDurationController.dispose();
    _fullNameController.dispose();
    _nationalityController.dispose();
    _passportNumberController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _previousVisasDetailsController.dispose();
    _denialDetailsController.dispose();
    _purposeController.dispose();
    _studentUniversityController.dispose();
    _studentCourseController.dispose();
    _workEmployerController.dispose();
    _workJobTitleController.dispose();
    _touristItineraryController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final AppStrings strings = AppLocalizations.getStrings(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );

    if (!_formKey.currentState!.validate()) {
      _showSnackbar(strings.formErrorCheckForm, strings, isError: true);
      return;
    }
    if (_isLoading || !mounted) return;
    setState(() => _isLoading = true);

    final user = _firebaseService.getCurrentUser();
    if (user == null) {
      _showSnackbar(
        strings.loginErrorGenericLoginFailed,
        strings,
        isError: true,
      );
      setState(() => _isLoading = false);
      return;
    }

    final Map<String, dynamic> dataToUpdate = {
      'visaType':
          _visaTypeController.text.trim(), // Save the key/selected value
      'destinationCountry': _destinationController.text.trim(),
      'proposedEntryDate': _entryDate?.toIso8601String(),
      'proposedStayDuration': _stayDurationController.text.trim(),
      'purposeOfVisit': _purposeController.text.trim(),
      'studentUniversity':
          _studentUniversityController.text.trim().isEmpty
              ? null
              : _studentUniversityController.text.trim(),
      'studentCourse':
          _studentCourseController.text.trim().isEmpty
              ? null
              : _studentCourseController.text.trim(),
      'workEmployer':
          _workEmployerController.text.trim().isEmpty
              ? null
              : _workEmployerController.text.trim(),
      'workJobTitle':
          _workJobTitleController.text.trim().isEmpty
              ? null
              : _workJobTitleController.text.trim(),
      'touristItinerary':
          _touristItineraryController.text.trim().isEmpty
              ? null
              : _touristItineraryController.text.trim(),
      'fullName': _fullNameController.text.trim(),
      'dateOfBirth': _dob?.toIso8601String(),
      'nationality': _nationalityController.text.trim(),
      'passportNumber': _passportNumberController.text.trim(),
      'passportExpiryDate': _passportExpiry?.toIso8601String(),
      'phoneNumber': _phoneController.text.trim(),
      'addressStreet': _streetController.text.trim(),
      'addressCity': _cityController.text.trim(),
      'addressState': _stateController.text.trim(),
      'addressZip': _zipController.text.trim(),
      'addressCountry': _countryController.text.trim(),
      'hasPreviousVisits': _hasPreviousVisits,
      'previousVisasDetails':
          _hasPreviousVisits == true
              ? _previousVisasDetailsController.text.trim()
              : null,
      'hasVisaDenials': _hasVisaDenials,
      'denialDetails':
          _hasVisaDenials == true ? _denialDetailsController.text.trim() : null,
      'fundingSource': _fundingSource, // Save the key
      'hasCriminalRecord': _hasCriminalRecord,
    };

    try {
      await _firebaseService.updateApplicationDetails(
        user.uid,
        widget.application.id!,
        dataToUpdate,
      );
      if (mounted) {
        _showSnackbar(strings.editAppSuccessMessage, strings);
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error saving application details: $e");
      if (mounted)
        _showSnackbar(strings.errorActionFailed, strings, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime) onDateSelected,
    AppStrings strings,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime(2101),
      locale: strings.locale, // Use locale from strings
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _EditScreenStyle.primaryAccent,
              onPrimary: Colors.black,
              surface: _EditScreenStyle.cardBg,
              onSurface: _EditScreenStyle.textColor,
            ),
            dialogBackgroundColor: _EditScreenStyle.bgColorEnd,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _EditScreenStyle.secondaryAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Get Provider and Strings using context.watch
    final localeProvider = context.watch<LocaleProvider>();
    final AppStrings strings = AppLocalizations.getStrings(
      localeProvider.locale,
    );
    // Initialize/Update localized options
    _initializeLocalizedOptions(strings);

    final textTheme = strings.textTheme.apply(
      bodyColor: _EditScreenStyle.textColor,
      displayColor: _EditScreenStyle.textColor,
    );

    // Ensure dropdown value is valid *before* building the dropdown
    String? currentValidVisaType =
        _visaTypesOptionsLocalized.any(
              (entry) =>
                  entry.key == _visaTypeController.text ||
                  entry.value == _visaTypeController.text,
            ) // Check key OR value for flexibility
            ? _visaTypeController
                .text // Keep original value if valid
            : null; // Set to null if current controller text isn't a valid option key/value

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.editAppTitle,
          style: textTheme.titleLarge,
        ), // Use strings
        backgroundColor: _EditScreenStyle.bgColorStart,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.5),
        iconTheme: IconThemeData(color: _EditScreenStyle.textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: strings.editAppSaveChangesButton, // Use strings
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _EditScreenStyle.bgColorStart,
                  _EditScreenStyle.bgColorEnd,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Use strings for all labels, hints, errors etc. ---
                  _buildSectionHeader(
                    textTheme,
                    strings.appFormSectionVisaDetails,
                  ),
                  _buildDropdownField<String>(
                    label: strings.appFormVisaTypeLabel,
                    icon: Icons.category_outlined,
                    value: currentValidVisaType, // Use validated key/value
                    items:
                        _visaTypesOptionsLocalized
                            .map(
                              (entry) => DropdownMenuItem(
                                value:
                                    entry
                                        .key, // VALUE IS THE KEY ('student', 'work')
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: _EditScreenStyle.textColor,
                                  ),
                                ), // DISPLAY IS LOCALIZED TEXT
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      // On change, update controller with the KEY
                      if (value != null)
                        setState(() => _visaTypeController.text = value);
                    },
                    validator:
                        (v) =>
                            (v == null || v.isEmpty)
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _destinationController,
                    label: strings.appFormDestinationLabel,
                    icon: Icons.flag_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildDateField(
                    context: context,
                    label: strings.appFormEntryDateLabel,
                    selectedDate: _entryDate,
                    onTap:
                        () => _selectDate(
                          context,
                          _entryDate,
                          (date) => setState(() => _entryDate = date),
                          strings,
                        ),
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _stayDurationController,
                    label: strings.appFormStayDurationLabel,
                    icon: Icons.timelapse_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _purposeController,
                    label: strings.appFormPurposeLabel,
                    icon: Icons.info_outline,
                    maxLines: 3,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorPurposeRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _studentUniversityController,
                    label: strings.appFormStudentUniversityLabel,
                    icon: Icons.school_outlined,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _studentCourseController,
                    label: strings.appFormStudentCourseLabel,
                    icon: Icons.book_outlined,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _workEmployerController,
                    label: strings.appFormWorkEmployerLabel,
                    icon: Icons.business_center_outlined,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _workJobTitleController,
                    label: strings.appFormWorkJobTitleLabel,
                    icon: Icons.badge_outlined,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _touristItineraryController,
                    label: strings.appFormTouristItineraryLabel,
                    icon: Icons.map_outlined,
                    maxLines: 3,
                    strings: strings,
                  ),

                  _buildSectionDivider(),

                  _buildSectionHeader(
                    textTheme,
                    strings.appFormSectionPersonalInfo,
                  ),
                  _buildTextField(
                    controller: _fullNameController,
                    label: strings.appFormFullNameLabel,
                    icon: Icons.badge_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildDateField(
                    context: context,
                    label: strings.appFormDOBLabel,
                    selectedDate: _dob,
                    onTap:
                        () => _selectDate(
                          context,
                          _dob,
                          (date) => setState(() => _dob = date),
                          strings,
                        ),
                    validator:
                        (d) =>
                            d == null
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _nationalityController,
                    label: strings.appFormNationalityLabel,
                    icon: Icons.public_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _passportNumberController,
                    label: strings.appFormPassportNumberLabel,
                    icon: Icons.contact_mail_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildDateField(
                    context: context,
                    label: strings.appFormPassportExpiryLabel,
                    selectedDate: _passportExpiry,
                    onTap:
                        () => _selectDate(
                          context,
                          _passportExpiry,
                          (date) => setState(() => _passportExpiry = date),
                          strings,
                        ),
                    validator:
                        (d) =>
                            d == null
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),

                  _buildSectionDivider(),

                  _buildSectionHeader(
                    textTheme,
                    strings.appFormSectionContactAddress,
                  ),
                  _buildTextField(
                    controller: _phoneController,
                    label: strings.appFormPhoneNumberLabel,
                    icon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.signupErrorPhoneRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _streetController,
                    label: strings.appFormAddressStreetLabel,
                    icon: Icons.home_work_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _cityController,
                    label: strings.appFormAddressCityLabel,
                    icon: Icons.location_city_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _stateController,
                    label: strings.appFormAddressStateLabel,
                    icon: Icons.map,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _zipController,
                    label: strings.appFormAddressZipLabel,
                    icon: Icons.markunread_mailbox_outlined,
                    keyboardType: TextInputType.number,
                    strings: strings,
                  ),
                  _buildTextField(
                    controller: _countryController,
                    label: strings.appFormAddressCountryLabel,
                    icon: Icons.map_outlined,
                    validator:
                        (v) =>
                            v!.isEmpty
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),

                  _buildSectionDivider(),

                  _buildSectionHeader(
                    textTheme,
                    strings.appFormSectionTravelHistory,
                  ),
                  _buildSwitchField(
                    label: strings.appFormPreviousVisitsLabel,
                    value: _hasPreviousVisits ?? false,
                    onChanged:
                        (value) => setState(() => _hasPreviousVisits = value),
                    strings: strings,
                  ),
                  if (_hasPreviousVisits == true)
                    _buildTextField(
                      controller: _previousVisasDetailsController,
                      label: strings.appFormPreviousVisasLabel,
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      validator:
                          (v) =>
                              (_hasPreviousVisits == true && v!.isEmpty)
                                  ? strings.appFormErrorFieldRequired
                                  : null,
                      strings: strings,
                    ),
                  _buildSwitchField(
                    label: strings.appFormVisaDenialsLabel,
                    value: _hasVisaDenials ?? false,
                    onChanged:
                        (value) => setState(() => _hasVisaDenials = value),
                    strings: strings,
                  ),
                  if (_hasVisaDenials == true)
                    _buildTextField(
                      controller: _denialDetailsController,
                      label: strings.appFormDenialDetailsLabel,
                      icon: Icons.gavel_outlined,
                      maxLines: 3,
                      validator:
                          (v) =>
                              (_hasVisaDenials == true && v!.isEmpty)
                                  ? strings.appFormErrorFieldRequired
                                  : null,
                      strings: strings,
                    ),

                  _buildSectionDivider(),

                  _buildSectionHeader(
                    textTheme,
                    strings.appFormSectionFinancials,
                  ),
                  _buildDropdownField<String>(
                    label: strings.appFormFundingSourceLabel,
                    icon: Icons.account_balance_wallet_outlined,
                    value: _fundingSource, // Use the key stored in state
                    items:
                        _fundingSourceOptionsLocalized
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key, // VALUE is the key
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: _EditScreenStyle.textColor,
                                  ),
                                ), // DISPLAY is localized text
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(
                          () => _fundingSource = value,
                        ), // Store the selected key
                    validator:
                        (v) =>
                            (v == null || v.isEmpty)
                                ? strings.appFormErrorFieldRequired
                                : null,
                    strings: strings,
                  ),

                  _buildSectionDivider(),

                  _buildSectionHeader(
                    textTheme,
                    strings.appFormSectionBackground,
                  ),
                  _buildSwitchField(
                    label: strings.appFormCriminalRecordLabel,
                    value: _hasCriminalRecord ?? false,
                    onChanged:
                        (value) => setState(() => _hasCriminalRecord = value),
                    strings: strings,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: SpinKitFadingCube(
                  color: _EditScreenStyle.secondaryAccent,
                  size: 50.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Fully Implemented Helper Widgets ---

  Widget _buildTextField({
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
              enabled
                  ? _EditScreenStyle.textColor
                  : _EditScreenStyle.textColorMuted,
        ),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _EditScreenStyle.textColorMuted),
          hintText: label,
          hintStyle: TextStyle(
            color: _EditScreenStyle.textColorMuted.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: _EditScreenStyle.primaryAccent,
            size: 20,
          ),
          filled: true,
          fillColor:
              enabled
                  ? _EditScreenStyle.cardBg.withOpacity(0.7)
                  : Colors.grey.shade800.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _EditScreenStyle.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _EditScreenStyle.cardBorder.withOpacity(0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _EditScreenStyle.primaryAccent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _EditScreenStyle.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _EditScreenStyle.errorColor,
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            color: _EditScreenStyle.errorColor.withOpacity(0.9),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: maxLines > 1 ? 16 : 12,
            horizontal: 12,
          ),
        ),
        validator: enabled ? validator : null,
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required AppStrings strings,
    String? Function(DateTime?)? validator,
    bool enabled = true,
  }) {
    final DateFormat formatter = DateFormat(
      'MMMM dd, yyyy',
      strings.locale.languageCode,
    );
    final String displayDate =
        selectedDate != null
            ? formatter.format(selectedDate)
            : strings.editAppSelectDateHint; // Use localized hint

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FormField<DateTime>(
        initialValue: selectedDate,
        validator: enabled ? validator : null,
        enabled: enabled,
        builder: (formFieldState) {
          return InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: _EditScreenStyle.textColorMuted),
                prefixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: _EditScreenStyle.primaryAccent,
                  size: 20,
                ),
                filled: true,
                fillColor:
                    enabled
                        ? _EditScreenStyle.cardBg.withOpacity(0.7)
                        : Colors.grey.shade800.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _EditScreenStyle.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _EditScreenStyle.cardBorder.withOpacity(0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _EditScreenStyle.primaryAccent,
                    width: 1.5,
                  ),
                ),
                errorText: formFieldState.errorText,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _EditScreenStyle.errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _EditScreenStyle.errorColor,
                    width: 1.5,
                  ),
                ),
                errorStyle: TextStyle(
                  color: _EditScreenStyle.errorColor.withOpacity(0.9),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 12,
                ),
              ),
              child: Text(
                displayDate,
                style: TextStyle(
                  color:
                      enabled
                          ? (selectedDate != null
                              ? _EditScreenStyle.textColor
                              : _EditScreenStyle.textColorMuted)
                          : _EditScreenStyle.textColorMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required AppStrings strings,
    String? Function(T?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: enabled ? validator : null,
        dropdownColor: _EditScreenStyle.cardBg,
        style: TextStyle(color: _EditScreenStyle.textColor),
        iconEnabledColor:
            enabled
                ? _EditScreenStyle.primaryAccent
                : _EditScreenStyle.textColorMuted,
        iconDisabledColor: _EditScreenStyle.textColorMuted,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _EditScreenStyle.textColorMuted),
          prefixIcon: Icon(
            icon,
            color: _EditScreenStyle.primaryAccent,
            size: 20,
          ),
          filled: true,
          fillColor:
              enabled
                  ? _EditScreenStyle.cardBg.withOpacity(0.7)
                  : Colors.grey.shade800.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _EditScreenStyle.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _EditScreenStyle.cardBorder.withOpacity(0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _EditScreenStyle.primaryAccent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _EditScreenStyle.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _EditScreenStyle.errorColor,
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            color: _EditScreenStyle.errorColor.withOpacity(0.9),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppStrings strings,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SwitchListTile.adaptive(
        title: Text(
          label,
          style: TextStyle(
            color:
                enabled
                    ? _EditScreenStyle.textColor
                    : _EditScreenStyle.textColorMuted,
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: _EditScreenStyle.secondaryAccent,
        inactiveTrackColor: Colors.grey.shade700,
        inactiveThumbColor: Colors.grey.shade400,
        tileColor: _EditScreenStyle.cardBg.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildSectionHeader(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Text(
        title.toUpperCase(),
        style: textTheme.titleMedium?.copyWith(
          color: _EditScreenStyle.secondaryAccent,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8, // Added letter spacing
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        color: _EditScreenStyle.cardBorder,
        thickness: 1,
        height: 1,
      ),
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
                ? _EditScreenStyle.errorColor
                : _EditScreenStyle.successColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  // Included for completeness, though only _showSnackbar is used above
  void _showSuccessSnackbar(String message, AppStrings strings) {
    _showSnackbar(message, strings, isError: false);
  }
} // End State
