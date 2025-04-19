// lib/app_strings.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart'; // Ensure this path is correct

// --- Abstract Class for All Strings ---
// Defines the contract for all localizations
abstract class AppStrings {
  Locale get locale;
  TextTheme get textTheme;

  // --- General ---
  String get highContrastTooltip;
  String get darkModeTooltip;
  String get languageToggleTooltip;
  String get errorInitializationFailed;
  String get errorCouldNotSavePrefs;
  String get errorConnectivityCheck;
  String get errorActionFailed;
  String get errorCouldNotLaunchUrl;
  String get errorCouldNotLaunchDialer;
  String get successPrefsSaved;
  String get successSubscription;
  String get connectionRestored;
  String get noInternet;
  String get retryButton;
  String get errorGeneric;
  String get loading;
  String get generalCancel;
  String get generalLogout;

  // --- Login Screen ---
  String get loginWelcomeTitle;
  String get loginWelcomeSubtitle;
  String get loginEmailLabel;
  String get loginPasswordLabel;
  String get loginForgotPasswordButton;
  String get loginSignInButton;
  String get loginOrDivider;
  String get loginSignInWithGoogleButton;
  String get loginSignUpPrompt;
  String get loginSignUpButton;
  String get loginErrorEmailRequired;
  String get loginErrorEmailInvalid;
  String get loginErrorPasswordRequired;
  String get loginErrorPasswordMinLength;
  String get loginErrorForgotPasswordEmailPrompt;
  String get loginSuccessPasswordResetSent;
  String get loginErrorGenericLoginFailed;
  String get loginErrorInvalidCredentials;

  // --- Sign Up Screen ---
  String get signupCreateAccountTitle;
  String get signupCreateAccountSubtitle;
  String get signupUsernameLabel;
  String get signupEmailLabel;
  String get signupPasswordLabel;
  String get signupPhoneNumberLabel;
  String get signupReferralCodeLabel;
  String get signupCreateAccountButton;
  String get signupLoginPrompt;
  String get signupLoginButton;
  String get signupErrorUsernameRequired;
  String get signupErrorUsernameMinLength;
  String get signupErrorEmailRequired;
  String get signupErrorEmailInvalid;
  String get signupErrorPasswordRequired;
  String get signupErrorPasswordMinLength;
  String get signupErrorPhoneRequired;
  String get signupErrorPhoneInvalid;
  String get signupErrorGenericSignupFailed;
  String get signupErrorEmailInUse;
  String get signupErrorWeakPassword;
  String get formErrorCheckForm; // Also used in other forms
  String get formErrorRequired; // Also used in other forms
  String get formErrorInvalidEmail; // Also used in other forms

  // --- HomeScreen ---
  String get homeDashboardTitle;
  String get homeWelcomeGeneric;
  String get homeWelcomeUser; // %s placeholder optional
  String get homeWelcomeSubtitle;
  String get homeVisaProgressTitle;
  String get homeRecentApplicationsTitle;
  String get homeNotificationsTitle;
  String get homeRecommendationsTitle;
  String get homeProfileOverviewTitle;
  String get homeActionViewDetails;
  String get homeActionUpdateStatus;
  String get homeActionViewAll;
  String get homeActionExploreMore;
  String get homeActionEditProfile;
  String get homeActionSecurity;
  String get homeStatusApproved;
  String get homeStatusPending;
  String get homeStatusRejected;
  String get homeStatusSubmitted;
  String get homeStatusProcessing;
  String get homeStatusUnknown;
  String get statusRequiresInfo;
  String get statusOnHold;
  String get homeAppsChartLegendApproved;
  String get homeAppsChartLegendPending;
  String get homeAppsChartLegendRejected;
  String get homeAppsChartNoApps;
  String get homeNotificationsNone;
  String get homeNotificationsError;
  String get homeRecommendationsSubtext;
  String get homeProfileLabelUsername;
  String get homeProfileLabelEmail;
  String get homeProfileLabelPhone;
  String get homeProfileValueNotSet;
  String get sidebarTitle;
  String get sidebarDashboard;
  String get sidebarProfile;
  String get homeAboutUs;
  String get sidebarSettings;
  String get sidebarLogout;
  String get tooltipMenu;
  String get tooltipMarkAllRead;
  String get tooltipViewProfile;
  String get homeAdditionalStatsTitle;
  String get homeAdditionalStatsAvgProcessing;
  String get homeAdditionalStatsSuccessRate;
  String get homeAdditionalStatsDisclaimer;
  String get homeQuickActionsTitle;
  String get homeQuickActionNewApp;
  String get homeQuickActionMyDocs;
  String get homeQuickActionBookMeeting;
  String get homeQuickActionSupport;
  String get homeQuickActionUpload;
  String get homeQuickActionMyProfile;
  String get homeRecommendationsTitleCard;
  String get homeRecommendationsSubtextCard;
  String get homeActionSeeDetails;
  String get homeProfileTitleCard;
  String get homeActionFullProfile;

  // --- Application Form Screen ---
  String get appFormTitle;
  String get appFormSectionVisaDetails;
  String get appFormSectionPersonalInfo;
  String get appFormSectionContactAddress;
  String get appFormSectionTravelHistory;
  String get appFormSectionPurposeDetails;
  String get appFormSectionFinancials;
  String get appFormSectionBackground;
  String get appFormSectionDocuments;
  String get appFormVisaTypeLabel;
  String get appFormVisaTypeHint;
  String get appFormDestinationLabel;
  String get appFormDestinationHint;
  String get appFormEntryDateLabel;
  String get appFormEntryDateHint;
  String get appFormStayDurationLabel;
  String get appFormStayDurationHint;
  String get appFormFullNameLabel;
  String get appFormFullNameHint;
  String get appFormDOBLabel;
  String get appFormDOBHint;
  String get appFormNationalityLabel;
  String get appFormNationalityHint;
  String get appFormPassportNumberLabel;
  String get appFormPassportNumberHint;
  String get appFormPassportExpiryLabel;
  String get appFormPassportExpiryHint;
  String get appFormAddressStreetLabel;
  String get appFormAddressStreetHint;
  String get appFormAddressCityLabel;
  String get appFormAddressCityHint;
  String get appFormAddressStateLabel;
  String get appFormAddressStateHint;
  String get appFormAddressZipLabel;
  String get appFormAddressZipHint;
  String get appFormAddressCountryLabel;
  String get appFormAddressCountryHint;
  String get appFormPhoneNumberLabel; // Reuses signup key
  String get appFormPhoneNumberHint;
  String get appFormPreviousVisitsLabel;
  String get appFormPreviousVisitsYes;
  String get appFormPreviousVisitsNo;
  String get appFormPreviousVisasLabel;
  String get appFormPreviousVisasHint;
  String get appFormVisaDenialsLabel;
  String get appFormVisaDenialsYes;
  String get appFormVisaDenialsNo;
  String get appFormDenialDetailsLabel;
  String get appFormDenialDetailsHint;
  String get appFormStudentUniversityLabel;
  String get appFormStudentCourseLabel;
  String get appFormWorkEmployerLabel;
  String get appFormWorkJobTitleLabel;
  String get appFormTouristItineraryLabel;
  String get appFormPurposeLabel;
  String get appFormPurposeHint;
  String get appFormFundingSourceLabel;
  String get appFormFundingSourceHint;
  String get appFormFundingSourceSelf;
  String get appFormFundingSourceSponsor;
  String get appFormFundingSourceScholarship;
  String get appFormFundingSourceOther;
  String get appFormCriminalRecordLabel;
  String get appFormCriminalRecordYes;
  String get appFormCriminalRecordNo;
  String get appFormSecurityQuestionLabel;
  String get appFormSecurityQuestionYes;
  String get appFormSecurityQuestionNo;
  String get appFormDocsInstruction;
  String get appFormDocsPassport;
  String get appFormDocsPhoto;
  String get appFormDocsFinancials;
  String get appFormDocsLetter;
  String get appFormUploadDocsButton;
  String get appFormSubmitButton;
  String get appFormErrorVisaTypeRequired;
  String get appFormErrorDestinationRequired;
  String get appFormErrorPurposeRequired;
  String get appFormErrorFieldRequired;
  String get appFormErrorInvalidDate;
  String get appFormErrorInvalidPassport;
  String get appFormSuccessMessage;
  String get appFormFailureMessage;

  // --- Recommendation Screen ---
  String get recScreenTitle;
  String get recPersonalizedTitle;
  String get recPersonalizedSubtext;
  String get recPersonalizedActionUpdateProfile;
  String get recInfoEligibility;
  String get recInfoDocuments;
  String get recInfoProcessingTime;
  String get recInfoFees;
  String get recInfoValidity;
  String get recInfoApplyButton;
  String get recInfoNoData;

  // --- Visa Types ---
  String get visaTypeStudent;
  String get visaTypeWork;
  String get visaTypeTourist;
  String get visaTypeOther;
  String get visaTypeF1;
  String get visaTypeH1B;
  String get visaTypeB1B2;

  // --- Welcome Screen & Other Sections ---
  String get heroHeadline;
  String get heroSubheadline;
  String get bookConsultationButton;
  String get statsInterviewsConductedLabel;
  String get statsLanguagesSpokenLabel;
  String get statsConsulatesLabel;
  String get expertiseCard1Title;
  String get expertiseCard1Desc;
  String get expertiseCard2Title;
  String get expertiseCard2Desc;
  String get expertiseCard3Title;
  String get expertiseCard3Desc;
  String get teamHeadline;
  String get teamDescription;
  String get meetOfficersButton;
  String get servicesHeadline;
  String get servicesSubheadline;
  String get servicesNivTitle;
  String get servicesIvTitle;
  List<String> get nivVisaTypes;
  List<String> get ivVisaTypes;
  String get reachHeadline;
  String get reachDescription;
  String get reachImagePlaceholder;
  String get situationsHeadline;
  List<String> get situationList;
  String get situationsContactPrompt;
  String get learnMoreServicesLink;
  String get leadMagnetHeadline;
  String get leadMagnetDescription;
  String get downloadFreeButton;
  String get testimonialsHeadline;
  List<Map<String, String>> get testimonials;
  String get anonymous;
  String get googleReviewSource;
  String get languagesHeadline;
  String get languagesDescription;
  String get learnMoreButton;
  String get newsletterHeadline;
  String get newsletterFirstNameLabel;
  String get newsletterEmailLabel;
  String get newsletterPhoneLabel;
  String get newsletterPhoneOptionalLabel;
  String get newsletterDisclaimer;
  String get subscribeButton;
  // formErrorRequired, formErrorInvalidEmail, formErrorCheckForm defined above
  String get finalCtaHeadline;
  String get finalCtaSubheadline;
  String get getStartedButton;
  String get goToDashboardButton;
  String get footerStatCountries;
  String get footerStatApplicants;
  String get footerStatRecommendation;
  String get footerLogoAltText;

