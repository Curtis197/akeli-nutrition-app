import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserRecord extends FirestoreRecord {
  UserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "user_health_parameter_id" field.
  String? _userHealthParameterId;
  String get userHealthParameterId => _userHealthParameterId ?? '';
  bool hasUserHealthParameterId() => _userHealthParameterId != null;

  // "user_goal_id" field.
  String? _userGoalId;
  String get userGoalId => _userGoalId ?? '';
  bool hasUserGoalId() => _userGoalId != null;

  // "user_preference_id" field.
  String? _userPreferenceId;
  String get userPreferenceId => _userPreferenceId ?? '';
  bool hasUserPreferenceId() => _userPreferenceId != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _id = castToType<int>(snapshotData['id']);
    _phoneNumber = snapshotData['phone_number'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _userHealthParameterId =
        snapshotData['user_health_parameter_id'] as String?;
    _userGoalId = snapshotData['user_goal_id'] as String?;
    _userPreferenceId = snapshotData['user_preference_id'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user');

  static Stream<UserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserRecord.fromSnapshot(s));

  static Future<UserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserRecord.fromSnapshot(s));

  static UserRecord fromSnapshot(DocumentSnapshot snapshot) => UserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserRecordData({
  String? email,
  String? displayName,
  String? uid,
  DateTime? createdTime,
  int? id,
  String? phoneNumber,
  String? photoUrl,
  String? userHealthParameterId,
  String? userGoalId,
  String? userPreferenceId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'uid': uid,
      'created_time': createdTime,
      'id': id,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'user_health_parameter_id': userHealthParameterId,
      'user_goal_id': userGoalId,
      'user_preference_id': userPreferenceId,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserRecordDocumentEquality implements Equality<UserRecord> {
  const UserRecordDocumentEquality();

  @override
  bool equals(UserRecord? e1, UserRecord? e2) {
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.id == e2?.id &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.userHealthParameterId == e2?.userHealthParameterId &&
        e1?.userGoalId == e2?.userGoalId &&
        e1?.userPreferenceId == e2?.userPreferenceId;
  }

  @override
  int hash(UserRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.uid,
        e?.createdTime,
        e?.id,
        e?.phoneNumber,
        e?.photoUrl,
        e?.userHealthParameterId,
        e?.userGoalId,
        e?.userPreferenceId
      ]);

  @override
  bool isValidKey(Object? o) => o is UserRecord;
}
