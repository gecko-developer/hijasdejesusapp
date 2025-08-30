import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 👤 Save user details to Firestore during registration
  Future<void> saveUserDetails({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final userModel = UserModel(
        id: user.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim().toLowerCase(),
        phoneNumber: phoneNumber?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      // Update Firebase Auth display name for consistency
      await user.updateDisplayName('$firstName $lastName');
      
      print('✅ User details saved successfully');
    } catch (e) {
      print('❌ Error saving user details: $e');
      rethrow;
    }
  }

  /// 📖 Get current user details from Firestore
  Future<UserModel?> getCurrentUserDetails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error getting user details: $e');
      return null;
    }
  }

  /// 🔄 Update user details
  Future<void> updateUserDetails({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (firstName != null) updates['firstName'] = firstName.trim();
      if (lastName != null) updates['lastName'] = lastName.trim();
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(updates);

      // Update display name if first or last name changed
      if (firstName != null || lastName != null) {
        final currentData = await getCurrentUserDetails();
        if (currentData != null) {
          final newFirstName = firstName ?? currentData.firstName;
          final newLastName = lastName ?? currentData.lastName;
          await user.updateDisplayName('$newFirstName $newLastName');
        }
      }

      print('✅ User details updated successfully');
    } catch (e) {
      print('❌ Error updating user details: $e');
      rethrow;
    }
  }

  /// 📝 Get user's first name for welcome messages
  Future<String> getUserFirstName() async {
    try {
      final userDetails = await getCurrentUserDetails();
      if (userDetails != null && userDetails.firstName.isNotEmpty) {
        return userDetails.firstName;
      }

      // Fallback to display name or email
      final user = _auth.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        return user.displayName!.split(' ').first;
      }

      if (user?.email != null) {
        return user!.email!.split('@').first;
      }

      return 'User';
    } catch (e) {
      print('❌ Error getting user first name: $e');
      return 'User';
    }
  }

  /// 🗑️ Delete user data (for account deletion)
  Future<void> deleteUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete user document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete();

      print('✅ User data deleted successfully');
    } catch (e) {
      print('❌ Error deleting user data: $e');
      rethrow;
    }
  }

  /// 📊 Check if user has completed profile setup
  Future<bool> isProfileComplete() async {
    try {
      final userDetails = await getCurrentUserDetails();
      return userDetails != null && 
             userDetails.firstName.isNotEmpty && 
             userDetails.lastName.isNotEmpty;
    } catch (e) {
      print('❌ Error checking profile completion: $e');
      return false;
    }
  }
}
