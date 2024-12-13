import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart'; // For SHA-256
import 'dart:convert'; // For utf8 encoding
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Check if the user is logged in by checking SharedPreferences
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userData'); // Returns true if 'userData' exists
  }

  // Check if the user is logged in by checking SharedPreferences
  Future<Map<String, dynamic>> loginWithSchoolId(String schoolId,
      String password) async {
    try {
      // Fetch the user document from Firestore using the school ID as the document ID
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(
          schoolId).get();

      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found.'};
      }

      // Retrieve the email from Firestore document
      String email = userDoc['email'];

      // Log in the user with Firebase Authentication using the email and password
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password, // Ensure the password is correct
      );

      final user = userCredential.user;
      if (user != null) {
        // Save user data locally (SharedPreferences), excluding the password
        await _saveUserDataLocally(userDoc, user.email);

        return {
          'success': true,
          'message': 'Login successful!',
          'user': userDoc.data(), // Returning the user data from Firestore
        };
      } else {
        return {'success': false, 'message': 'Failed to log in.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Hash the password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha256.convert(bytes); // Perform the SHA-256 hashing
    return digest.toString(); // Return the hashed password as a string
  }

  // Save user data to SharedPreferences (excluding the password)
  Future<void> _saveUserDataLocally(DocumentSnapshot userDoc,
      String? email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save user details (ensure that the keys match your Firestore document fields)
    await prefs.setString('user_first_name', userDoc['first_name']);
    await prefs.setString('user_last_name', userDoc['last_name']);
    await prefs.setString(
        'user_email', email ?? ''); // Save email from Firebase Authentication
    await prefs.setString(
        'user_school_id', userDoc.id); // Saving the school ID (document ID)
    // Do not store the password in SharedPreferences for security reasons

    await prefs.setBool('is_logged_in', true);
  }

  // Log out the user and clear SharedPreferences
  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // List of keys to retain
    List<String> keysToRetain = [
      'first_time', // Retaining the key for first-time app launch (example)
      // Add any other keys you want to retain here
    ];

    // Get all keys in SharedPreferences
    Set<String> allKeys = prefs.getKeys();

    // Iterate over all keys and remove them if they are not in the keysToRetain list
    for (String key in allKeys) {
      if (!keysToRetain.contains(key)) {
        await prefs.remove(key);
      }
    }

    // Optionally set 'is_logged_in' to false if you want to track login status
    await prefs.setBool('is_logged_in', false);
  }

  // Get current user email from Firebase Authentication
  Future<String> getCurrentUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? '';
  }

  // Update the email in Firebase Authentication
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Send verification email to the new email
        await user.verifyBeforeUpdateEmail(newEmail);
        await user.reload();

        print("Verification email sent. Please verify the new email.");
      } else {
        print("No user signed in.");
      }
    } catch (e) {
      print("Error updating email: $e");
      throw Exception("Failed to update email: $e");
    }
  }



  Future<void> printCurrentUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Current user email: ${user.email}');
    } else {
      print('No user is signed in');
    }
  }

  // Update user profile (first name, last name, school ID, and password)
  Future<bool> updateProfile(String schoolId, String firstName, String lastName,
      String email, String password) async {
    try {
      // Prepare user data for update
      Map<String, dynamic> updatedData = {
        'first_name': firstName,
        'last_name': lastName,
        'user_email': email, // Optionally update school ID if required
      };

      // If a new password is provided, hash it and update it
      if (password.isNotEmpty) {
        updatedData['password'] =
            _hashPassword(password); // Hash the password before saving
      }

      // Update the user document in Firestore
      await _firestore.collection('users').doc(schoolId).update(updatedData);

      // Optionally, save updated data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);
      await prefs.setString('user_email', email); // Update email if needed
      await prefs.setString(
          'user_school_id', schoolId); // Update school ID in SharedPreferences

      // Log the success to the console for debugging
      print("Profile updated successfully!");
      return true; // Return true if update was successful
    } catch (e) {
      // Print the error message to the console for debugging
      print("Error updating profile: $e");

      // Show more detailed error feedback
      if (e is FirebaseException) {
        print("Firebase error: ${e.message}");
      } else {
        print("Non-Firebase error: $e");
      }

      return false; // Return false if an error occurs
    }
  }
}