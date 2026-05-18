import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class OperatorsState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<AppUser> _operators = [];
  StreamSubscription? _sub;

  List<AppUser> get operators => List.unmodifiable(_operators);

  void watch() {
    _sub?.cancel();
    _sub = _db
        .collection('users')
        .where('role', whereIn: ['staff', 'admin'])
        .snapshots()
        .listen((snap) {
      _operators = snap.docs
          .map((d) => AppUser.fromFirestore(d.id, d.data()))
          .toList();
      _operators.sort((a, b) {
        if (a.role != b.role) {
          // admin first
          return a.role == 'admin' ? -1 : 1;
        }
        return a.displayName.compareTo(b.displayName);
      });
      notifyListeners();
    });
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
  }

  /// Promotes an existing user (by email) to 'staff'.
  /// Throws if email not found or if user already has higher role.
  Future<void> promoteByEmail(String email, {String role = 'staff'}) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty || !clean.contains('@')) {
      throw OperatorException('Email non valida.');
    }
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: clean)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw OperatorException(
          'Nessun utente registrato con questa email. '
          'L\'operatore deve prima registrarsi dall\'app come cliente.');
    }
    final doc = query.docs.first;
    final current = doc.data()['role'] as String? ?? 'customer';
    if (current == role) {
      throw OperatorException('Utente già "$role".');
    }
    if (current == 'admin' && role == 'staff') {
      throw OperatorException(
          'Non posso retrocedere un admin a staff. Rimuovilo prima.');
    }
    await doc.reference.update({'role': role});
  }

  /// Removes an operator (sets role back to 'customer').
  Future<void> demote(String uid) async {
    await _db.collection('users').doc(uid).update({'role': 'customer'});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class OperatorException implements Exception {
  final String message;
  OperatorException(this.message);
  @override
  String toString() => message;
}

final operatorsState = OperatorsState();