  // --- for detial screen ---
  // --- Keys to ADD/VERIFY in abstract class AppStrings ---
  String get applicationsTitle;
  String get applicationsErrorLoading;
  String get applicationsNoApplications;
  String get applicationsSearchHint;
  String get applicationsFilterLabel;
  String get applicationsFilterAll;
  String get applicationsFilterPending;
  String get applicationsFilterApproved;
  String get applicationsFilterRejected;
  String get applicationsSortLabel;
  String get applicationsSortNewest;
  String get applicationsSortOldest;
  String get applicationsSubmittedOn; // Used in tile
  String get applicationsUpdatedAt; // Used in tile
  String get applicationsViewDetailsAction;
  String get notificationsTitle;
  String get notificationsMarkAllReadTooltip;
  String get notificationsMarkAllReadSuccess;
  String get notificationsMarkAllReadError;
  String get notificationsEmpty;
  String get notificationsError; // Optional for button text

  // --- Keys for the new Details Screen ---
  String get appDetailsTitle;
  String get appDetailsErrorNotFound;
  String get appDetailsStatusHistory;
  String get appDetailsCurrentStatus;
  String get appDetailsSubmitted; // e.g., Submitted
  String get appDetailsLastUpdate; // e.g., Last Update
  String get appDetailsInfoSection; // e.g., Application Information
  String get appDetailsNoData; // e.g., No details available
  // Add keys for labels matching your form fields if you want to display them
  String get appDetailVisaType; // e.g. "Visa Type"
  String get appDetailDestination; // e.g. "Destination"
  String get appDetailFullName; // e.g. "Full Name"
  String get appDetailDOB; // e.g. "Date of Birth"
  String get appDetailNationality; // e.g. "Nationality"
  String get appDetailPassportNo; // e.g. "Passport No."
  String get appDetailPhone; // e.g. "Phone"
  String get appDetailPurpose; // e.g. "Purpose"
  // Add more keys as needed...
  // --- Logout Dialog ---
  String get logoutConfirmTitle; // Defined above
  String get logoutConfirmContent; // Defined above
  // --- ** NEW: Settings Screen Strings ** --- // Add this section header
  String get settingsProfileSection;
  String get settingsEditProfile;
  String get settingsPreferencesSection;
  String get settingsNotificationsPref;
  String get settingsAccountSection;
  String get settingsChangePassword;
  String get settingsLogoutAction; // Specific string for the action tile
  String get settingsDeleteAccountAction; // Specific string for the action tile
  String get settingsSupportSection;
  String get settingsHelpCenter;
  String get settingsPrivacyPolicy;
  String get settingsTerms;
  String get settingsAbout;
  String
  get settingsAboutDialogTitle; // Usually handled by showAboutDialog's 'applicationName'
  String get settingsAboutDialogContent; // Content for the About dialog
  String get settingsErrorProfileNotFound;
  String get settingsErrorCannotSendReset;
  String get settingsErrorFailedToSendReset;
  String get settingsErrorReauthRequired; // Placeholder for re-auth message
  String get settingsErrorRequiresRecentLogin; // Specific Firebase error
  String get settingsErrorDeleteFailed;
  String get settingsSuccessPreferenceSaved;
  String get settingsSuccessAccountDeleted;
  String get settingsDeleteConfirmTitle;
  String get settingsDeleteConfirmContent;
  String get appName;
  String get settingsDeleteConfirmAction;
  String get settingsDeleteConfirmTitle2;
  String get settingsDeleteConfirmInputPrompt; // If using input confirmation
  String get settingsDeleteConfirmActionFinal;
  // --- ** NEW: Edit Screen Strings ** --- // Add this section header
  String get editAppTitle; // Title for the edit screen AppBar
  String get editAppSaveChangesButton; // Tooltip/Text for the Save button
  String get editAppSuccessMessage; // Snackbar message on successful update
  String get editAppSelectDateHint;
  // --- ADD TO abstract class AppStrings ---

  // --- ** NEW: Profile Screen Strings ** ---
  String get profileTitle; // AppBar Title
  String get profileOverviewTab;
  String get profileSettingsTab; // Reuses sidebarSettings maybe?
  String get profileStatisticsTab;
  String get profileActivityTab;
  String get profileErrorLoading;
  String get profileEditButton;
  String get profilePhoneLabel; // Specific label for profile overview
  String get profileBioLabel; // If you add a bio display
  String get profilePreferencesTitle;
  String get profileNoPreferencesSet;
  String get profileStatsTitle;
  String get profileStatsTotalApps; // e.g., "Visa Applications ({total} Total)"
  String get profileStatsNoAppsYet;
  String get profileActivityTitle; // Maybe reuse homeNotificationsTitle?
  String get profileActivityErrorLoading;
  String get profileActivityNoActivity;
  String get profileActivityActionLogin;
  String get profileActivityActionCreated;
  String get profileActivityActionUpdate;
  String get profileActivityActionEdited;
  String get profileActivityActionApplication;
  String get profileActivityActionNotification;
  String get profileActivityActionLogout;
  String get profileActivityActionDelete;
  String get profileActivityActionUnknown;
  String
  get profileActivityTimeAgo; // Format string for time ago, e.g., "%s ago"
  String get profileActivityJustNow;
  // --- ** END NEW PROFILE STRINGS ** ---
}

// --- English Implementation ---
class AppStringsEn implements AppStrings {
  @override
  Locale get locale => const Locale('en');
  @override
  TextTheme get textTheme => GoogleFonts.poppinsTextTheme();

  // General  // --- ** NEW: Edit Screen Strings (English) ** --- // Add this section header
  @override
  String get editAppTitle => "Edit Application";
  @override
  String get editAppSaveChangesButton => "Save Changes";
  @override
  String get editAppSuccessMessage => "Application updated successfully!";
  @override
  String get editAppSelectDateHint => "Select Date";
  // --- ** END NEW EDIT SCREEN STRINGS (English) ** ---
  @override
  String get highContrastTooltip => "High Contrast";
  @override
  String get darkModeTooltip => "Dark Mode";
  @override
  String get languageToggleTooltip => "Switch Language (ቋንቋ ቀይር)";
  @override
  String get errorInitializationFailed => "Initialization failed";
  @override
  String get errorCouldNotSavePrefs => "Could not save preferences";
  @override
  String get errorConnectivityCheck => "Could not check connectivity";
  @override
  String get errorActionFailed => "Action failed. Please try again.";
  @override
  String get errorCouldNotLaunchUrl => "Could not launch URL.";
  @override
  String get errorCouldNotLaunchDialer => "Could not launch dialer.";
  @override
  String get successPrefsSaved => "Preference saved.";
  @override
  String get successSubscription => "Thank you for subscribing!";
  @override
  String get connectionRestored => "Internet connection restored.";
  @override
  String get noInternet => "No internet connection.";
  @override
  String get retryButton => "Retry";
  @override
  String get errorGeneric => "An error occurred. Please try again.";
  @override
  String get loading => "Loading...";
  @override
  String get generalCancel => "Cancel";
  @override
  String get generalLogout => "Logout";

  // Login
  @override
  String get loginWelcomeTitle => "Welcome Back";
  @override
  String get loginWelcomeSubtitle => "Sign in to access your dashboard";
  @override
  String get loginEmailLabel => "Email Address";
  @override
  String get loginPasswordLabel => "Password";
  @override
  String get loginForgotPasswordButton => "Forgot Password?";
  @override
  String get loginSignInButton => "Sign In";
  @override
  String get loginOrDivider => "OR";
  @override
  String get loginSignInWithGoogleButton => "Sign In with Google";
  @override
  String get loginSignUpPrompt => "Don't have an account? ";
  @override
  String get loginSignUpButton => "Sign Up";
  @override
  String get loginErrorEmailRequired => 'Email is required.';
  @override
  String get loginErrorEmailInvalid => 'Enter a valid email address.';
  @override
  String get loginErrorPasswordRequired => 'Password is required.';
  @override
  String get loginErrorPasswordMinLength =>
      'Password must be at least 6 characters.';
  @override
  String get loginErrorForgotPasswordEmailPrompt =>
      'Please enter your email address first.';
  @override
  String get loginSuccessPasswordResetSent =>
      'Password reset email sent. Please check your inbox.';
  @override
  String get loginErrorGenericLoginFailed =>
      'Login failed. Please check your details or connection.';
  @override
  String get loginErrorInvalidCredentials => 'Incorrect email or password.';

  // Sign Up
  @override
  String get signupCreateAccountTitle => "Create Account";
  @override
  String get signupCreateAccountSubtitle => "Start your journey with us";
  @override
  String get signupUsernameLabel => "Choose a Username";
  @override
  String get signupEmailLabel => "Email Address";
  @override
  String get signupPasswordLabel => "Create Password";
  @override
  String get signupPhoneNumberLabel => "Phone Number";
  @override
  String get signupReferralCodeLabel => "Referral Code (Optional)";
  @override
  String get signupCreateAccountButton => "Create Account";
  @override
  String get signupLoginPrompt => "Already have an account? ";
  @override
  String get signupLoginButton => "Sign In";
  @override
  String get signupErrorUsernameRequired => 'Username is required.';
  @override
  String get signupErrorUsernameMinLength =>
      'Username must be at least 3 characters.';
  @override
  String get signupErrorEmailRequired => 'Email is required.';
  @override
  String get signupErrorEmailInvalid => 'Enter a valid email address.';
  @override
  String get signupErrorPasswordRequired => 'Password is required.';
  @override
  String get signupErrorPasswordMinLength =>
      'Password must be at least 6 characters.';
  @override
  String get signupErrorPhoneRequired => 'Phone number is required.';
  @override
  String get signupErrorPhoneInvalid =>
      'Enter a valid phone number (e.g., +1...).';
  @override
  String get signupErrorGenericSignupFailed =>
      'Sign up failed. Please try again.';
  @override
  String get signupErrorEmailInUse =>
      'This email address is already registered.';
  @override
  String get signupErrorWeakPassword => 'Password is too weak.';
  @override
  String get formErrorCheckForm => "Please check the form for errors.";
  @override
  String get formErrorRequired => "Required";
  @override
  String get formErrorInvalidEmail => "Invalid Email";
  @override
  String get appFormErrorFieldRequired => "This field is required.";
  @override
  String get appFormErrorInvalidDate => "Please enter a valid date.";
  @override
  String get appFormErrorInvalidPassport => "Invalid passport number format.";

