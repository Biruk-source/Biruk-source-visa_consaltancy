// lib/models/visa_application.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class VisaApplication {
  final String id; // Firestore document ID
  final String userId;
  final String visaType; // e.g., "student", "work" (use the key)
  final String status;
  final Timestamp createdAt;
  final Timestamp? statusUpdatedAt;
  final String? rejectionReason;
  final String? consultantNotes; // Notes from the consultant/reviewer

  // --- ALL THE FORM DATA FIELDS ---
  // Make these nullable as they might not exist on every doc initially
  // Or provide default values in fromFirestore if appropriate

  // Visa Details section
  final String? destinationCountry;
  final String? proposedEntryDate; // Store as ISO string
  final String? proposedStayDuration;

  // Personal Info section
  final String? fullName;
  final String? dateOfBirth; // Store as ISO string
  final String? nationality;
  final String? passportNumber;
  final String? passportExpiryDate; // Store as ISO string

  // Contact & Address section
  final String? addressStreet;
  final String? addressCity;
  final String? addressState;
  final String? addressZip;
  final String? addressCountry;
  final String? phoneNumber;

  // Travel History section
  final bool? hasPreviousVisits;
  final String? previousVisasDetails;
  final bool? hasVisaDenials;
  final String? denialDetails;

  // Purpose section
  final String? purposeOfVisit; // General purpose
  // Purpose Specific Fields (Now top-level in the model)
  final String? studentUniversity;
  final String? studentCourse;
  final String? workEmployer;
  final String? workJobTitle;
  final String? touristItinerary;
  // ... add other specific fields for other visa types if needed ...

  // Financials section
  final String? fundingSource;
  // Add sponsor details etc. if needed

  // Background section
  final bool? hasCriminalRecord;
  // Add other background fields

  // --- Keep original formData map as a fallback or for less structured data? ---
  // It's generally better to have explicit fields if the structure is consistent.
  // If you absolutely need it:
  final Map<String, dynamic>? formData;

  VisaApplication({
    required this.id,
    required this.userId,
    required this.visaType,
    required this.status,
    required this.createdAt,
    this.statusUpdatedAt,
    this.rejectionReason,
    this.consultantNotes,
    // Add all the new fields to the constructor
    this.destinationCountry,
    this.proposedEntryDate,
    this.proposedStayDuration,
    this.fullName,
    this.dateOfBirth,
    this.nationality,
    this.passportNumber,
    this.passportExpiryDate,
    this.addressStreet,
    this.addressCity,
    this.addressState,
    this.addressZip,
    this.addressCountry,
    this.phoneNumber,
    this.hasPreviousVisits,
    this.previousVisasDetails,
    this.hasVisaDenials,
    this.denialDetails,
    this.purposeOfVisit,
    this.studentUniversity,
    this.studentCourse,
    this.workEmployer,
    this.workJobTitle,
    this.touristItinerary,
    this.fundingSource,
    this.hasCriminalRecord,
    this.formData, // Keep if using
  });

  // Factory constructor to create a VisaApplication from Firestore data
  factory VisaApplication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return VisaApplication(
      id: doc.id,
      userId: data['userId'] ?? '',
      visaType: data['visaType'] ?? 'other', // Default type if missing
      status: data['status'] ?? 'Unknown',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      statusUpdatedAt: data['statusUpdatedAt'] as Timestamp?,
      rejectionReason: data['rejectionReason'] as String?,
      consultantNotes: data['consultantNotes'] as String?,

      // Map all the fields directly from data
      destinationCountry: data['destinationCountry'] as String?,
      proposedEntryDate: data['proposedEntryDate'] as String?,
      proposedStayDuration: data['proposedStayDuration'] as String?,
      fullName: data['fullName'] as String?,
      dateOfBirth: data['dateOfBirth'] as String?,
      nationality: data['nationality'] as String?,
      passportNumber: data['passportNumber'] as String?,
      passportExpiryDate: data['passportExpiryDate'] as String?,
      addressStreet: data['addressStreet'] as String?,
      addressCity: data['addressCity'] as String?,
      addressState: data['addressState'] as String?,
      addressZip: data['addressZip'] as String?,
      addressCountry: data['addressCountry'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      hasPreviousVisits: data['hasPreviousVisits'] as bool?,
      previousVisasDetails: data['previousVisasDetails'] as String?,
      hasVisaDenials: data['hasVisaDenials'] as bool?,
      denialDetails: data['denialDetails'] as String?,
      purposeOfVisit: data['purposeOfVisit'] as String?,
      studentUniversity: data['studentUniversity'] as String?,
      studentCourse: data['studentCourse'] as String?,
      workEmployer: data['workEmployer'] as String?,
      workJobTitle: data['workJobTitle'] as String?,
      touristItinerary: data['touristItinerary'] as String?,
      fundingSource: data['fundingSource'] as String?,
      hasCriminalRecord: data['hasCriminalRecord'] as bool?,
      // Keep formData mapping if you still store data there too
      formData:
          (data['formData'] != null && data['formData'] is Map)
              ? Map<String, dynamic>.from(data['formData'])
              : null, // Ensure it's a map
    );
  }

  // Method to convert to Map for Firestore (useful for creating/updating)
  // Make sure this includes all relevant fields if you use it for updates
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'visaType': visaType,
      'status': status,
      'createdAt': createdAt,
      if (statusUpdatedAt != null) 'statusUpdatedAt': statusUpdatedAt,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (consultantNotes != null) 'consultantNotes': consultantNotes,
      // Add all other fields...
      if (destinationCountry != null) 'destinationCountry': destinationCountry,
      if (proposedEntryDate != null) 'proposedEntryDate': proposedEntryDate,
      if (proposedStayDuration != null)
        'proposedStayDuration': proposedStayDuration,
      if (fullName != null) 'fullName': fullName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (nationality != null) 'nationality': nationality,
      if (passportNumber != null) 'passportNumber': passportNumber,
      if (passportExpiryDate != null) 'passportExpiryDate': passportExpiryDate,
      if (addressStreet != null) 'addressStreet': addressStreet,
      if (addressCity != null) 'addressCity': addressCity,
      if (addressState != null) 'addressState': addressState,
      if (addressZip != null) 'addressZip': addressZip,
      if (addressCountry != null) 'addressCountry': addressCountry,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (hasPreviousVisits != null) 'hasPreviousVisits': hasPreviousVisits,
      if (previousVisasDetails != null)
        'previousVisasDetails': previousVisasDetails,
      if (hasVisaDenials != null) 'hasVisaDenials': hasVisaDenials,
      if (denialDetails != null) 'denialDetails': denialDetails,
      if (purposeOfVisit != null) 'purposeOfVisit': purposeOfVisit,
      if (studentUniversity != null) 'studentUniversity': studentUniversity,
      if (studentCourse != null) 'studentCourse': studentCourse,
      if (workEmployer != null) 'workEmployer': workEmployer,
      if (workJobTitle != null) 'workJobTitle': workJobTitle,
      if (touristItinerary != null) 'touristItinerary': touristItinerary,
      if (fundingSource != null) 'fundingSource': fundingSource,
      if (hasCriminalRecord != null) 'hasCriminalRecord': hasCriminalRecord,
      if (formData != null) 'formData': formData,
    };
  }
}
