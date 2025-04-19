// lib/models/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String? phone;
  final String? profilePictureUrl;
  final String? bio;
  final bool notificationsEnabled;
  final Map<String, dynamic> preferences;
  final Timestamp? createdAt; // Track when the profile was created
  final Timestamp? lastLogin; // Track last login time
  final Timestamp? updatedAt; // Track last update time

  UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    this.phone,
    this.profilePictureUrl,
    this.bio,
    this.notificationsEnabled = true, // Default to true
    this.preferences = const {}, // Default to empty map
    this.createdAt,
    this.lastLogin,
    this.updatedAt,
  });

  // Factory constructor to create a UserProfile object from a Firestore DocumentSnapshot
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    // It's safer to check for null or cast carefully
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return UserProfile(
      uid: doc.id, // The document ID is the UID
      username: data['username'] ?? 'Unknown User', // Provide defaults
      email: data['email'] ?? '',
      phone: data['phone'] as String?, // Cast safely
      profilePictureUrl: data['profilePictureUrl'] as String?,
      bio: data['bio'] as String?,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      preferences: (data['preferences'] as Map<String, dynamic>?) ?? {},
      createdAt: data['createdAt'] as Timestamp?,
      lastLogin: data['lastLogin'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  // Method to convert a UserProfile object back to a Map for Firestore
  // This is useful if you need to create/update Firestore documents from the model
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid, // Often useful to store UID within the doc as well
      'username': username,
      'email': email,
      // Only include fields if they are not null
      if (phone != null) 'phone': phone,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (bio != null) 'bio': bio,
      'notificationsEnabled': notificationsEnabled,
      'preferences': preferences,
      // Timestamps might be set using FieldValue.serverTimestamp() elsewhere
      if (createdAt != null) 'createdAt': createdAt,
      if (lastLogin != null) 'lastLogin': lastLogin,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}