  // HomeScreen
  @override
  String get homeDashboardTitle => "Visa Dashboard";
  @override
  String get homeWelcomeGeneric => "Welcome!";
  @override
  String get homeWelcomeUser => "Welcome back, %s!";
  @override
  String get homeWelcomeSubtitle => "Manage your visa journey here.";
  @override
  String get homeVisaProgressTitle => "Application Status";
  @override
  String get homeRecentApplicationsTitle => "Recent Applications";
  @override
  String get homeNotificationsTitle => "Notifications";
  @override
  String get homeRecommendationsTitle => "Recommendations";
  @override
  String get homeProfileOverviewTitle => "Profile Snapshot";
  @override
  String get homeActionViewDetails => "View Details";
  @override
  String get homeAboutUs => "Apply Now";
  @override
  String get homeActionUpdateStatus => "Update Status";
  @override
  String get homeActionViewAll => "View All";
  @override
  String get homeActionExploreMore => "Explore More";
  @override
  String get homeActionEditProfile => "Edit Profile";
  @override
  String get homeActionSecurity => "Security";
  @override
  String get homeStatusApproved => "Approved";
  @override
  String get homeStatusPending => "Pending";
  @override
  String get homeStatusRejected => "Rejected";
  @override
  String get homeStatusSubmitted => "Submitted";
  @override
  String get homeStatusProcessing => "Processing";
  @override
  String get homeStatusUnknown => "Unknown";
  @override
  String get statusRequiresInfo => "Requires Info";
  @override
  String get statusOnHold => "On Hold";
  @override
  String get homeAppsChartLegendApproved => "Approved";
  @override
  String get homeAppsChartLegendPending => "Pending";
  @override
  String get homeAppsChartLegendRejected => "Rejected";
  @override
  String get homeAppsChartNoApps => "No applications submitted yet.";
  @override
  String get homeNotificationsNone => "No new notifications.";
  @override
  String get homeNotificationsError => "Could not load notifications.";
  @override
  String get homeRecommendationsSubtext =>
      "Explore these options based on your profile:";
  @override
  String get homeProfileLabelUsername => "Username";
  @override
  String get homeProfileLabelEmail => "Email";
  @override
  String get homeProfileLabelPhone => "Phone";
  @override
  String get homeProfileValueNotSet => "Not set";
  @override
  String get sidebarTitle => "Visa Consultancy";
  @override
  String get sidebarDashboard => "Dashboard";
  @override
  String get sidebarProfile => "Profile";
  @override
  String get sidebarSettings => "Settings";
  @override
  String get sidebarLogout => "Logout";
  @override
  String get tooltipMenu => "Menu";
  @override
  String get tooltipMarkAllRead => "Mark all as read";
  @override
  String get tooltipViewProfile => "View Profile";
  @override
  String get homeAdditionalStatsTitle => "Performance Insights";
  @override
  String get homeAdditionalStatsAvgProcessing => "Avg. Processing";
  @override
  String get homeAdditionalStatsSuccessRate => "Est. Success Rate";
  @override
  String get homeAdditionalStatsDisclaimer => "Based on historical data.";
  @override
  String get homeQuickActionsTitle => "Quick Actions";
  @override
  String get homeQuickActionNewApp => "New App";
  @override
  String get homeQuickActionMyDocs => "My Docs";
  @override
  String get homeQuickActionBookMeeting => "Book Meeting";
  @override
  String get homeQuickActionSupport => "Support";
  @override
  String get homeQuickActionUpload => "Upload";
  @override
  String get homeQuickActionMyProfile => "My Profile";
  @override
  String get homeRecommendationsTitleCard => "Personalized Suggestions";
  @override
  String get homeRecommendationsSubtextCard =>
      "Options you might be interested in:";
  @override
  String get homeActionSeeDetails => "See Details";
  @override
  String get homeProfileTitleCard => "Profile Snapshot";
  @override
  String get homeActionFullProfile => "Full Profile";

  // Application Form
  @override
  String get appFormTitle => "New Visa Application";
  @override
  String get appFormSectionVisaDetails => "Visa Details";
  @override
  String get appFormSectionPersonalInfo => "Personal Information";
  @override
  String get appFormSectionContactAddress => "Contact & Address";
  @override
  String get appFormSectionTravelHistory => "Travel History";
  @override
  String get appFormSectionPurposeDetails => "Purpose of Visit Details";
  @override
  String get appFormSectionFinancials => "Financial Information";
  @override
  String get appFormSectionBackground => "Background Questions";
  @override
  String get appFormSectionDocuments => "Document Checklist";
  @override
  String get appFormVisaTypeLabel => "Select Visa Type";
  @override
  String get appFormVisaTypeHint => "Choose the type of visa";
  @override
  String get appFormDestinationLabel => "Destination Country";
  @override
  String get appFormDestinationHint => "e.g., USA, Canada, UK";
  @override
  String get appFormEntryDateLabel => "Proposed Entry Date";
  @override
  String get appFormEntryDateHint => "Select date";
  @override
  String get appFormStayDurationLabel => "Intended Stay Duration";
  @override
  String get appFormStayDurationHint => "e.g., 6 months, 2 years";
  @override
  String get appFormFullNameLabel => "Full Legal Name";
  @override
  String get appFormFullNameHint => "As shown on passport";
  @override
  String get appFormDOBLabel => "Date of Birth";
  @override
  String get appFormDOBHint => "Select date";
  @override
  String get appFormNationalityLabel => "Nationality";
  @override
  String get appFormNationalityHint => "Country of citizenship";
  @override
  String get appFormPassportNumberLabel => "Passport Number";
  @override
  String get appFormPassportNumberHint => "Enter passport number";
  @override
  String get appFormPassportExpiryLabel => "Passport Expiry Date";
  @override
  String get appFormPassportExpiryHint => "Select date";
  @override
  String get appFormAddressStreetLabel => "Address";
  @override
  String get appFormAddressStreetHint => "e.g., 123 Main St";
  @override
  String get appFormAddressCityLabel => "City";
  @override
  String get appFormAddressCityHint => "e.g., New York";
  @override
  String get appFormAddressStateLabel => "State/Province (Optional)";
  @override
  String get appFormAddressStateHint => "e.g., NY";
  @override
  String get appFormAddressZipLabel => "ZIP/Postal Code (Optional)";
  @override
  String get appFormAddressZipHint => "e.g., 10001";
  @override
  String get appFormAddressCountryLabel => "Country of Residence";
  @override
  String get appFormAddressCountryHint => "e.g., India";
  @override
  String get appFormPhoneNumberLabel => "Phone Number";
  @override
  String get appFormPhoneNumberHint => "Include country code (+1...)";
  @override
  String get appFormPreviousVisitsLabel =>
      "Have you visited this country before?";
  @override
  String get appFormPreviousVisitsYes => "Yes";
  @override
  String get appFormPreviousVisitsNo => "No";
  @override
  String get appFormPreviousVisasLabel =>
      "Details of previous visits/visas (if yes)";
  @override
  String get appFormPreviousVisasHint => "Type, dates, duration...";
  @override
  String get appFormVisaDenialsLabel =>
      "Have you ever been denied a visa for any country?";
  @override
  String get appFormVisaDenialsYes => "Yes";
  @override
  String get appFormVisaDenialsNo => "No";
  @override
  String get appFormDenialDetailsLabel => "Denial details (if yes)";
  @override
  String get appFormDenialDetailsHint => "Country, visa type, year, reason...";
  @override
  String get appFormStudentUniversityLabel => "University/School Name";
  @override
  String get appFormStudentCourseLabel => "Course of Study";
  @override
  String get appFormWorkEmployerLabel => "Employer Name";
  @override
  String get appFormWorkJobTitleLabel => "Job Title / Position";
  @override
  String get appFormTouristItineraryLabel =>
      "Brief Itinerary / Planned Activities";
  @override
  String get appFormPurposeLabel => "Primary Purpose of Visit";
  @override
  String get appFormPurposeHint => "Briefly describe";
  @override
  String get appFormFundingSourceLabel => "Primary Source of Funds";
  @override
  String get appFormFundingSourceHint => "How will trip be financed?";
  @override
  String get appFormFundingSourceSelf => "Self-Funded";
  @override
  String get appFormFundingSourceSponsor => "Sponsored";
  @override
  String get appFormFundingSourceScholarship => "Scholarship/Grant";
  @override
  String get appFormFundingSourceOther => "Other";
  @override
  String get appFormCriminalRecordLabel => "Do you have a criminal record?";
  @override
  String get appFormCriminalRecordYes => "Yes";
  @override
  String get appFormCriminalRecordNo => "No";
  @override
  String get appFormSecurityQuestionLabel =>
      "Have you ever been involved in espionage or terrorism?";
  @override
  String get appFormSecurityQuestionYes => "Yes";
  @override
  String get appFormSecurityQuestionNo => "No";
  @override
  String get appFormDocsInstruction =>
      "Ensure you have the following documents ready (upload later):";
  @override
  String get appFormDocsPassport => "Passport Copy";
  @override
  String get appFormDocsPhoto => "Digital Photo";
  @override
  String get appFormDocsFinancials => "Proof of Funds";
  @override
  String get appFormDocsLetter => "Acceptance/Employment Letter";
  @override
  String get appFormUploadDocsButton => "Upload Documents (Later)";
  @override
  String get appFormSubmitButton => "Submit Application";
  @override
  String get appFormErrorVisaTypeRequired => "Please select a visa type.";
  @override
  String get appFormErrorDestinationRequired =>
      "Destination country is required.";
  @override
  String get appFormErrorPurposeRequired => "Purpose of visit is required.";
  @override
  String get appFormSuccessMessage => "Application submitted successfully!";
  @override
  String get appFormFailureMessage =>
      "Failed to submit application. Please try again.";

  // Recommendation Screen
  @override
  String get recScreenTitle => "Visa Recommendations";
  @override
  String get recPersonalizedTitle => "Personalized Suggestion";
  @override
  String get recPersonalizedSubtext =>
      "Based on your profile details, this visa might be a good fit:";
  @override
  String get recPersonalizedActionUpdateProfile =>
      "Update Profile for Better Matches";
  @override
  String get recInfoEligibility => "Eligibility";
  @override
  String get recInfoDocuments => "Required Documents";
  @override
  String get recInfoProcessingTime => "Est. Processing Time";
  @override
  String get recInfoFees => "Approx. Fees";
  @override
  String get recInfoValidity => "Visa Validity";
  @override
  String get recInfoApplyButton => "Start Application";
  @override
  String get recInfoNoData => "Could not load visa information.";

  // Visa Types
  @override
  String get visaTypeStudent => "Student Visa";
  @override
  String get visaTypeWork => "Work Visa";
  @override
  String get visaTypeTourist => "Tourist Visa";
  @override
  String get visaTypeOther => "Other";
  @override
  String get visaTypeF1 => "F-1 (Student)";
  @override
  String get visaTypeH1B => "H-1B (Specialty Occupation)";
  @override
  String get visaTypeB1B2 => "B1/B2 (Visitor)";

