import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;

  AuthCubit({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        super(const AuthInitial()) {
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(
          userId: user.uid,
          email: user.email ?? '',
        ));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      emit(const AuthLoading());
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // State will be updated by authStateChanges listener
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'An error occurred during sign in'));
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      emit(const AuthLoading());
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(username);
      // State will be updated by authStateChanges listener
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'An error occurred during registration'));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> signOut() async {
    try {
      emit(const AuthLoading());
      await _auth.signOut();
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError('Sign out failed: ${e.toString()}'));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      emit(const AuthLoading());
      await _auth.sendPasswordResetEmail(email: email);
      emit(const AuthUnauthenticated());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Failed to send reset email'));
    } catch (e) {
      emit(AuthError('Password reset failed: ${e.toString()}'));
    }
  }
}
