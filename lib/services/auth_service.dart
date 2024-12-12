import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart'; // For SHA-256
import 'dart:convert'; // For utf8 encoding
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


// Inside AuthService
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userData'); // Returns true if 'userData' exists
  }


  // Login using school ID (which is the document ID in Firestore)
  Future<Map<String, dynamic>> loginWithSchoolId(String schoolId, String password) async {
    try {
      // Fetch the user document from Firestore using the school ID as the document ID
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(schoolId).get();

      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found.'};
      }

      // Hash the provided password using SHA-256
      String hashedPassword = _hashPassword(password);

      // Check if the provided hashed password matches the stored one
      String storedPassword = userDoc['password']; // This should be the hashed password stored in Firestore
      if (storedPassword != hashedPassword) {
        return {'success': false, 'message': 'Invalid credentials. Please try again.'};
      }

      // Save user data locally (SharedPreferences), excluding the password
      await _saveUserDataLocally(userDoc);

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userDoc.data(), // Returning the user data from Firestore
      };
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
  Future<void> _saveUserDataLocally(DocumentSnapshot userDoc) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save user details (ensure that the keys match your Firestore document fields)
    await prefs.setString('user_first_name', userDoc['first_name']);
    await prefs.setString('user_last_name', userDoc['last_name']);
    await prefs.setString('user_email', userDoc['email']);
    await prefs.setString('user_school_id', userDoc.id); // Saving the school ID (document ID)
    // Do not store the password in SharedPreferences for security reasons

    await prefs.setBool('is_logged_in', true);
  }

  // Log out the user and clear SharedPreferences
// Log out the user and clear SharedPreferences except for certain keys
  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // List of keys to retain
    List<String> keysToRetain = [
      'first_time',  // Retaining the key for first-time app launch (example)
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


  // Update user profile (first name, last name, school ID, and password)
  Future<bool> updateProfile(String schoolId, String firstName, String lastName, String schoolIdField, String password) async {
    try {
      // Prepare user data for update
      Map<String, dynamic> updatedData = {
        'first_name': firstName,
        'last_name': lastName,
        'school_id': schoolIdField, // Optionally update school ID if required
      };

      // If a new password is provided, hash it and update it
      if (password.isNotEmpty) {
        updatedData['password'] = _hashPassword(password); // Hash the password before saving
      }

      // Update the user document in Firestore
      await _firestore.collection('users').doc(schoolId).update(updatedData);

      // Optionally, save updated data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);
      await prefs.setString('user_email', schoolIdField); // Update email if needed
      await prefs.setString('user_school_id', schoolId); // Update school ID in SharedPreferences

      return true; // Return true if update was successful
    } catch (e) {
      print('Error updating profile: $e');
      return false; // Return false if an error occurs
    }
  }
}