  // Welcome Screen & Other Sections
  // (Keep implementations for all these keys from your previous working version)
  @override
  String get heroHeadline =>
      "Don’t let the visa interview stop you from your American dream.";
  @override
  String get heroSubheadline =>
      "Get your U.S. visa approved with the help of Former Visa Officers.";
  @override
  String get bookConsultationButton => "Book a consultation";
  @override
  String get statsInterviewsConductedLabel => "Visa interviews conducted";
  @override
  String get statsLanguagesSpokenLabel => "Languages spoken";
  @override
  String get statsConsulatesLabel => "Consulates & Embassies";
  @override
  String get expertiseCard1Title => "Prepare for your first interview";
  @override
  String get expertiseCard1Desc =>
      "Did you know 1 in 4 people get rejected? Get preparation from a Former Visa Officer who can help you pass on the first try!";
  @override
  String get expertiseCard2Title => "Overcome a visa refusal";
  @override
  String get expertiseCard2Desc =>
      "Find out why you really got denied. We help you see your case through the eyes of the Visa Officer so you can get approved on your next attempt.";
  @override
  String get expertiseCard3Title => "Strategize for complicated situations";
  @override
  String get expertiseCard3Desc =>
      "We know how Visa Officers think. Global can help you prepare for challenges at your interview.";
  @override
  String get teamHeadline => "Meet the Former Visa Officers";
  @override
  String get teamDescription =>
      "Our team of Officers are passionate about helping applicants around the world have the resources, information, and preparation they need to pass their visa interview.";
  @override
  String get meetOfficersButton => "Meet Our Officers";
  @override
  String get servicesHeadline => "Who do we help?";
  @override
  String get servicesSubheadline =>
      "Learn more about the cases and situations we help with:";
  @override
  String get servicesNivTitle => "Non-Immigrant Visas (NIV)";
  @override
  String get servicesIvTitle => "Immigrant Visas (IV)";
  @override
  List<String> get nivVisaTypes => [
    "B1/B2 (Business/ tourism)",
    "F-1/ M-1 (Students)",
    "H-1B (Specialty Occupation)",
    "O (Extraordinary Ability/Achievement)",
    "H-4 (dependent family members)",
    "F-2 (dependent status)",
    "L-1 (Intracompany Transferee)",
    "K-1 (Fiancée)",
    "E-2 (Investor visa)",
    "P-1 (Performer)",
    "TN (Professional worker)",
    "J-1 (Au Pair, Scholar, Work&Travel, Teacher)",
    "Other NIVs",
  ];
  @override
  List<String> get ivVisaTypes => [
    "Family-Based",
    "Employment Based",
    "Diversity Visas",
    "Other IVs",
  ];
  @override
  String get reachHeadline => "Helping people from 120+ countries";
  @override
  String get reachDescription =>
      "Our team has unique insights into how Consular Processing works everywhere. We have experience in every region of the world!";
  @override
  String get reachImagePlaceholder => "[Image: Diverse Country Flags]";
  @override
  String get situationsHeadline =>
      "What type of situations can Global Visa help with?";
  @override
  List<String> get situationList => [
    "Overcoming a prior refusal",
    "Visa prep & mock interviews",
    "First visa interview",
    "Post-refusal analysis & strategy",
    "Interviewing after change of status",
    "Navigating complicated situations",
    "Immigrant visa interview",
    "Complex consular strategy",
    "Interview document strategy",
    "DS-160 guidance",
    "Former Visa Officer perspective",
  ];
  @override
  String get situationsContactPrompt =>
      "If you don't see your visa type, country, or situation listed, reach out to us at hello@Globalvisa.com to see if we can help you!";
  @override
  String get learnMoreServicesLink =>
      "Click here to learn about Global Visa Services";
  @override
  String get leadMagnetHeadline => "Pass your F-1 student visa interview?";
  @override
  String get leadMagnetDescription =>
      "We know how Visa Officers think. Understand key insights for the F-1 interview.";
  @override
  String get downloadFreeButton => "Download for FREE";
  @override
  String get testimonialsHeadline => "Our Global Customers share their stories";
  @override
  String get anonymous => "Anonymous";
  @override
  String get googleReviewSource => "Google Review";
  @override
  List<Map<String, String>> get testimonials => [
    {
      "name": "biruk",
      "source": googleReviewSource,
      "quote":
          "I could not recommend Global services more...helped me understand my situation...worth every penny!”",
    },
    {
      "name": "Biruk",
      "source": googleReviewSource,
      "quote":
          "...after four previous denials, I successfully received my B1/B2 visa. I attribute this achievement largely to the guidance...",
    },
    {
      "name": "selam",
      "source": googleReviewSource,
      "quote": "100% recommend! ...30 minutes - and it was WORTH IT.”",
    },
  ];
  @override
  String get languagesHeadline => "We speak your language";
  @override
  String get languagesDescription =>
      "Our team speaks 10+ languages. We can work with you in your native language.";
  @override
  String get learnMoreButton => "Learn more";
  @override
  String get newsletterHeadline =>
      "Get additional insights straight to your inbox!";
  @override
  String get newsletterFirstNameLabel => "First Name";
  @override
  String get newsletterEmailLabel => "Email Address";
  @override
  String get newsletterPhoneLabel => "Phone Number";
  @override
  String get newsletterPhoneOptionalLabel => "Phone (Optional)";
  @override
  String get newsletterDisclaimer =>
      "By submitting your details, you will receive emails from Global Visa. See Terms & Conditions and Privacy Policy.";
  @override
  String get subscribeButton => "submit";
  @override
  String get finalCtaHeadline => "Book Your Visa\nConsultation Today.";
  @override
  String get finalCtaSubheadline =>
      "1 in 4 visas are rejected. Let Global help you pass.";
  @override
  String get getStartedButton => "Get started now";
  @override
  String get goToDashboardButton => "Go to Dashboard";
  @override
  String get footerStatCountries => "150+ countries";
  @override
  String get footerStatApplicants => "5000+ applicants helped";
  @override
  String get footerStatRecommendation => "Recommended by over 90%";
  @override
  String get footerLogoAltText => "Global Logo";
  // --- visa applicaiton detail screen strings ---
  @override
  String get applicationsTitle => "My Applications";
  @override
  String get applicationsErrorLoading => "Could not load applications.";
  @override
  String get applicationsNoApplications =>
      "You haven't submitted any applications yet.";
  @override
  String get applicationsSearchHint => "Search by type or country...";
  @override
  String get applicationsFilterLabel => "Filter By Status";
  @override
  String get applicationsFilterAll => "All Statuses";
  @override
  String get applicationsFilterPending => "Pending";
  @override
  String get applicationsFilterApproved => "Approved";
  @override
  String get applicationsFilterRejected => "Rejected";
  @override
  String get applicationsSortLabel => "Sort By";
  @override
  String get applicationsSortNewest => "Newest First";
  @override
  String get applicationsSortOldest => "Oldest First";
  @override
  String get applicationsSubmittedOn => "Submitted: %s"; // %s is placeholder for date
  @override
  String get applicationsUpdatedAt => "Updated: %s"; // %s is placeholder for relative time
  @override
  String get applicationsViewDetailsAction => "View Details";
  @override
  String get appDetailsTitle => "Application Details";
  @override
  String get appDetailsErrorNotFound =>
      "Application not found or access denied.";
  @override
  String get appDetailsStatusHistory => "Status History";
  @override
  String get appDetailsCurrentStatus => "Current Status";
  @override
  String get appDetailsSubmitted => "Submitted";
  @override
  String get appDetailsLastUpdate => "Last Update";
  @override
  String get appDetailsInfoSection => "Application Information";
  @override
  String get appDetailsNoData => "No details available";
  @override
  String get appDetailVisaType => "Visa Type";
  @override
  String get appDetailDestination => "Destination";
  @override
  String get appDetailFullName => "Full Name";
  @override
  String get appDetailDOB => "Date of Birth";
  @override
  String get appDetailNationality => "Nationality";
  @override
  String get appDetailPassportNo => "Passport No.";
  @override
  String get appDetailPhone => "Phone";
  @override
  String get appDetailPurpose => "Purpose";
  //--- notificaitons ---
  // --- NEW: Notifications Screen ---
  @override
  String get notificationsTitle => "Notifications";
  @override
  String get notificationsMarkAllReadTooltip => "Mark all as read";
  @override
  String get notificationsMarkAllReadSuccess =>
      "All notifications marked as read.";
  @override
  String get notificationsMarkAllReadError => "Failed to mark notifications.";
  @override
  String get notificationsEmpty => "You have no notifications yet.";
  @override
  String get notificationsError => "Could not load notifications.";

  // --- Logout Dialog ---
  @override
  String get logoutConfirmTitle => "Confirm Logout";
  @override
  String get logoutConfirmContent => "Are you sure?";
  // --- ** NEW: Settings Screen Strings (English) ** --- // Add this section header
  @override
  String get settingsProfileSection => "Profile";
  @override
  String get settingsEditProfile => "Edit Profile";
  @override
  String get settingsPreferencesSection => "Preferences";
  @override
  String get settingsNotificationsPref => "Enable Notifications";
  @override
  String get settingsAccountSection => "Account";
  @override
  String get settingsChangePassword => "Change Password";
  @override
  String get settingsLogoutAction => "Logout";
  @override
  String get settingsDeleteAccountAction => "Delete Account";
  @override
  String get settingsSupportSection => "Support & Information";
  @override
  String get settingsHelpCenter => "Help Center";
  @override
  String get settingsPrivacyPolicy => "Privacy Policy";
  @override
  String get settingsTerms => "Terms of Service";
  @override
  String get settingsAbout => "About";
  @override
  String get settingsAboutDialogTitle => "About"; // Used if you build a custom dialog
  @override
  String get settingsAboutDialogContent =>
      "Visa Consultancy App helps you manage your visa applications efficiently.";
  @override
  String get settingsErrorProfileNotFound =>
      "User profile could not be loaded.";
  @override
  String get settingsErrorCannotSendReset =>
      "Cannot send reset email: Email address not found.";
  @override
  String get settingsErrorFailedToSendReset => "Failed to send reset email";
  @override
  String get settingsErrorReauthRequired =>
      "Re-authentication required for this action. Please implement."; // Placeholder
  @override
  String get settingsErrorRequiresRecentLogin =>
      "Security check failed. Please sign out and sign back in recently before performing this action.";
  @override
  String get settingsErrorDeleteFailed => "Failed to delete account";
  @override
  String get settingsSuccessPreferenceSaved => "Preference saved successfully.";
  @override
  String get settingsSuccessAccountDeleted => "Account deleted successfully.";
  @override
  String get settingsDeleteConfirmTitle => "DANGER: Delete Account?";
  @override
  String get settingsDeleteConfirmContent =>
      "This action is irreversible. All your data, including applications and profile information, will be permanently deleted.\n\nARE YOU ABSOLUTELY SURE?";
  @override
  String get settingsDeleteConfirmAction => "YES, DELETE MY ACCOUNT";
  @override
  String get settingsDeleteConfirmTitle2 => "Final Confirmation";
  @override
  String get appName => "Visa Consultancy App";
  @override
  String get settingsDeleteConfirmInputPrompt =>
      "Please type 'DELETE' to confirm permanent account deletion."; // Or adapt if not using input
  @override
  String get settingsDeleteConfirmActionFinal => "CONFIRM DELETION";
  // --- ** END NEW SETTINGS STRINGS (English) ** ---
  // --- ADD TO class AppStringsEn implements AppStrings ---

