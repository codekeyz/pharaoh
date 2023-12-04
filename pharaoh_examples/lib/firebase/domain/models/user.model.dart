class User {
  String uid;
  String email;
  bool emailVerified;
  String displayName;
  String? photoUrl;
  String? phoneNumber;
  bool disabled;
  UserMetadata metadata;

  User({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.displayName,
    required this.photoUrl,
    required this.phoneNumber,
    required this.disabled,
    required this.metadata,
  });

  static User fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'],
        email: json['email'],
        emailVerified: json['emailVerified'],
        displayName: json['displayName'],
        photoUrl: json['photoUrl'],
        phoneNumber: json['phoneNumber'],
        disabled: json['disabled'],
        metadata: UserMetadata.fromJson(json['metadata']),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'emailVerified': emailVerified,
        "displayName": displayName,
        "photoUrl": photoUrl,
        "phoneNumber": phoneNumber,
        "disabled": disabled,
        'metadata': metadata.toJson(),
      };
}

class UserMetadata {
  DateTime creationTime;
  DateTime? lastSignInTime;
  DateTime? lastRefreshTime;

  UserMetadata({
    required this.creationTime,
    required this.lastRefreshTime,
    required this.lastSignInTime,
  });

  static UserMetadata fromJson(Map<String, dynamic> json) => UserMetadata(
        creationTime: DateTime.parse(json['creationTime']),
        lastSignInTime: json['lastSignInTime'] == null
            ? null
            : DateTime.parse(json['lastSignInTime']),
        lastRefreshTime: json['lastRefreshTime'] == null
            ? null
            : DateTime.parse(json['lastRefreshTime']),
      );

  Map<String, dynamic> toJson() => {
        "creationTime": creationTime.toUtc().toIso8601String(),
        "lastSignInTime": lastSignInTime?.toUtc().toIso8601String(),
        'lastRefreshTime': lastRefreshTime?.toUtc().toIso8601String(),
      };
}
