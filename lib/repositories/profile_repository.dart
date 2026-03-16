import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_profile.dart';

export '../models/app_user_profile.dart';

class ProfileRepository {
  ProfileRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('user_profiles');

  Future<AppUserProfile> getOrCreateProfile(String uid) async {
    final snapshot = await _profiles.doc(uid).get();
    if (snapshot.exists && snapshot.data() != null) {
      return AppUserProfile.fromMap(snapshot.data()!);
    }

    final profile = AppUserProfile(
      uid: uid,
      firstName: '',
      locationLabel: '',
      topics: const [],
      onboardingComplete: false,
      notificationPreferences: NotificationPreference.defaults(),
    );

    await _profiles.doc(uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return profile;
  }

  Future<void> saveProfile(AppUserProfile profile) async {
    await _profiles.doc(profile.uid).set(
      {
        ...profile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveMessagingToken({
    required String uid,
    required String token,
  }) async {
    await _profiles.doc(uid).set(
      {
        'uid': uid,
        'messagingTokens': FieldValue.arrayUnion(<String>[token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<AppUserProfile> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{'uid': uid};
      return AppUserProfile.fromMap(data);
    });
  }
}