  // --- ** NEW: Profile Screen Strings (English) ** ---
  @override
  String get profileTitle => "My Profile";
  @override
  String get profileOverviewTab => "Overview";
  @override
  String get profileSettingsTab => "Settings"; // Or reuse sidebarSettings
  @override
  String get profileStatisticsTab => "Statistics";
  @override
  String get profileActivityTab => "Activity";
  @override
  String get profileErrorLoading => "Could not load profile.";
  @override
  String get profileEditButton => "Edit Profile";
  @override
  String get profilePhoneLabel => "Phone";
  @override
  String get profileBioLabel => "Bio";
  @override
  String get profilePreferencesTitle => "Preferences";
  @override
  String get profileNoPreferencesSet => "No preferences set.";
  @override
  String get profileStatsTitle => "Application Statistics";
  @override
  String get profileStatsTotalApps => "Visa Applications ({total} Total)"; // Use {total} as placeholder
  @override
  String get profileStatsNoAppsYet => "No applications submitted yet.";
  @override
  String get profileActivityTitle => "Recent Activity";
  @override
  String get profileActivityErrorLoading => "Error loading activity.";
  @override
  String get profileActivityNoActivity => "No recent activity found.";
  @override
  String get profileActivityActionLogin => "Logged In / Session Started";
  @override
  String get profileActivityActionCreated => "Account Created";
  @override
  String get profileActivityActionUpdate => "Profile Updated";
  @override
  String get profileActivityActionEdited => "Details Edited";
  @override
  String get profileActivityActionApplication => "Application Related";
  @override
  String get profileActivityActionNotification => "Notification Interaction";
  @override
  String get profileActivityActionLogout => "Logged Out";
  @override
  String get profileActivityActionDelete => "Account Action";
  @override
  String get profileActivityActionUnknown => "Unknown Action";
  @override
  String get profileActivityTimeAgo => "%s ago"; // %s for value (e.g., 5m)
  @override
  String get profileActivityJustNow => "Just now";
  // --- ** END NEW PROFILE STRINGS (English) ** ---
}

// --- Amharic Implementation ---
class AppStringsAm implements AppStrings {
  @override
  Locale get locale => const Locale('am');
  @override
  TextTheme get textTheme => GoogleFonts.notoSansEthiopicTextTheme();

  // General
  @override
  String get highContrastTooltip => "ከፍተኛ ንፅፅር";
  @override
  String get darkModeTooltip => "ጨለማ ሁናቴ";
  @override
  String get languageToggleTooltip => "ቋንቋ ቀይር (Switch Language)";
  @override
  String get errorInitializationFailed => "ማስጀመር አልተሳካም";
  @override
  String get errorCouldNotSavePrefs => "ምርጫዎችን ማስቀመጥ አልተቻለም";
  @override
  String get errorConnectivityCheck => "ግንኙነትን ማረጋገጥ አልተቻለም";
  @override
  String get errorActionFailed => "እርምጃው አልተሳካም። እባክዎ እንደገና ይሞክሩ.";
  @override
  String get errorCouldNotLaunchUrl => "ዩአርኤል መክፈት አልተቻለም።";
  @override
  String get errorCouldNotLaunchDialer => "መደወያ መክፈት አልተቻለም።";
  @override
  String get successPrefsSaved => "ምርጫ ተቀምጧል።";
  @override
  String get successSubscription => "ስለተመዘገቡ እናመሰግናለን!";
  @override
  String get connectionRestored => "የበይነመረብ ግንኙነት ተመልሷል።";
  @override
  String get noInternet => "የበይነመረብ ግንኙነት የለም።";
  @override
  String get retryButton => "እንደገና ሞክር";
  @override
  String get errorGeneric => "ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ።";
  @override
  String get loading => "በመጫን ላይ...";
  @override
  String get generalCancel => "ይቅር";
  @override
  String get generalLogout => "ውጣ";

  // Login
  @override
  String get loginWelcomeTitle => "እንኳን ደህና መጡ";
  @override
  String get loginWelcomeSubtitle => "ለመግባት ሳይን ኢን ያድርጉ";
  @override
  String get loginEmailLabel => "ኢሜይል አድራሻ";
  @override
  String get loginPasswordLabel => "የይለፍ ቃል";
  @override
  String get loginForgotPasswordButton => "የይለፍ ቃል ረሱ?";
  @override
  String get loginSignInButton => "ሳይን ኢን";
  @override
  String get loginOrDivider => "ወይም";
  @override
  String get loginSignInWithGoogleButton => "በGoogle ይግቡ";
  @override
  String get loginSignUpPrompt => "አካውንት የለዎትም? ";
  @override
  String get loginSignUpButton => "አካውንት ይክፈቱ";
  @override
  String get loginErrorEmailRequired => 'ኢሜይል ያስፈልጋል።';
  @override
  String get loginErrorEmailInvalid => 'ትክክለኛ ኢሜይል ያስገቡ።';
  @override
  String get loginErrorPasswordRequired => 'የይለፍ ቃል ያስፈልጋል።';
  @override
  String get loginErrorPasswordMinLength => 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት።';
  @override
  String get loginErrorForgotPasswordEmailPrompt => 'እባክዎ መጀመሪያ ኢሜይልዎን ያስገቡ።';
  @override
  String get loginSuccessPasswordResetSent =>
      'የይለፍ ቃል መቀየሪያ ኢሜይል ተልኳል። ኢሜይልዎን ይመልከቱ።';
  @override
  String get loginErrorGenericLoginFailed => 'ሳይን ኢን አልተሳካም። እባክዎ እንደገና ይሞክሩ።';
  @override
  String get loginErrorInvalidCredentials => 'ኢሜይል ወይም የይለፍ ቃል የተሳሳተ ነው።';

  // Sign Up
  @override
  String get signupCreateAccountTitle => "አካውንት ይክፈቱ";
  @override
  String get signupCreateAccountSubtitle => "ጉዞዎን ከእኛ ጋር ይጀምሩ";
  @override
  String get signupUsernameLabel => "የተጠቃሚ ስም";
  @override
  String get signupEmailLabel => "ኢሜይል አድራሻ";
  @override
  String get signupPasswordLabel => "የይለፍ ቃል ይፍጠሩ";
  @override
  String get signupPhoneNumberLabel => "ስልክ ቁጥር";
  @override
  String get signupReferralCodeLabel => "የሪፈራል ኮድ (ካለዎት)";
  @override
  String get signupCreateAccountButton => "አካውንት ፍጠር";
  @override
  String get signupLoginPrompt => "አካውንት አለዎት? ";
  @override
  String get signupLoginButton => "ሳይን ኢን";
  @override
  String get signupErrorUsernameRequired => 'የተጠቃሚ ስም ያስፈልጋል።';
  @override
  String get signupErrorUsernameMinLength => 'የተጠቃሚ ስም ቢያንስ 3 ቁምፊዎች መሆን አለበት።';
  @override
  String get signupErrorEmailRequired => 'ኢሜይል ያስፈልጋል።';
  @override
  String get signupErrorEmailInvalid => 'ትክክለኛ ኢሜይል ያስገቡ።';
  @override
  String get signupErrorPasswordRequired => 'የይለፍ ቃል ያስፈልጋል።';
  @override
  String get signupErrorPasswordMinLength => 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት።';
  @override
  String get signupErrorPhoneRequired => 'ስልክ ቁጥር ያስፈልጋል።';
  @override
  String get signupErrorPhoneInvalid => 'ትክክለኛ ስልክ ቁጥር ያስገቡ።';
  @override
  String get signupErrorGenericSignupFailed => 'አካውንት መክፈት አልተሳካም።';
  @override
  String get signupErrorEmailInUse => 'ይህ ኢሜይል አስቀድሞ ተመዝግቧል።';
  @override
  String get signupErrorWeakPassword => 'የይለፍ ቃል ደካማ ነው።';
  @override
  String get formErrorCheckForm => "እባክዎ ቅጹን ለስህተቶች ያረጋግጡ።";
  @override
  String get formErrorRequired => "ያስፈልጋል";
  @override
  String get formErrorInvalidEmail => "የማይሰራ ኢሜይል";
  @override
  String get appFormErrorFieldRequired => "ይህ መስክ ያስፈልጋል።";
  @override
  String get appFormErrorInvalidDate => "እባክዎ ትክክለኛ ቀን ያስገቡ።";
  @override
  String get appFormErrorInvalidPassport => "ትክክል ያልሆነ የፓስፖርት ቁጥር ቅርጸት።";

  // HomeScreen
  @override
  String get homeDashboardTitle => "ዳሽቦርድ";
  @override
  String get homeWelcomeGeneric => "እንኳን ደህና መጡ!";
  @override
  String get homeWelcomeUser => "እንኳን ደህና መጡ, %s!";
  @override
  String get homeWelcomeSubtitle => "የቪዛ ጉዞዎን ያስተዳድሩ።";
  @override
  String get homeVisaProgressTitle => "የማመልከቻ ሁኔታ";
  @override
  String get homeRecentApplicationsTitle => "የቅርብ ጊዜ ማመልከቻዎች";
  @override
  String get homeNotificationsTitle => "ማሳወቂያዎች";
  @override
  String get homeRecommendationsTitle => "ምክሮች";
  @override
  String get homeProfileOverviewTitle => "የመገለጫ ቅጽበታዊ እይታ";
  @override
  String get homeActionViewDetails => "ዝርዝሮችን ይመልከቱ";
  @override
  String get homeActionUpdateStatus => "ሁኔታ አዘምን";
  @override
  String get homeActionViewAll => "ሁሉንም ይመልከቱ";
  @override
  String get homeActionExploreMore => "ተጨማሪ ያስሱ";
  @override
  String get homeActionEditProfile => "መገለጫ አርትዕ";
  @override
  String get homeActionSecurity => "ደህንነት";
  @override
  String get homeStatusApproved => "ጸድቋል";
  @override
  String get homeStatusPending => "በመጠባበቅ ላይ";
  @override
  String get homeStatusRejected => "ውድቅ ተደርጓል";
  @override
  String get homeStatusSubmitted => "ገባ";
  @override
  String get homeStatusProcessing => "በሂደት ላይ";
  @override
  String get homeAboutUs => "ስለኛ";
  @override
  String get homeStatusUnknown => "ያልታወቀ";
  @override
  String get statusRequiresInfo => "መረጃ ያስፈልጋል";
  @override
  String get statusOnHold => "ታግዷል";
  @override
  String get homeAppsChartLegendApproved => "ጸድቋል";
  @override
  String get homeAppsChartLegendPending => "በመጠባበቅ ላይ";
  @override
  String get homeAppsChartLegendRejected => "ውድቅ ተደርጓል";
  @override
  String get homeAppsChartNoApps => "እስካሁን ምንም ማመልከቻዎች የሉም።";
  @override
  String get homeNotificationsNone => "ምንም አዲስ ማሳወቂያዎች የሉም።";
  @override
  String get homeNotificationsError => "ማሳወቂያዎችን መጫን አልተቻለም።";
  @override
  String get homeRecommendationsSubtext =>
      "በእርስዎ መገለጫ ላይ በመመስረት እነዚህን አማራጮች ያስሱ፡";
  @override
  String get homeProfileLabelUsername => "የተጠቃሚ ስም";
  @override
  String get homeProfileLabelEmail => "ኢሜይል";
  @override
  String get homeProfileLabelPhone => "ስልክ";
  @override
  String get homeProfileValueNotSet => "አልተዋቀረም";
  @override
  String get sidebarTitle => "የቪዛ አማካሪ";
  @override
  String get sidebarDashboard => "ዳሽቦርድ";
  @override
  String get sidebarProfile => "መገለጫ";
  @override
  String get sidebarSettings => "ቅንብሮች";
  @override
  String get sidebarLogout => "ውጣ";
  @override
  String get tooltipMenu => "ምናሌ";
  @override
  String get tooltipMarkAllRead => "ሁሉንም እንደተነበበ ምልክት አድርግ";
  @override
  String get tooltipViewProfile => "መገለጫ ይመልከቱ";
  @override
  String get homeAdditionalStatsTitle => "የአፈጻጸም ግንዛቤዎች";
  @override
  String get homeAdditionalStatsAvgProcessing => "አማካይ ሂደት";
  @override
  String get homeAdditionalStatsSuccessRate => "ግምታዊ የስኬት መጠን";
  @override
  String get homeAdditionalStatsDisclaimer => "በታሪካዊ መረጃ ላይ የተመሰረተ።";
  @override
  String get homeQuickActionsTitle => "ፈጣን እርምጃዎች";
  @override
  String get homeQuickActionNewApp => "አዲስ መተግበሪያ";
  @override
  String get homeQuickActionMyDocs => "ሰነዶቼ";
  @override
  String get homeQuickActionBookMeeting => "ስብሰባ ያዝ";
  @override
  String get homeQuickActionSupport => "ድጋፍ";
  @override
  String get homeQuickActionUpload => "ጫን";
  @override
  String get homeQuickActionMyProfile => "የኔ መገለጫ";
  @override
  String get homeRecommendationsTitleCard => "ለእርስዎ የቀረቡ ምክሮች";
  @override
  String get homeRecommendationsSubtextCard => "ሊፈልጓቸው የሚችሏቸው አማራጮች፡";
  @override
  String get homeActionSeeDetails => "ዝርዝሮችን ይመልከቱ";
  @override
  String get homeProfileTitleCard => "የመገለጫ ቅጽበታዊ እይታ";
  @override
  String get homeActionFullProfile => "ሙሉ መገለጫ";

