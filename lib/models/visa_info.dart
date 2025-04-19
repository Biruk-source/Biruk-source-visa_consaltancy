// lib/models/visa_info.dart

class VisaInfo {
  final String typeKey; // e.g., 'student_f1', 'work_h1b' (used for linking)
  final String localizedName; // e.g., "F-1 (Student)"
  final String eligibility;
  final List<String> documents;
  final String processingTime;
  final String fees;
  final String validity;
  final String? description; // Optional short description

  VisaInfo({
    required this.typeKey,
    required this.localizedName,
    required this.eligibility,
    required this.documents,
    required this.processingTime,
    required this.fees,
    required this.validity,
    this.description,
  });

  // Add a fromMap constructor if fetching from Firestore later
  // factory VisaInfo.fromMap(Map<String, dynamic> map, String key) { ... }
}
