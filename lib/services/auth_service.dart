import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/unit_model.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register Landlord (only landlords can self-register)
  Future<Map<String, dynamic>> registerLandlord({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Create auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return {'success': false, 'message': 'Failed to create account'};
      }

      // Create user model
      UserModel newUser = UserModel(
        uid: credential.user!.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: UserRole.landlord,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      return {'success': true, 'user': newUser};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Create Manager (by Landlord)
  Future<Map<String, dynamic>> createManager({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String landlordId,
    required String propertyId,
    required String location,
  }) async {
    try {
      // Create auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return {'success': false, 'message': 'Failed to create manager account'};
      }

      // Create user model
      UserModel newManager = UserModel(
        uid: credential.user!.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: UserRole.manager,
        assignedLandlordId: landlordId,
        assignedPropertyId: propertyId,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newManager.toMap());

      // Update property with manager ID
      await _firestore.collection('properties').doc(propertyId).update({
        'managerId': credential.user!.uid,
      });

      // Sign out the newly created user (landlord stays logged in)
      await _auth.signOut();

      return {'success': true, 'manager': newManager};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Create Tenant (by Landlord or Manager)
  Future<Map<String, dynamic>> createTenant({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String landlordId,
    required String propertyId,
    required String unitId,
    String? ninOrPassport,
    String? nextOfKin,
    String? nextOfKinContact,
  }) async {
    try {
      // Store current user to re-login after creating tenant
    
      
      // Create auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return {'success': false, 'message': 'Failed to create tenant account'};
      }

      // Create user model
      UserModel newTenant = UserModel(
        uid: credential.user!.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: UserRole.tenant,
        assignedLandlordId: landlordId,
        assignedPropertyId: propertyId,
        assignedUnitId: unitId,
        ninOrPassport: ninOrPassport?.trim(),
        nextOfKin: nextOfKin?.trim(),
        nextOfKinContact: nextOfKinContact?.trim(),
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newTenant.toMap());

      // Update unit with tenant ID and status
      await _firestore.collection('units').doc(unitId).update({
        'tenantId': credential.user!.uid,
        'status': UnitStatus.occupied.name,
        'leaseStartDate': Timestamp.fromDate(DateTime.now()),
      });

      // Update property occupied units count
      await _firestore.collection('properties').doc(propertyId).update({
        'occupiedUnits': FieldValue.increment(1),
      });

      return {'success': true, 'tenant': newTenant};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return {'success': false, 'message': 'Login failed'};
      }

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {'success': false, 'message': 'User data not found'};
      }

      UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

      // Check if user is active
      if (!user.isActive) {
        await _auth.signOut();
        return {'success': false, 'message': 'Your account has been deactivated'};
      }

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return {'success': true, 'message': 'Password changed successfully'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Get friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication error: $code';
    }
  }
}