  // Application Form
  @override
  String get appFormTitle => "አዲስ የቪዛ ማመልከቻ";
  @override
  String get appFormSectionVisaDetails => "የቪዛ ዝርዝሮች";
  @override
  String get appFormSectionPersonalInfo => "የግል መረጃ";
  @override
  String get appFormSectionContactAddress => "የመገኛ መረጃ እና አድራሻ";
  @override
  String get appFormSectionTravelHistory => "የጉዞ ታሪክ";
  @override
  String get appFormSectionPurposeDetails => "የጉብኝት ምክንያት ዝርዝሮች";
  @override
  String get appFormSectionFinancials => "የገንዘብ መረጃ";
  @override
  String get appFormSectionBackground => "የጀርባ ጥያቄዎች";
  @override
  String get appFormSectionDocuments => "የሰነድ ዝርዝር";
  @override
  String get appFormVisaTypeLabel => "የቪዛ አይነት ይምረጡ";
  @override
  String get appFormVisaTypeHint => "የሚፈልጉትን የቪዛ አይነት ይምረጡ";
  @override
  String get appFormDestinationLabel => "የመድረሻ ሀገር";
  @override
  String get appFormDestinationHint => "ምሳሌ፦ አሜሪካ, ካናዳ";
  @override
  String get appFormEntryDateLabel => "የታቀደ የመግቢያ ቀን";
  @override
  String get appFormEntryDateHint => "ቀን ይምረጡ";
  @override
  String get appFormStayDurationLabel => "የሚቆዩበት ግዜ";
  @override
  String get appFormStayDurationHint => "ምሳሌ፦ 6 ወር, 2 ዓመት";
  @override
  String get appFormFullNameLabel => "ሙሉ ህጋዊ ስም";
  @override
  String get appFormFullNameHint => "ፓስፖርት ላይ እንዳለው";
  @override
  String get appFormDOBLabel => "የትውልድ ቀን";
  @override
  String get appFormDOBHint => "ቀን ይምረጡ";
  @override
  String get appFormNationalityLabel => "ዜግነት";
  @override
  String get appFormNationalityHint => "የዜግነት ሀገር";
  @override
  String get appFormPassportNumberLabel => "የፓስፖርት ቁጥር";
  @override
  String get appFormPassportNumberHint => "የፓስፖርት ቁጥር ያስገቡ";
  @override
  String get appFormPassportExpiryLabel => "ፓስፖርት የሚያበቃበት ቀን";
  @override
  String get appFormPassportExpiryHint => "ቀን ይምረጡ";
  @override
  String get appFormAddressStreetLabel => "አድራሻ";
  @override
  String get appFormAddressStreetHint => "ምሳሌ፦ ቀበሌ 08";
  @override
  String get appFormAddressCityLabel => "ከተማ";
  @override
  String get appFormAddressCityHint => "ምሳሌ፦ አዲስ አበባ";
  @override
  String get appFormAddressStateLabel => "ክፍለ ሀገር/ክልል (ካለ)";
  @override
  String get appFormAddressStateHint => "ምሳሌ፦ አዲስ አበባ";
  @override
  String get appFormAddressZipLabel => "ፖስታ ቁጥር (ካለ)";
  @override
  String get appFormAddressZipHint => "ምሳሌ፦ 1000";
  @override
  String get appFormAddressCountryLabel => "የመኖሪያ ሀገር";
  @override
  String get appFormAddressCountryHint => "ምሳሌ፦ ኢትዮጵያ";
  @override
  String get appFormPhoneNumberLabel => "ስልክ ቁጥር";
  @override
  String get appFormPhoneNumberHint => "የሀገር ኮድ ጨምሮ (+251...)";
  @override
  String get appFormPreviousVisitsLabel => "ይህችን ሀገር ከዚህ በፊት ጎብኝተው ያውቃሉ?";
  @override
  String get appFormPreviousVisitsYes => "አዎ";
  @override
  String get appFormPreviousVisitsNo => "አይ";

  // --- ** NEW: Edit Screen Strings (Amharic) ** --- // Add this section header
  @override
  String get editAppTitle => "ማመልከቻ አርትዕ";
  @override
  String get editAppSaveChangesButton => "ለውጦችን አስቀምጥ";
  @override
  String get editAppSuccessMessage => "ማመልከቻው በተሳካ ሁኔታ ዘምኗል!";
  @override
  String get editAppSelectDateHint => "ቀን ይምረጡ";
  // --- ** END NEW EDIT SCREEN STRINGS (Amharic) ** ---
  @override
  String get appFormPreviousVisasLabel => "የቀድሞ ጉብኝቶች/ቪዛዎች ዝርዝር (አዎ ከሆነ)";
  @override
  String get appFormPreviousVisasHint => "አይነት, ቀን, የቆይታ ጊዜ...";
  @override
  String get appFormVisaDenialsLabel => "ለማንኛውም ሀገር ቪዛ ተከልክለው ያውቃሉ?";
  @override
  String get appFormVisaDenialsYes => "አዎ";
  @override
  String get appFormVisaDenialsNo => "አይ";
  @override
  String get appFormDenialDetailsLabel => "የቪዛ እምቢታ ዝርዝሮች (አዎ ከሆነ)";
  @override
  String get appFormDenialDetailsHint => "ሀገር, የቪዛ አይነት, ዓመት, ምክንያት...";
  @override
  String get appFormStudentUniversityLabel => "የዩኒቨርሲቲ/ትምህርት ቤት ስም";
  @override
  String get appFormStudentCourseLabel => "የትምህርት መስክ";
  @override
  String get appFormWorkEmployerLabel => "የቀጣሪ ስም";
  @override
  String get appFormWorkJobTitleLabel => "የሥራ መደብ";
  @override
  String get appFormTouristItineraryLabel => "አጭር የጉዞ እቅድ / እንቅስቃሴዎች";
  @override
  String get appFormPurposeLabel => "ዋና የጉብኝት ምክንያት";
  @override
  String get appFormPurposeHint => "በአጭሩ ይግለጹ";
  @override
  String get appFormFundingSourceLabel => "ዋና የገንዘብ ምንጭ";
  @override
  String get appFormFundingSourceHint => "ጉዞው እንዴት ይሸፈናል?";
  @override
  String get appFormFundingSourceSelf => "በራስ ወጪ";
  @override
  String get appFormFundingSourceSponsor => "በስፖንሰር";
  @override
  String get appFormFundingSourceScholarship => "ስኮላርሺፕ/ዕርዳታ";
  @override
  String get appFormFundingSourceOther => "ሌላ";
  @override
  String get appFormCriminalRecordLabel => "የወንጀል ሪከርድ አለብዎት?";
  @override
  String get appFormCriminalRecordYes => "አዎ";
  @override
  String get appFormCriminalRecordNo => "የለብኝም";
  @override
  String get appFormSecurityQuestionLabel => "በስለላ ወይም ሽብርተኝነት ተሳትፈው ያውቃሉ?";
  @override
  String get appFormSecurityQuestionYes => "አዎ";
  @override
  String get appFormSecurityQuestionNo => "አይ";
  @override
  String get appFormDocsInstruction =>
      "የሚከተሉትን ሰነዶች ዝግጁ መሆናቸውን ያረጋግጡ (በኋላ ይጫናሉ):";
  @override
  String get appFormDocsPassport => "የፓስፖርት ቅጂ";
  @override
  String get appFormDocsPhoto => "ዲጂታል ፎቶ";
  @override
  String get appFormDocsFinancials => "የገንዘብ ማረጋገጫ";
  @override
  String get appFormDocsLetter => "የቅበላ/የቅጥር ደብዳቤ";
  @override
  String get appFormUploadDocsButton => "ሰነዶችን ይጫኑ (በኋላ)";
  @override
  String get appFormSubmitButton => "ማመልከቻ አስገባ";
  @override
  String get appFormErrorVisaTypeRequired => "እባክዎ የቪዛ አይነት ይምረጡ።";
  @override
  String get appFormErrorDestinationRequired => "የመድረሻ ሀገር ያስፈልጋል።";
  @override
  String get appFormErrorPurposeRequired => "የጉብኝት ምክንያት ያስፈልጋል።";
  @override
  String get appFormSuccessMessage => "ማመልከቻው በተሳካ ሁኔታ ገብቷል!";
  @override
  String get appFormFailureMessage => "ማመልከቻ ማስገባት አልተሳካም። እባክዎ እንደገና ይሞክሩ።";

  // Recommendation Screen
  @override
  String get recScreenTitle => "የቪዛ ምክሮች";
  @override
  String get recPersonalizedTitle => "ለእርስዎ የቀረበ ሀሳብ";
  @override
  String get recPersonalizedSubtext =>
      "በእርስዎ መገለጫ ላይ በመመስረት፣ ይህ ቪዛ ተስማሚ ሊሆን ይችላል፡";
  @override
  String get recPersonalizedActionUpdateProfile => "ለተሻለ ምክር መገለጫ ያዘምኑ";
  @override
  String get recInfoEligibility => "የብቁነት መስፈርት";
  @override
  String get recInfoDocuments => "የሚያስፈልጉ ሰነዶች";
  @override
  String get recInfoProcessingTime => "ግምታዊ የሂደት ጊዜ";
  @override
  String get recInfoFees => "ግምታዊ ክፍያ";
  @override
  String get recInfoValidity => "የቪዛ ፀንቶ መቆያ ጊዜ";
  @override
  String get recInfoApplyButton => "ማመልከቻ ጀምር";
  @override
  String get recInfoNoData => "የቪዛ መረጃ መጫን አልተቻለም።";

