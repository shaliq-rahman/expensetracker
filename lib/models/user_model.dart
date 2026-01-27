
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? dob;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.dob,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'dob': dob?.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      dob: map['dob'] != null ? DateTime.tryParse(map['dob']) : null,
      fcmToken: map['fcmToken'],
    );
  }
}
