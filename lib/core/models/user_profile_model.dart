/// User Profile domain model for OpenAsk.
/// Private account credentials and security tokens are NEVER stored in public profiles.
class UserProfileModel {
  final String id;
  final String displayName;
  final String username;
  final String? email;
  final String? bio;
  final String? photoUrl;
  final String? country;
  final String language;
  final String? timezone;
  final String? website;
  final List<String> interests;
  final int reputation;
  final int questionCount;
  final int answerCount;
  final int followersCount;
  final int followingCount;
  final String role; // 'member', 'moderator', 'admin'
  final String status; // 'active', 'suspended', 'banned'
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.email,
    this.bio,
    this.photoUrl,
    this.country,
    this.language = 'en',
    this.timezone,
    this.website,
    this.interests = const [],
    this.reputation = 0,
    this.questionCount = 0,
    this.answerCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.role = 'member',
    this.status = 'active',
    this.isPrivate = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
      'country': country,
      'language': language,
      'timezone': timezone,
      'website': website,
      'interests': interests,
      'reputation': reputation,
      'questionCount': questionCount,
      'answerCount': answerCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'role': role,
      'status': status,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
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
      country: map['country'],
      language: map['language'] ?? 'en',
      timezone: map['timezone'],
      website: map['website'],
      interests: List<String>.from(map['interests'] ?? []),
      reputation: (map['reputation'] ?? 0) as int,
      questionCount: (map['questionCount'] ?? 0) as int,
      answerCount: (map['answerCount'] ?? 0) as int,
      followersCount: (map['followersCount'] ?? 0) as int,
      followingCount: (map['followingCount'] ?? 0) as int,
      role: map['role'] ?? 'member',
      status: map['status'] ?? 'active',
      isPrivate: map['isPrivate'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? displayName,
    String? username,
    String? email,
    String? bio,
    String? photoUrl,
    String? country,
    String? language,
    String? timezone,
    String? website,
    List<String>? interests,
    int? reputation,
    int? questionCount,
    int? answerCount,
    int? followersCount,
    int? followingCount,
    String? role,
    String? status,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      website: website ?? this.website,
      interests: interests ?? this.interests,
      reputation: reputation ?? this.reputation,
      questionCount: questionCount ?? this.questionCount,
      answerCount: answerCount ?? this.answerCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      role: role ?? this.role,
      status: status ?? this.status,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
