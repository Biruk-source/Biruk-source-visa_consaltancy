// lib/screens/visa_applications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for QuerySnapshot
import 'package:firebase_auth/firebase_auth.dart'
    hide UserProfile; // Needed for User

// Import project files
import '../services/firebase_service.dart';
import 'visa_application_detail_screen.dart';
import '../providers/locale_provider.dart';
import 'app_strings.dart';
import '../models/visa_application.dart';

// Constants defined locally for this screen
class _AppStyle {
  static const double cardRadius = 16.0;
  static const double hPadding = 18.0;
  static const double vPadding = 12.0;
  static const double sectionSpacing = 20.0; // Renamed from HomeScreenConstants
  static const Color primaryAccent = Color(0xFF26C6DA);
  static const Color secondaryAccent = Color(0xFFFFD54F);
  static const Color bgColorStart = Color(0xFF0A191E);
  static const Color bgColorEnd = Color(0xFF00333A);
  static const Color cardBg = Color(0xFF1F3035);
  static const Color cardBorder = Color(0xFF37474F);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color textColorMuted = Color(0xFF9E9E9E);
  static const Color successColor = Colors.greenAccent; // Adjusted name
  static const Color errorColor = Color(0xFFEF5350); // Adjusted name
  static const Color pendingColor = Color(0xFF42A5F5);
  // V V V V V V V V V V V V V V V V V V V V V V V V V V
  static const Color success =
      Colors.greenAccent; // Adjusted name <<<--- NAME IS successColor
  static const Color error = Color(0xFFEF5350);
}

class VisaApplicationsScreen extends StatefulWidget {
  const VisaApplicationsScreen({super.key});

  @override
  State<VisaApplicationsScreen> createState() => _VisaApplicationsScreenState();
}

