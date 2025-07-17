import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:echopay/main.dart';
import 'package:echopay/pages/home_page.dart';

class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  UserDataService._internal();

  static final UserDataService _instance = UserDataService._internal();

  factory UserDataService() => _instance;

  Map<String, dynamic>? _cachedUserData;

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> initializeUserData(User user) async {
    final docRef = _firestore.collection('Users').doc(user.uid);

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print(navigatorKey.currentContext == null);
        await _createUserDocument(docRef, user);
      }
    } catch (e) {
      print("Error initializing user data: $e");
    }
  }

  // Helper to create user document
  Future<void> _createUserDocument(DocumentReference docRef, User user) async {
    final Map<String, dynamic> initialData = {
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    _cachedUserData = initialData;
    WriteBatch batch = _firestore.batch();
    batch.set(docRef, initialData);

    await batch.commit();
  }
}