  // Visa Types
  @override
  String get visaTypeStudent => "የተማሪ ቪዛ";
  @override
  String get visaTypeWork => "የሥራ ቪዛ";
  @override
  String get visaTypeTourist => "የቱሪስት ቪዛ";
  @override
  String get visaTypeOther => "ሌላ";
  @override
  String get visaTypeF1 => "F-1 (ተማሪ)";
  @override
  String get visaTypeH1B => "H-1B (ልዩ ሙያ)";
  @override
  String get visaTypeB1B2 => "B1/B2 (ጎብኚ)";

  // Welcome Screen & Other Sections (Existing Implementations)
  @override
  String get heroHeadline => "የቪዛ ቃለ መጠይቁ ከአሜሪካ ህልምዎ እንዲያስቀርዎት አይፍቀዱ።";
  @override
  String get heroSubheadline => "የቀድሞ የቪዛ አማካር እገዛ በማግኘት የአሜሪካ ቪዛዎን ያጽድቁ።";
  @override
  String get bookConsultationButton => "የቪዛ process ይጀምሩ";
  @override
  String get statsInterviewsConductedLabel => "የተካሄዱ የቪዛ ቃለመጠይቆች";
  @override
  String get statsLanguagesSpokenLabel => "የሚነገሩ ቋንቋዎች";
  @override
  String get statsConsulatesLabel => "ቆንስላዎች እና ኤምባሲዎች";
  @override
  String get expertiseCard1Title => "ለመጀመሪያ ቃለ መጠይቅዎ ይዘጋጁ";
  @override
  String get expertiseCard1Desc =>
      "ከ4 ሰዎች 1 ሰው ውድቅ እንደሚደረግ ያውቃሉ? በመጀመሪያው ሙከራዎ እንዲያልፉ ከሚረዳዎ የቀድሞ የቪዛ መኮንን ዝግጅት ያግኙ!";
  @override
  String get expertiseCard2Title => "የቪዛ እምቢታን ማሸነፍ";
  @override
  String get expertiseCard2Desc =>
      "በእኛ እርዳታ ለምን በእርግጥ ውድቅ እንደተደረጉ ይወቁ። በሚቀጥለው ሙከራዎ መጽደቅ እንዲችሉ ጉዳይዎን በቪዛ ኦፊሰር እይታ እንዲመለከቱ እንረዳዎታለን።";
  @override
  String get expertiseCard3Title => "ለተወሳሰቡ ሁኔታዎች ስልት መንደፍ";
  @override
  String get expertiseCard3Desc =>
      "የቪዛ አማካር እንዴት እንደሚያስቡ እና ውሳኔ እንደሚወስኑ ከማንም በላይ እናውቃለን። ግሎባል በቪዛ ቃለ መጠይቅዎ ላይ ያሉ ማናቸውንም ችግሮች እንዴት መወጣት እንደሚችሉ እንዲዘጋጁ ይረዳዎታል።";
  @override
  String get teamHeadline => "የቀድሞ የቪዛ አማካርን ያግኙ";
  @override
  String get teamDescription =>
      "የእኛ የአማካር ቡድን በአለም ዙሪያ ያሉ አመልካቾች የቪዛ ቃለ መጠይቃቸውን ለማለፍ የሚያስፈልጉትን ግብአቶች፣ መረጃዎች እና ዝግጅቶች እንዲያገኙ ለመርዳት ቁርጠኞች ናቸው።";
  @override
  String get meetOfficersButton => "የቪዛ አማካር ያግኙ";
  @override
  String get servicesHeadline => "ማንን ነው የምንረዳው?";
  @override
  String get servicesSubheadline => "ልንረዳቸው የምንችላቸውን ጉዳዮች እና ሁኔታዎች የበለጠ ይወቁ:";
  @override
  String get servicesNivTitle => "ስደተኛ ያልሆኑ ቪዛዎች (NIV)";
  @override
  String get servicesIvTitle => "የስደተኞች ቪዛዎች (IV)";
  @override
  List<String> get nivVisaTypes => [
    "B1/B2 (ንግድ/ቱሪዝም)",
    "F-1/ M-1 (ተማሪዎች)",
    "H-1B (ልዩ ሙያ)",
    "O (ልዩ ችሎታ/ስኬት)",
    "H-4 (ጥገኛ የቤተሰብ አባላት)",
    "F-2 (ጥገኛ ሁኔታ)",
    "L-1 (የድርጅት ውስጥ ዝውውር)",
    "K-1 (እጮኛ)",
    "E-2 (ባለሀብት ቪዛ)",
    "P-1 (አቅራቢ)",
    "TN (የሙያ ሰራተኛ)",
    "J-1 (ኦፔር፣ ጎብኚ ምሁር፣ በጋ ሥራ እና ጉዞ፣ መምህር)",
    "ሌሎች ስደተኛ ያልሆኑ ቪዛዎች",
  ];
  @override
  List<String> get ivVisaTypes => [
    "በቤተሰብ ላይ የተመሰረተ ስደት",
    "በቅጥር ላይ የተመሰረተ ስደት",
    "የዳይቨርሲቲ ቪዛዎች",
    "ሌሎች የስደተኞች ቪዛዎች",
  ];
  @override
  String get reachHeadline => "ከ120+ በላይ ሀገራት ሰዎችን መርዳት";
  @override
  String get reachDescription =>
      "የእኛ ቡድን የቆንስላ ሂደቱ በሁሉም ቦታ እንዴት እንደሚሰራ ልዩ ግንዛቤዎች አሉት። በአለም ላይ ባሉ ሁሉም ክልሎች ልምድ አለን!";
  @override
  String get reachImagePlaceholder => "[ምስል: የተለያዩ የሀገር ባንዲራዎች]";
  @override
  String get situationsHeadline => "ግሎባል ቪዛ በምን አይነት ሁኔታዎች ሊረዳ ይችላል?";
  @override
  List<String> get situationList => [
    "የቀድሞ እምቢታን ማሸነፍ",
    "የቪዛ ዝግጅት እና የሙከራ ቃለመጠይቆች",
    "ለመጀመሪያው የቪዛ ቃለ መጠይቅ መዘጋጀት",
    "ከእምቢታ በኋላ ትንተና እና ስልት",
    "የሁኔታ ለውጥ ከተደረገ በኋላ ቃለ መጠይቅ ማድረግ",
    "ውስብስብ ሁኔታዎችን ማሰስ",
    "ለስደተኛ ቪዛ ቃለ መጠይቅ",
    "ውስብስብ የቆንስላ ሁኔታ ስልት",
    "የቪዛ ቃለ መጠይቅ ሰነድ ስልት",
    "ቪዛዎን ከማመልከትዎ በፊት የDS-160 መመሪያ",
    "በጉዳይዎ ላይ የቀድሞ የቪዛ መኮንን ግብረመልስ እና እይታ",
  ];
  @override
  String get situationsContactPrompt =>
      "የቪዛ አይነትዎን፣ ሀገርዎን ወይም ሁኔታዎን ዝርዝር ውስጥ ካላዩ፣ ልንረዳዎ እንደምንችል ለማየት በ hello@globalvisa.com ያግኙን!";
  @override
  String get learnMoreServicesLink => "ስለ ግሎባል ቪዛ አገልግሎቶች ለማወቅ እዚህ ጠቅ ያድርጉ";
  @override
  String get leadMagnetHeadline => "የF-1 የተማሪ ቪዛ ቃለ መጠይቅዎን ማለፍ ይፈልጋሉ?";
  @override
  String get leadMagnetDescription =>
      "የቪዛ አማካር እንዴት እንደሚያስቡ እናውቃለን። ለF-1 ቃለ መጠይቅ ቁልፍ ግንዛቤዎችን ይረዱ።";
  @override
  String get downloadFreeButton => "በነጻ ያውርዱ";
  @override
  String get testimonialsHeadline => "የእኛ ግሎባል ደንበኞች ታሪካቸውን ያካፍላሉ";
  @override
  String get anonymous => "ስም የለም";
  @override
  String get googleReviewSource => "Google ግምገማ";
  @override
  List<Map<String, String>> get testimonials => [
    {
      "name": "ብርሃኑ ካ.",
      "source": googleReviewSource,
      "quote":
          "ከግሎባል አገልግሎቶች የበለጠ ልመክር አልችልም... ሁኔታዬን እንድረዳ ረድቶኛል... ለእያንዳንዱ ሳንቲም ዋጋ አለው!",
    },
    {
      "name": "አበበች ሸ.",
      "source": googleReviewSource,
      "quote":
          "...ከአራት ቀዳሚ እምቢታዎች በኋላ፣ የ B1/B2 ቪዛዬን በተሳካ ሁኔታ አግኝቻለሁ። ይህንን ስኬት በአብዛኛው...",
    },
    {
      "name": "ሳሙኤል ገ.",
      "source": googleReviewSource,
      "quote": "100% እመክራለሁ!... ባለቤቴና እኔ... 30 ደቂቃ - እና ዋጋ ነበረው።",
    },
  ];
  @override
  String get languagesHeadline => "የእርስዎን ቋንቋ እንናገራለን";
  @override
  String get languagesDescription =>
      "ቡድናችን ከ10 በላይ ቋንቋዎችን ይናገራል። በአፍ መፍቻ ቋንቋዎ ልንሰራዎ እንችላለን።";
  @override
  String get learnMoreButton => "የበለጠ ተማር";
  @override
  String get newsletterHeadline => "ተጨማሪ ግንዛቤዎችን  ለማገኘት በቀጥታ ወደ ኢሜል መልእክት ይላኩ!";
  @override
  String get newsletterFirstNameLabel => "የመጀመሪያ ስም";
  @override
  String get newsletterEmailLabel => "የኢሜል አድራሻ";
  @override
  String get newsletterPhoneLabel => "ስልክ ቁጥር";
  @override
  String get newsletterPhoneOptionalLabel => "ስልክ (አማራጭ)";
  @override
  String get newsletterDisclaimer =>
      "ዝርዝሮችዎን በማስገባት ከግሎባል ቪዛ ኢሜይሎችን ይደርስዎታል። የአገልግሎት ውሎችን እና የግላዊነት መመሪያን ይመልከቱ።";
  @override
  String get subscribeButton => "መልእክቶን ያስተላልፉ";
  // formErrorCheckForm defined above
  @override
  String get finalCtaHeadline => "የቪዛ process አሁኑኑ\nዛሬውኑ ይጀምሩ።";
  @override
  String get finalCtaSubheadline => "ከ4 ቪዛዎች 1ዱ ውድቅ ይደረጋል። ግሎባል እንዲያልፉ ይርዳዎት።";
  @override
  String get getStartedButton => "አሁኑኑ ይጀምሩ";
  @override
  String get goToDashboardButton => "ወደ ዳሽቦርድ ይሂዱ";
  @override
  String get footerStatCountries => "150+ ሀገሮች";
  @override
  String get footerStatApplicants => "5000+ አመልካቾች ረድተናል";
  @override
  String get footerStatRecommendation => "ከ90% በላይ ደንበኞች የሚመከር";
  @override
  String get footerLogoAltText => "ግሎባል ሎጎ";
  // --- application screen --
  @override
  String get applicationsTitle => "የእኔ ማመልከቻዎች";
  @override
  String get applicationsErrorLoading => "ማመልከቻዎችን መጫን አልተቻለም።";
  @override
  String get applicationsNoApplications => "እስካሁን ምንም ማመልከቻ አላስገቡም።";
  @override
  String get applicationsSearchHint => "በአይነት ወይም በሀገር ይፈልጉ...";
  @override
  String get applicationsFilterLabel => "በሁኔታ ማጣራት";
  @override
  String get applicationsFilterAll => "ሁሉም ሁኔታዎች";
  @override
  String get applicationsFilterPending => "በመጠባበቅ ላይ";
  @override
  String get applicationsFilterApproved => "ጸድቋል";
  @override
  String get applicationsFilterRejected => "ውድቅ ተደርጓል";
  @override
  String get applicationsSortLabel => "በዚህ መደርደር";
  @override
  String get applicationsSortNewest => "አዲስ መጀመሪያ";
  @override
  String get applicationsSortOldest => "አሮጌ መጀመሪያ";
  @override
  String get applicationsSubmittedOn => "የገባው: %s";
  @override
  String get applicationsUpdatedAt => "የዘመነው: %s";
  @override
  String get applicationsViewDetailsAction => "ዝርዝሮችን ይመልከቱ";
  @override
  String get appDetailsTitle => "የማመልከቻ ዝርዝሮች";
  @override
  String get appDetailsErrorNotFound => "ማመልከቻ አልተገኘም ወይም የመዳረሻ ፍቃድ የለም።";
  @override
  String get appDetailsStatusHistory => "የሁኔታ ታሪክ";
  @override
  String get appDetailsCurrentStatus => "የአሁኑ ሁኔታ";
  @override
  String get appDetailsSubmitted => "ገባ";
  @override
  String get appDetailsLastUpdate => "ለመጨረሻ ጊዜ የዘመነው";
  @override
  String get appDetailsInfoSection => "የማመልከቻ መረጃ";
  @override
  String get appDetailsNoData => "ምንም ዝርዝር መረጃ የለም";
  @override
  String get appDetailVisaType => "የቪዛ አይነት";
  @override
  String get appDetailDestination => "መድረሻ";
  @override
  String get appDetailFullName => "ሙሉ ስም";
  @override
  String get appDetailDOB => "የትውልድ ቀን";
  @override
  String get appDetailNationality => "ዜግነት";
  @override
  String get appDetailPassportNo => "ፓስፖርት ቁጥር";
  @override
  String get appDetailPhone => "ስልክ";
  @override
  String get appDetailPurpose => "ምክንያት";

