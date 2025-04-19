// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart'; // For debugPrint

// Import your data models
import '../models/user_profile.dart';
import '../models/visa_application.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- Authentication ---

  User? getCurrentUser() => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    // ... (Keep this method as it was - no duplicates here) ...
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error (Sign In): ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      debugPrint('General Error (Sign In): $e');
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  Future<UserCredential?> signUpWithEmailPassword(
    String email,
    String password,
    String username,
    String phone,
    String? referralCode, // Make sure this is the ONLY definition
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      if (userCredential.user != null) {
        await saveInitialUserData(
          // Call the correct method below
          userCredential.user!,
          username.trim(),
          phone.trim(),
          referralCode?.trim(),
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error (Sign Up): ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      debugPrint('General Error (Sign Up): $e');
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          // When saving initial data for Google user, phone/referral are typically not available
          // Pass null or default values as needed for the saveInitialUserData method
          await saveInitialUserData(
            user,
            user.displayName ?? 'Google User',
            '', // Pass empty string or null for phone if unavailable
            null, // Pass null for referral code
          );
        } else {
          await userDocRef.update({
            'lastLogin': FieldValue.serverTimestamp(),
            'profilePictureUrl':
                user.photoURL ?? userDoc.data()?['profilePictureUrl'],
            'email': user.email,
          });
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error (Google Sign In): ${e.code} - ${e.message}',
      );
      throw e;
    } catch (e) {
      debugPrint('General Error (Google Sign In): $e');
      throw Exception('An unexpected error occurred during Google sign in.');
    }
  }

  // --- Make sure this is the ONLY `saveInitialUserData` ---
  Future<void> saveInitialUserData(
    User user,
    String username,
    String phone, // Takes phone
    String? referralCode, // Takes referral code
  ) async {
    try {
      final userData = UserProfile(
        uid: user.uid,
        username: username,
        email: user.email ?? '',
        phone: phone, // Save phone number
        profilePictureUrl: user.photoURL,
        createdAt: Timestamp.now(),
        lastLogin: Timestamp.now(),
        notificationsEnabled: true,
        preferences: {},
      );

      Map<String, dynamic> firestoreData = userData.toFirestore();

      if (referralCode != null && referralCode.isNotEmpty) {
        firestoreData['referralCode'] =
            referralCode; // Add referral code if present
      }

      await _firestore.collection('users').doc(user.uid).set(firestoreData);

      debugPrint(
        "Initial user data saved for ${user.uid} (inc. phone/referral)",
      );

      // Keep welcome notification/activity log
      addNotification(
        user.uid,
        'Welcome to Visa Consultancy!',
        type: 'Welcome',
      );
      addActivityLog(user.uid, 'Account Created', {
        'method':
            user.providerData.isNotEmpty
                ? user.providerData[0].providerId
                : 'email',
      });
    } catch (e) {
      debugPrint('Error saving initial user data for ${user.uid}: $e');
    }
  }

  /// Signs the current user out from Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      // Check if signed in with Google before attempting to sign out
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      debugPrint("User signed out successfully.");
    } catch (e) {
      debugPrint('Error Signing Out: $e');
      // Don't usually need to throw an error here, just log it.
    }
  }

  /// Sends a password reset email to the provided email address.
  /// Throws FirebaseAuthException on errors (e.g., user not found).
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint("Password reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error (Password Reset): ${e.code} - ${e.message}',
      );
      throw e;
    } catch (e) {
      debugPrint('General Error (Password Reset): $e');
      throw Exception('Could not send password reset email.');
    }
  }

  // --- User Account Deletion ---

  /// Deletes the currently authenticated user's account from Firebase Auth.
  /// **WARNING:** Requires recent login (re-authentication) handled in the UI.
  /// **WARNING:** Does NOT automatically delete associated Firestore data.
  /// Throws exceptions on failure or if re-authentication is required.
  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user currently signed in to delete.');
    }

    try {
      // !!! Placeholder for Re-authentication !!!
      // You MUST implement re-authentication logic in your UI BEFORE calling this.
      // Gather credentials (password, or trigger Google/Apple re-sign) and
      // call `user.reauthenticateWithCredential(credential)` here.
      // --- Example Re-auth Start (Conceptual) ---
      // bool reauthenticated = await _promptAndPerformReauthentication(context);
      // if (!reauthenticated) {
      //    throw Exception('Re-authentication failed or was cancelled.');
      // }
      // --- Example Re-auth End ---

      // Proceed with deletion ONLY AFTER successful re-authentication
      String uid = user.uid; // Store UID before user object becomes invalid
      await user.delete();
      debugPrint("Firebase Auth user deleted for UID: $uid");

      // ** Call data cleanup AFTER successful Auth deletion **
      await _deleteUserFirestoreData(uid);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error (Delete Account): ${e.code} - ${e.message}',
      );
      if (e.code == 'requires-recent-login') {
        // This is the crucial error to handle in the UI, prompting re-login.
        throw Exception(
          'Security check failed. Please sign in again recently to delete your account.',
        );
      }
      throw Exception(
        'Failed to delete account: ${e.message}',
      ); // Generic message for other auth errors
    } catch (e) {
      debugPrint('General Error (Delete Account): $e');
      throw Exception('Could not delete user account.');
    }
  }

  /// Helper function to delete associated Firestore data for a user.
  /// Call this AFTER successful `user.delete()`.
  /// Uses batch writes for efficiency and atomicity where possible.
  /// Consider Cloud Functions for more robust, server-side cleanup.
  Future<void> _deleteUserFirestoreData(String uid) async {
    debugPrint("Attempting to delete Firestore data for UID: $uid");
    final WriteBatch batch = _firestore.batch();

    // 1. Delete user profile document
    final userDocRef = _firestore.collection('users').doc(uid);
    batch.delete(userDocRef);

    // 2. Delete subcollections (requires fetching documents first)
    // Be mindful of limits if subcollections can be very large. Cloud Functions are better for huge datasets.
    try {
      // Delete Applications
      final appSnapshot =
          await userDocRef
              .collection('applications')
              .limit(500)
              .get(); // Limit batch size
      for (final doc in appSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete Notifications
      final notifSnapshot =
          await userDocRef.collection('notifications').limit(500).get();
      for (final doc in notifSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete Activity Log
      final activitySnapshot =
          await userDocRef.collection('activity').limit(500).get();
      for (final doc in activitySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // TODO: Add deletion for any other user-specific subcollections

      // Commit all batched deletions
      await batch.commit();
      debugPrint("Successfully deleted Firestore data batch for UID: $uid");
    } catch (e) {
      debugPrint(
        "Error deleting Firestore data for UID $uid: $e. Some data might be orphaned.",
      );
      // Log this error seriously. Orphaned data is hard to clean up later.
      throw Exception('Failed to clean up all user data.');
    }
  }

  // --- User Data (Firestore) ---

  /// Saves initial user data ONLY during signup or first Google login.

  /// Updates specific fields in a user's profile document.
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> dataToUpdate,
  ) async {
    if (uid.isEmpty) {
      throw ArgumentError('User ID cannot be empty for profile update.');
    }
    if (dataToUpdate.isEmpty) {
      debugPrint(
        "updateUserProfile called with no data to update for UID: $uid",
      );
      return; // Nothing to do
    }
    try {
      dataToUpdate.remove('uid'); // Cannot update the document ID
      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(uid).update(dataToUpdate);
      debugPrint(
        "User profile updated for $uid. Fields: ${dataToUpdate.keys.join(', ')}",
      );
      addActivityLog(uid, 'Updated Profile', dataToUpdate.keys.toList());
    } catch (e) {
      debugPrint('Error updating user profile for $uid: $e');
      throw Exception('Failed to update profile.');
    }
  }

  /// Retrieves a user's profile, returning a UserProfile object or null.
  Future<UserProfile?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserProfile.fromFirestore(userDoc);
      } else {
        debugPrint('User profile document not found for UID: $uid');
        return null; // No profile found for this user
      }
    } catch (e) {
      debugPrint('Error getting user profile for $uid: $e');
      throw Exception('Could not retrieve user profile.');
    }
  }

  // --- Visa Applications (Firestore Subcollection) ---

  /// Adds a new visa application document to the user's subcollection.
  Future<DocumentReference?> addVisaApplication(
    String uid,
    Map<String, dynamic> applicationData,
  ) async {
    if (uid.isEmpty) {
      throw ArgumentError('User ID cannot be empty for adding application.');
    }
    if (applicationData['visaType'] == null ||
        applicationData['visaType'].isEmpty) {
      throw ArgumentError('Visa type is required for new application.');
    }
    try {
      // Ensure standard fields are set
      applicationData['createdAt'] = FieldValue.serverTimestamp();
      applicationData['status'] = 'Submitted'; // Initial status
      applicationData['userId'] = uid; // Link to the user

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('applications')
          .add(applicationData);

      debugPrint("Added visa application ${docRef.id} for user $uid");
      // Add activity log and notification
      addActivityLog(uid, 'Created Visa Application', {
        'applicationId': docRef.id,
        'type': applicationData['visaType'],
      });
      addNotification(
        uid,
        'Your ${applicationData['visaType']} visa application has been submitted.',
        type: 'ApplicationSubmitted',
        relatedDocId: docRef.id,
      );

      return docRef;
    } catch (e) {
      debugPrint('Error adding visa application for $uid: $e');
      throw Exception('Failed to submit visa application.');
    }
  }

  /// Fetches all visa applications for a specific user, ordered by creation date.
  Future<List<VisaApplication>> getUserApplications(String uid) async {
    if (uid.isEmpty) return [];
    try {
      QuerySnapshot appSnapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('applications')
              .orderBy('createdAt', descending: true) // Show newest first
              .get();

      final applications =
          appSnapshot.docs
              .map((doc) => VisaApplication.fromFirestore(doc))
              .toList();
      debugPrint("Fetched ${applications.length} applications for user $uid");
      return applications;
    } catch (e) {
      debugPrint('Error fetching applications for $uid: $e');
      throw Exception('Could not retrieve applications.');
    }
  }

  /// Fetches details for a single specific visa application.
  Future<VisaApplication?> getApplicationDetails(
    String uid,
    String applicationId,
  ) async {
    if (uid.isEmpty || applicationId.isEmpty) return null;
    try {
      DocumentSnapshot appDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('applications')
              .doc(applicationId)
              .get();

      if (appDoc.exists) {
        return VisaApplication.fromFirestore(appDoc);
      } else {
        debugPrint('Application $applicationId not found for user $uid');
        return null; // Application not found
      }
    } catch (e) {
      debugPrint('Error fetching application details for $applicationId: $e');
      throw Exception('Could not retrieve application details.');
    }
  }

  /// Updates the status and optionally notes/reason for a specific visa application.
  Future<void> updateApplicationStatus(
    String uid,
    String applicationId,
    String newStatus, {
    String? reviewerNotes,
    String? reviewerId,
  }) async {
    if (uid.isEmpty || applicationId.isEmpty || newStatus.isEmpty) {
      throw ArgumentError(
        'User ID, Application ID, and New Status cannot be empty.',
      );
    }
    // You might want to validate newStatus against a list of allowed statuses
    // const allowedStatuses = ['Submitted', 'Processing', 'Requires Information', 'Approved', 'Rejected'];
    // if (!allowedStatuses.contains(newStatus)) {
    //   throw ArgumentError('Invalid status provided: $newStatus');
    // }

    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      };

      // Clear previous rejection reason when status changes, unless it's becoming 'Rejected' again
      if (newStatus != 'Rejected') {
        updateData['rejectionReason'] = FieldValue.delete();
      }

      // Handle notes based on status
      if (reviewerNotes != null && reviewerNotes.isNotEmpty) {
        updateData['consultantNotes'] = reviewerNotes; // General notes field
        if (newStatus == 'Rejected') {
          updateData['rejectionReason'] =
              reviewerNotes; // Specific field for rejection
        }
      }

      // Track the reviewer if provided
      if (reviewerId != null && reviewerId.isNotEmpty) {
        updateData['lastReviewedBy'] = reviewerId;
      }

      final appRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('applications')
          .doc(applicationId);

      await appRef.update(updateData);
      debugPrint(
        "Updated status for application $applicationId to $newStatus for user $uid",
      );

      // Add activity log and notify the user
      addActivityLog(uid, 'Application Status Updated', {
        'applicationId': applicationId,
        'newStatus': newStatus,
      });
      addNotification(
        uid,
        'Update for application $applicationId: Status is now $newStatus.',
        type: 'ApplicationUpdate',
        relatedDocId: applicationId,
      );
    } catch (e) {
      debugPrint('Error updating application status for $applicationId: $e');
      throw Exception('Failed to update application status.');
    }
  }

  // --- Notifications (Firestore Subcollection) ---

  /// Adds a notification document to the user's subcollection.
  Future<void> addNotification(
    String uid,
    String message, {
    String type = 'General',
    String? relatedDocId,
  }) async {
    if (uid.isEmpty || message.isEmpty) return;
    try {
      Map<String, dynamic> notificationData = {
        'message': message,
        'type':
            type, // e.g., 'ApplicationUpdate', 'Reminder', 'Message', 'Welcome'
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // Start as unread
      };
      // Add reference to related document (like an application) if provided
      if (relatedDocId != null && relatedDocId.isNotEmpty) {
        notificationData['relatedDocId'] = relatedDocId;
      }

      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add(notificationData);
      debugPrint("Added notification ${docRef.id} for user $uid (type: $type)");
    } catch (e) {
      debugPrint('Error adding notification for $uid: $e');
      // Typically log this but don't interrupt user flow
    }
  }

  /// Provides a real-time stream of the user's most recent notifications.
  Stream<QuerySnapshot> getUserNotificationsStream(
    String uid, {
    int limit = 20,
  }) {
    if (uid.isEmpty) return Stream.empty(); // Return empty stream if no UID
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true) // Show newest first
        .limit(limit) // Limit the number of results for performance
        .snapshots() // Listen for real-time changes
        .handleError((error) {
          // Gracefully handle errors in the stream
          debugPrint("Error in notification stream for $uid: $error");
          // You might want to yield an error state or an empty list here
        });
  }

  /// Marks a single notification as read.
  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      debugPrint("Marked notification $notificationId as read for user $uid");
    } catch (e) {
      debugPrint('Error marking notification $notificationId as read: $e');
      // Log only, usually not critical to throw
    }
  }

  /// Marks all unread notifications for a user as read using a batch write.
  Future<void> markAllNotificationsAsRead(String uid) async {
    if (uid.isEmpty) return;
    debugPrint("Attempting to mark all notifications read for user $uid");
    try {
      final batch = _firestore.batch();
      // Get only unread notifications to avoid unnecessary writes
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint("No unread notifications to mark for user $uid.");
        return;
      }

      int count = 0;
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
        count++;
      }
      await batch.commit();
      debugPrint("Marked $count notifications as read for user $uid.");
      addActivityLog(uid, 'Marked all notifications as read', {'count': count});
    } catch (e) {
      debugPrint('Error marking all notifications as read for $uid: $e');
      throw Exception('Failed to update notifications.');
    }
  }

  // --- Activity Log (Firestore Subcollection) ---

  /// Adds an entry to the user's activity log subcollection.
  Future<void> addActivityLog(
    String uid,
    String action,
    dynamic details,
  ) async {
    if (uid.isEmpty || action.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).collection('activity').add({
        'action':
            action, // e.g., 'Logged In', 'Updated Profile', 'Viewed Application'
        'details': details, // Contextual details (map, string, list etc.)
        'timestamp': FieldValue.serverTimestamp(),
        // Optionally add platform, IP (with privacy considerations)
      });
    } catch (e) {
      // Log but don't interrupt user flow
      debugPrint('Error adding activity log for $uid (Action: $action): $e');
    }
  }

  /// Provides a real-time stream of the user's most recent activity log entries.
  Stream<QuerySnapshot> getUserActivityStream(String uid, {int limit = 50}) {
    if (uid.isEmpty) return Stream.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('activity')
        .orderBy('timestamp', descending: true) // Show most recent first
        .limit(limit)
        .snapshots()
        .handleError((error) {
          debugPrint("Error in activity stream for $uid: $error");
        });
  }

  // --- Newsletter Subscriptions (Top-Level Collection) ---

  /// Adds or updates a newsletter subscription in the 'newsletterSubscriptions' collection.
  /// Uses email as document ID for deduplication.
  Future<void> addNewsletterSubscription(
    String email, {
    String? firstName,
    String? phone,
  }) async {
    if (email.trim().isEmpty || !_isValidEmail(email)) {
      // Added email validation
      throw ArgumentError(
        'A valid email is required for newsletter subscription.',
      );
    }
    try {
      // Sanitize email to use as a Firestore document ID (basic example)
      String docId = email.trim().toLowerCase().replaceAll(
        RegExp(r'[.#$[\]]'),
        '_',
      );

      Map<String, dynamic> subscriptionData = {
        'email': email.trim().toLowerCase(), // Store lowercase for consistency
        'subscribedAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'status': 'subscribed', // Default status
      };
      // Add optional fields if provided
      if (firstName != null && firstName.trim().isNotEmpty) {
        subscriptionData['firstName'] = firstName.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        subscriptionData['phone'] =
            phone.trim(); // Consider phone number validation/formatting
      }

      // Use SetOptions(merge: true) to update if email exists, or create if new
      await _firestore
          .collection('newsletterSubscriptions')
          .doc(docId)
          .set(subscriptionData, SetOptions(merge: true));
      debugPrint("Newsletter subscription added/updated for $email");
    } catch (e) {
      debugPrint(
        'Error adding/updating newsletter subscription for $email: $e',
      );
      throw Exception('Failed to subscribe to the newsletter.');
    }
  }

  // Optional: Method to check subscription status or unsubscribe would go here

  // --- Consultancy Configuration/Settings (Top-Level Collection) ---

  /// Fetches global application settings from the 'appConfig' collection.
  /// Uses 'default' as the standard document ID, but allows overrides.
  /// Returns null if the config document doesn't exist.
  Future<Map<String, dynamic>?> getAppSettings({
    String configDocId = 'default',
  }) async {
    try {
      DocumentSnapshot configDoc =
          await _firestore.collection('appConfig').doc(configDocId).get();
      if (configDoc.exists) {
        debugPrint("Fetched app configuration '$configDocId'");
        return configDoc.data() as Map<String, dynamic>?;
      } else {
        debugPrint('App configuration document "$configDocId" not found.');
        return null; // Configuration doesn't exist
      }
    } catch (e) {
      debugPrint('Error fetching app configuration "$configDocId": $e');
      throw Exception('Could not load application settings.');
    }
  }

  // --- Helper Methods --- (like validation - could be moved to a utils file)
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  Future<void> updateApplicationDetails(
    String uid,
    String applicationId,
    Map<String, dynamic> dataToUpdate, // Map of fields to change
  ) async {
    if (uid.isEmpty || applicationId.isEmpty) {
      throw ArgumentError('User ID and Application ID cannot be empty.');
    }
    if (dataToUpdate.isEmpty) {
      debugPrint(
        'updateApplicationDetails called with no data for $applicationId',
      );
      return; // Nothing to update
    }

    // Remove fields that shouldn't be directly updated here
    dataToUpdate.remove('status');
    dataToUpdate.remove('statusUpdatedAt');
    dataToUpdate.remove('createdAt');
    dataToUpdate.remove('userId');
    dataToUpdate.remove('id'); // Cannot update document ID

    if (dataToUpdate.isEmpty) {
      debugPrint(
        'No valid fields remaining to update for $applicationId after filtering.',
      );
      return;
    }

    try {
      // Add an 'updatedAt' timestamp for tracking general updates
      dataToUpdate['detailsUpdatedAt'] = FieldValue.serverTimestamp();

      final appRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('applications')
          .doc(applicationId);

      await appRef.update(dataToUpdate); // Use update, not set

      debugPrint(
        "Updated details for application $applicationId for user $uid. Fields: ${dataToUpdate.keys.join(', ')}",
      );

      // Optional: Add activity log entry
      addActivityLog(uid, 'Updated Application Details', {
        'applicationId': applicationId,
        'updatedFields': dataToUpdate.keys.toList(),
      });

      addNotification(
        uid,
        'Details updated for application $applicationId.',
        type: 'ApplicationDetailsUpdate', // New type?
        relatedDocId: applicationId,
      );
    } catch (e) {
      debugPrint('Error updating application details for $applicationId: $e');
      throw Exception('Failed to update application details.');
    }
  }

  // Add Firebase Storage methods for file uploads/downloads if needed
}
