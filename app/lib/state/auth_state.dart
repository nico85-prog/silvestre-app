import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/push_notifications_service.dart';

class AuthState extends ChangeNotifier {
  AuthState() {
    _auth.authStateChanges().listen(_onAuthChange);
  }

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _loading = true;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _loading;

  Future<void> _onAuthChange(fb.User? fbUser) async {
    if (fbUser == null) {
      _currentUser = null;
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      final snap = await _db.collection('users').doc(fbUser.uid).get();
      if (snap.exists) {
        _currentUser = AppUser.fromFirestore(fbUser.uid, snap.data()!);
      } else {
        _currentUser = AppUser(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Utente',
          createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
          acceptedTos: true,
        );
        await _db
            .collection('users')
            .doc(fbUser.uid)
            .set(_currentUser!.toFirestore());
      }
    } catch (e) {
      _currentUser = null;
    } finally {
      _loading = false;
      notifyListeners();
    }

    // Register FCM token for push notifications (silent fail if permission missing)
    if (_currentUser != null) {
      PushNotificationsService.registerTokenForUser(_currentUser!.id)
          .catchError((_) {});
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    required bool acceptTos,
    bool acceptMarketing = false,
    bool acceptPortfolio = false,
  }) async {
    if (!acceptTos) {
      throw AuthException(
          'Devi accettare Termini e Privacy per registrarti.');
    }
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = AppUser(
        id: cred.user!.uid,
        email: cred.user!.email!,
        displayName: displayName.trim(),
        phone: phone?.trim().isEmpty ?? true ? null : phone!.trim(),
        createdAt: DateTime.now(),
        acceptedTos: true,
        acceptedMarketing: acceptMarketing,
        acceptedPortfolioUse: acceptPortfolio,
      );
      await _db
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());
      // Send verification email (silent fail if rate-limited)
      cred.user!.sendEmailVerification().catchError((_) {});
      _currentUser = user;
      notifyListeners();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Send a password reset email to [email].
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Re-send the verification email to the current user.
  Future<void> resendVerificationEmail() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null || fbUser.emailVerified) return;
    try {
      await fbUser.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Reloads the Firebase user and returns whether email is verified.
  Future<bool> refreshEmailVerified() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return false;
    await fbUser.reload();
    final updated = _auth.currentUser;
    final verified = updated?.emailVerified ?? false;
    notifyListeners();
    return verified;
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> logout() async => _auth.signOut();

  Future<void> updateProfile({
    String? displayName,
    String? phone,
    bool? acceptMarketing,
    bool? acceptPortfolio,
  }) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      displayName: displayName,
      phone: phone,
      acceptedMarketing: acceptMarketing,
      acceptedPortfolioUse: acceptPortfolio,
    );
    await _db
        .collection('users')
        .doc(updated.id)
        .set(updated.toFirestore(), SetOptions(merge: true));
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    try {
      // Cancellazione ATOMICA via WriteBatch: o tutto o niente.
      // Evita ordini orfani se la sequenza fallisce a metà.
      final orders =
          await _db.collection('orders').where('userId', isEqualTo: uid).get();
      // Firestore batch supporta max 500 operazioni: per utenti con tanti
      // ordini, splittiamo in più batch.
      const batchLimit = 400;
      for (int start = 0; start < orders.docs.length; start += batchLimit) {
        final batch = _db.batch();
        final end = (start + batchLimit < orders.docs.length)
            ? start + batchLimit
            : orders.docs.length;
        for (int i = start; i < end; i++) {
          batch.delete(orders.docs[i].reference);
        }
        // Sull'ultimo batch elimino anche il user doc
        if (end == orders.docs.length) {
          batch.delete(_db.collection('users').doc(uid));
        }
        await batch.commit();
      }
      // Se non c'erano ordini, elimino comunque il user doc
      if (orders.docs.isEmpty) {
        await _db.collection('users').doc(uid).delete();
      }
      // Auth account come ultimo passo (richiede recent login)
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(
          'Riautenticati e riprova (sessione troppo vecchia per cancellare): ${e.message}');
    }
  }

  String _messageFor(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Esiste già un account con questa email.';
      case 'invalid-email':
        return 'Email non valida.';
      case 'weak-password':
        return 'Password troppo debole (minimo 6 caratteri).';
      case 'user-not-found':
        return 'Nessun account trovato per questa email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Password errata.';
      case 'network-request-failed':
        return 'Connessione assente. Riprova.';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova tra qualche minuto.';
      default:
        return e.message ?? 'Errore di autenticazione.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

final authState = AuthState();
