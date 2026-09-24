class UserProfileModel {
  final String id;
  final String displayName;
  final String username;
  final String? email;
  final String? bio;
  final String? photoUrl;
  final int reputation;
  final int questionCount;
  final int answerCount;
  final int followersCount;
  final int followingCount;
  final String role;
  final String status;
  final DateTime createdAt;

  UserProfileModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.email,
    this.bio,
    this.photoUrl,
    this.reputation = 0,
    this.questionCount = 0,
    this.answerCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.role = 'member',
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
      'reputation': reputation,
      'questionCount': questionCount,
      'answerCount': answerCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'role': role,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfileModel(
      id: docId,
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'],
      bio: map['bio'],
      photoUrl: map['photoUrl'],
      reputation: (map['reputation'] ?? 0) as int,
      questionCount: (map['questionCount'] ?? 0) as int,
      answerCount: (map['answerCount'] ?? 0) as int,
      followersCount: (map['followersCount'] ?? 0) as int,
      followingCount: (map['followingCount'] ?? 0) as int,
      role: map['role'] ?? 'member',
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? displayName,
    String? username,
    String? email,
    String? bio,
    String? photoUrl,
    int? reputation,
    int? questionCount,
    int? answerCount,
    int? followersCount,
    int? followingCount,
    String? role,
    String? status,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      reputation: reputation ?? this.reputation,
      questionCount: questionCount ?? this.questionCount,
      answerCount: answerCount ?? this.answerCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