// *** Add TickerProviderStateMixin ***
class _VisaApplicationsScreenState extends State<VisaApplicationsScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late AppStrings _strings;
  List<VisaApplication> _allApplications = [];
  List<VisaApplication> _filteredApplications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchTerm = '';
  String _selectedStatusFilter = 'all';
  String _selectedSort = 'newest';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // *** ADD Animation Controllers and Animations ***
  late AnimationController _staggerController;
  late AnimationController
  _buttonPulseController; // For button feedback if needed
  late Animation<double> _staggerAnimation;
  late Animation<double> _buttonPulseAnimation;

  @override
  void initState() {
    super.initState();
    // Strings initialized later
    _setupAnimations(); // Setup animations
    _fetchApplications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _strings = AppLocalizations.getStrings(localeProvider.locale);
  }

  // *** ADD Animation Setup ***
  void _setupAnimations() {
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    ); // Adjust duration
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 350),
    );
    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic),
    );
    _buttonPulseAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );
    // Don't start stagger yet
  }

  Future<void> _fetchApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = _firebaseService.getCurrentUser();
      if (user != null) {
        _allApplications = await _firebaseService.getUserApplications(user.uid);
        _applyFiltersAndSort(); // Apply initial filter/sort
        if (mounted)
          _staggerController.forward(from: 0.0); // Start animation after fetch
      } else {
        _allApplications = [];
        _filteredApplications = [];
        _errorMessage = "User not logged in."; // TODO: Localize
      }
    } catch (e) {
      debugPrint("Error fetching applications: $e");
      if (mounted) _errorMessage = _strings.applicationsErrorLoading;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFiltersAndSort() {
    List<VisaApplication> filtered = List.from(_allApplications);
    if (_searchTerm.isNotEmpty) {
      filtered =
          filtered.where((app) {
            final type = app.visaType.toLowerCase();
            final dest =
                (app.formData?['destinationCountry'] as String?)
                    ?.toLowerCase() ??
                '';
            final term = _searchTerm.toLowerCase();
            return type.contains(term) || dest.contains(term);
          }).toList();
    }
    if (_selectedStatusFilter != 'all') {
      filtered =
          filtered.where((app) {
            if (_selectedStatusFilter == 'pending')
              return [
                'submitted',
                'processing',
                'pending',
                'requires information',
                'on hold',
              ].contains(app.status.toLowerCase());
            return app.status.toLowerCase() == _selectedStatusFilter;
          }).toList();
    }
    if (_selectedSort == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    setState(() {
      _filteredApplications = filtered;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _staggerController.dispose(); // Dispose animations
    _buttonPulseController.dispose();
    super.dispose();
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
          _strings.applicationsTitle,
          style: textTheme.headlineSmall?.copyWith(
            color: _AppStyle.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _AppStyle.bgColorStart.withOpacity(0.85),
        elevation: 0,
        iconTheme: IconThemeData(color: _AppStyle.textColor),
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
            colors: [_AppStyle.bgColorStart, _AppStyle.bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterSortBar(textTheme),
              Expanded(
                child: _buildContent(textTheme),
              ), // Pass content to builder
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

  // --- Loading, Error, Empty States ---
  Widget _buildLoadingState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpinKitFadingCube(color: _AppStyle.secondaryAccent, size: 40.0),
          SizedBox(height: 16),
          Text(
            _strings.loading,
            style: textTheme.bodyMedium?.copyWith(
              color: _AppStyle.textColorMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TextTheme textTheme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: _AppStyle.errorColor,
              size: 50,
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: _AppStyle.textColorMuted,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchApplications,
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text(_strings.retryButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              color: _AppStyle.textColorMuted.withOpacity(0.5),
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              _strings.applicationsNoApplications,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: _AppStyle.textColorMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Filter/Sort Bar ---
  Widget _buildFilterSortBar(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _AppStyle.hPadding,
        12,
        _AppStyle.hPadding,
        12,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: textTheme.bodyMedium?.copyWith(color: _AppStyle.textColor),
            decoration: InputDecoration(
              hintText: _strings.applicationsSearchHint,
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: _AppStyle.textColorMuted,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _AppStyle.textColorMuted,
                size: 20,
              ),
              suffixIcon:
                  _searchTerm.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: _AppStyle.textColorMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                          _applyFiltersAndSort();
                        },
                      )
                      : null,
              filled: true,
              fillColor: _AppStyle.cardBg.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: _AppStyle.primaryAccent,
                  width: 1,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchTerm = value);
              _applyFiltersAndSort();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: _strings.applicationsFilterLabel,
                  value: _selectedStatusFilter,
                  items: {
                    'all': _strings.applicationsFilterAll,
                    'pending': _strings.applicationsFilterPending,
                    'approved': _strings.applicationsFilterApproved,
                    'rejected': _strings.applicationsFilterRejected,
                  },
                  onChanged: (val) {
                    if (val != null)
                      setState(() => _selectedStatusFilter = val);
                    _applyFiltersAndSort();
                  },
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: _strings.applicationsSortLabel,
                  value: _selectedSort,
                  items: {
                    'newest': _strings.applicationsSortNewest,
                    'oldest': _strings.applicationsSortOldest,
                  },
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSort = val);
                    _applyFiltersAndSort();
                  },
                  textTheme: textTheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
    required TextTheme textTheme,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value, style: textTheme.bodySmall),
                ),
              )
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.labelSmall?.copyWith(
          color: _AppStyle.textColorMuted,
        ),
        filled: true,
        fillColor: _AppStyle.cardBg.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      dropdownColor: _AppStyle.cardBg,
      style: textTheme.bodyMedium?.copyWith(color: _AppStyle.textColor),
      iconEnabledColor: _AppStyle.primaryAccent,
      focusColor: Colors.transparent,
    );
  }

  // --- Content Builder ---
  Widget _buildContent(TextTheme textTheme) {
    if (_isLoading) return _buildLoadingState(textTheme);
    if (_errorMessage != null)
      return _buildErrorState(textTheme, _errorMessage!);
    if (_filteredApplications.isEmpty) return _buildEmptyState(textTheme);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        bottom: 80,
        left: _AppStyle.hPadding,
        right: _AppStyle.hPadding,
        top: 8,
      ), // Added top padding
      itemCount: _filteredApplications.length,
      itemBuilder: (context, index) {
        final app = _filteredApplications[index];
        return _buildAnimatedListItem(
          index,
          _buildApplicationCard(app, textTheme),
        );
      },
    );
  }

  // --- Animated List Item Wrapper ---
  Widget _buildAnimatedListItem(int index, Widget child) {
    const totalDuration = 600;
    const delayPerItem = 60;
    final startDelay = (index * delayPerItem).clamp(0, totalDuration - 200);
    final endDelay = (startDelay + 300).clamp(startDelay, totalDuration);
    final interval = Interval(
      startDelay / totalDuration,
      endDelay / totalDuration,
      curve: Curves.easeOut,
    );
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, cardChild) {
        final animationValue = interval.transform(_staggerController.value);
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0.0, 20.0 * (1.0 - animationValue)),
            child: cardChild,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: _AppStyle.vPadding),
        child: child,
      ),
    );
  }

  // *** ADD THIS METHOD INSIDE _VisaApplicationsScreenState ***
  String _formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    String langCode = _strings.locale.languageCode; // Use _strings instance
    if (diff.inDays > 7)
      return DateFormat('MMM dd, yyyy', langCode).format(dateTime);
    if (diff.inDays >= 1)
      return '${diff.inDays}${langCode == 'am' ? 'ቀ' : 'd'} ago'; // Consider localizing 'ago' too
    if (diff.inHours >= 1)
      return '${diff.inHours}${langCode == 'am' ? 'ሰ' : 'h'} ago';
    if (diff.inMinutes >= 1)
      return '${diff.inMinutes}${langCode == 'am' ? 'ደ' : 'm'} ago';
    return langCode == 'am' ? 'አሁን' : 'Just now'; // Localized 'Just now'
  }

  // --- Application Card Widget ---
  Widget _buildApplicationCard(VisaApplication app, TextTheme textTheme) {
    final DateFormat formatter = DateFormat(
      'MMM dd, yyyy',
      _strings.locale.languageCode,
    );
    final String submittedDate = formatter.format(app.createdAt.toDate());
    final String? updatedDate =
        app.statusUpdatedAt != null
            ? _formatTimeAgo(app.statusUpdatedAt!.toDate())
            : null;

    return Card(
      elevation: 2.0,
      color: _AppStyle.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_AppStyle.cardRadius),
        side: BorderSide(color: _AppStyle.cardBorder.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print('Tapped: ${app.id}');
          // *** FIX: Navigate to Detail Screen ***
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => VisaApplicationDetailScreen(
                    applicationId: app.id,
                  ), // Pass ID
            ),
          );
        },
        splashColor: _AppStyle.primaryAccent.withOpacity(0.1),
        highlightColor: _AppStyle.primaryAccent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(_AppStyle.vPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _AppStyle.primaryAccent.withOpacity(0.15),
                    child: Icon(
                      _getVisaTypeIcon(app.visaType),
                      color: _AppStyle.primaryAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.visaType,
                          style: textTheme.titleMedium?.copyWith(
                            color: _AppStyle.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.formData?['destinationCountry'] ??
                              'Unknown Destination' /* TODO: Localize & use actual data */,
                          style: textTheme.bodySmall?.copyWith(
                            color: _AppStyle.textColorMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(app.status, textTheme),
                ],
              ),
              const Divider(
                color: _AppStyle.cardBorder,
                height: 24,
                thickness: 0.5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today_outlined,
                    '${_strings.homeStatusSubmitted}: $submittedDate',
                    textTheme,
                  ),
                  if (updatedDate != null)
                    _buildInfoChip(
                      Icons.update_outlined,
                      '${_strings.applicationsUpdatedAt.split(':')[0]}: $updatedDate',
                      textTheme,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildInfoChip(IconData icon, String text, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _AppStyle.textColorMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: _AppStyle.textColorMuted,
          ),
        ),
      ],
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
} // End of _VisaApplicationsScreenState