  // --- Logout Dialog ---
  @override
  String get logoutConfirmTitle => "መውጣት ያረጋግጡ";
  @override
  String get logoutConfirmContent => "እርግጠኛ ነዎት?";
  //-- notifications --
  // --- NEW: Notifications Screen ---
  @override
  String get notificationsTitle => "ማሳወቂያዎች";
  @override
  String get notificationsMarkAllReadTooltip => "ሁሉንም እንደተነበበ ምልክት አድርግ";
  @override
  String get notificationsMarkAllReadSuccess =>
      "ሁሉም ማሳወቂያዎች እንደተነበቡ ምልክት ተደርጎባቸዋል።";
  @override
  String get notificationsMarkAllReadError => "ማሳወቂያዎችን ምልክት ማድረግ አልተሳካም።";
  @override
  String get notificationsEmpty => "እስካሁን ምንም ማሳወቂያዎች የሉም።";
  @override
  String get notificationsError => "ማሳወቂያዎችን መጫን አልተቻለም።";
  // --- ** NEW: Settings Screen Strings (Amharic) ** --- // Add this section header
  @override
  String get settingsProfileSection => "መገለጫ";
  @override
  String get settingsEditProfile => "መገለጫ አርትዕ";
  @override
  String get settingsPreferencesSection => "ምርጫዎች";
  @override
  String get settingsNotificationsPref => "ማሳወቂያዎችን አንቃ";
  @override
  String get settingsAccountSection => "አካውንት";
  @override
  String get settingsChangePassword => "የይለፍ ቃል ቀይር";
  @override
  String get settingsLogoutAction => "ውጣ"; // Reuses generalLogout if preferred, but separate is clearer
  @override
  String get settingsDeleteAccountAction => "አካውንት አጥፋ";
  @override
  String get settingsSupportSection => "ድጋፍ እና መረጃ";
  @override
  String get settingsHelpCenter => "የእገዛ ማዕከል";
  @override
  String get settingsPrivacyPolicy => "የግላዊነት መመሪያ";
  @override
  String get settingsTerms => "የአገልግሎት ውሎች";
  @override
  String get settingsAbout => "ስለ";
  @override
  String get settingsAboutDialogTitle => "ስለ"; // Used if custom dialog
  @override
  String get settingsAboutDialogContent =>
      "የቪዛ አማካሪ መተግበሪያ የቪዛ ማመልከቻዎችዎን በብቃት እንዲያስተዳድሩ ያግዝዎታል።";
  @override
  String get settingsErrorProfileNotFound => "የተጠቃሚ መገለጫ መጫን አልተቻለም።";
  @override
  String get settingsErrorCannotSendReset =>
      "የኢሜይል አድራሻ ስላልተገኘ የይለፍ ቃል ዳግም ማስጀመሪያ ኢሜይል መላክ አልተቻለም።";
  @override
  String get settingsErrorFailedToSendReset =>
      "የይለፍ ቃል ዳግም ማስጀመሪያ ኢሜይል መላክ አልተሳካም";
  @override
  String get settingsErrorReauthRequired =>
      "ለዚህ እርምጃ ዳግም ማረጋገጫ ያስፈልጋል። እባክዎ ተግባራዊ ያድርጉ።"; // Placeholder
  @override
  String get settingsErrorRequiresRecentLogin =>
      "የደህንነት ማረጋገጫ አልተሳካም። እባክዎ ይህን እርምጃ ከመፈጸምዎ በፊት በቅርቡ ወጥተው እንደገና ይግቡ።";
  @override
  String get settingsErrorDeleteFailed => "አካውንት ማጥፋት አልተሳካም";
  @override
  String get settingsSuccessPreferenceSaved => "ምርጫው በተሳካ ሁኔታ ተቀምጧል።";
  @override
  String get settingsSuccessAccountDeleted => "አካውንቱ በተሳካ ሁኔታ ተሰርዟል።";
  @override
  String get settingsDeleteConfirmTitle => "አደጋ፡ አካውንት ይሰረዝ?";
  @override
  String get appName => "visa አማካር";
  @override
  String get settingsDeleteConfirmContent =>
      "ይህ እርምጃ የማይቀለበስ ነው። ማመልከቻዎችን እና የመገለጫ መረጃን ጨምሮ ሁሉም የእርስዎ ውሂብ እስከመጨረሻው ይሰረዛል።\n\nሙሉ በሙሉ እርግጠኛ ነዎት?";
  @override
  String get settingsDeleteConfirmAction => "አዎ፣ አካውንቴን አጥፋ";
  @override
  String get settingsDeleteConfirmTitle2 => "የመጨረሻ ማረጋገጫ";
  @override
  String get settingsDeleteConfirmInputPrompt =>
      "ቋሚ የአካውንት ስረዛን ለማረጋገጥ እባክዎ 'DELETE' ብለው ይጻፉ።"; // Adapt if not using input
  @override
  String get settingsDeleteConfirmActionFinal => "ስረዛውን አረጋግጥ";
  // --- ** END NEW SETTINGS STRINGS (Amharic) ** ---
  // --- ADD TO class AppStringsAm implements AppStrings ---

  // --- ** NEW: Profile Screen Strings (Amharic) ** ---
  @override
  String get profileTitle => "የኔ መገለጫ";
  @override
  String get profileOverviewTab => "አጠቃላይ እይታ";
  @override
  String get profileSettingsTab => "ቅንብሮች"; // Reuse sidebarSettings
  @override
  String get profileStatisticsTab => "ስታቲስቲክስ";
  @override
  String get profileActivityTab => "እንቅስቃሴ";
  @override
  String get profileErrorLoading => "መገለጫ መጫን አልተቻለም።";
  @override
  String get profileEditButton => "መገለጫ አርትዕ";
  @override
  String get profilePhoneLabel => "ስልክ";
  @override
  String get profileBioLabel => "አጭር መግለጫ";
  @override
  String get profilePreferencesTitle => "ምርጫዎች";
  @override
  String get profileNoPreferencesSet => "ምንም ምርጫዎች አልተቀመጡም።";
  @override
  String get profileStatsTitle => "የማመልከቻ ስታቲስቲክስ";
  @override
  String get profileStatsTotalApps => "የቪዛ ማመልከቻዎች ({total} ጠቅላላ)";
  @override
  String get profileStatsNoAppsYet => "እስካሁን ምንም ማመልከቻዎች አልተገቡም።";
  @override
  String get profileActivityTitle => "የቅርብ ጊዜ እንቅስቃሴ";
  @override
  String get profileActivityErrorLoading => "እንቅስቃሴ መጫን ላይ ስህተት ተከስቷል።";
  @override
  String get profileActivityNoActivity => "ምንም የቅርብ ጊዜ እንቅስቃሴ አልተገኘም።";
  @override
  String get profileActivityActionLogin => "ገብቷል / ክፍለ ጊዜ ተጀምሯል";
  @override
  String get profileActivityActionCreated => "አካውንት ተፈጥሯል";
  @override
  String get profileActivityActionUpdate => "መገለጫ ተዘምኗል";
  @override
  String get profileActivityActionEdited => "ዝርዝሮች ተስተካክለዋል";
  @override
  String get profileActivityActionApplication => "ከማመልከቻ ጋር የተያያዘ";
  @override
  String get profileActivityActionNotification => "የማሳወቂያ መስተጋብር";
  @override
  String get profileActivityActionLogout => "ወጥቷል";
  @override
  String get profileActivityActionDelete => "የአካውንት እርምጃ";
  @override
  String get profileActivityActionUnknown => "ያልታወቀ እርምጃ";
  @override
  String get profileActivityTimeAgo => "ከ %s በፊት"; // %s ለዋጋው (ለምሳሌ 5ደ)
  @override
  String get profileActivityJustNow => "አሁን";
  // --- ** END NEW PROFILE STRINGS (Amharic) ** ---
}

@override
// --- Localization Setup Logic ---
class AppLocalizations {
  final Locale locale;
  final AppStrings strings;

  AppLocalizations(this.locale, this.strings);

  // Helper to get strings using Provider
  static AppStrings? of(BuildContext context) {
    try {
      final provider = Provider.of<LocaleProvider>(context, listen: false);
      return getStrings(provider.locale);
    } catch (e) {
      debugPrint("Error getting AppLocalizations: Provider not found? $e");
      return AppStringsEn(); // Fallback safely
    }
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Map holding instances for each language
  static final Map<String, AppStrings> _localizedValues = {
    'en': AppStringsEn(),
    'am': AppStringsAm(),
  };

  // Retrieve correct AppStrings instance based on Locale
  static AppStrings getStrings(Locale locale) {
    return _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
  }
}

// Delegate for loading strings
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  static const _supportedLanguageCodes = ['en', 'am'];

  @override
  bool isSupported(Locale locale) =>
      _supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppStrings strings = AppLocalizations.getStrings(locale);
    return AppLocalizations(locale, strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// --- End of File ---
