/// Achievement and badge model for OpenAsk.
class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // 'contribution', 'helpful', 'reputation', 'streak'
  final int requiredThreshold;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requiredThreshold,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'requiredThreshold': requiredThreshold,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map, String docId) {
    return AchievementModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      category: map['category'] ?? 'contribution',
      requiredThreshold: (map['requiredThreshold'] ?? 0) as int,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null ? DateTime.tryParse(map['unlockedAt']) : null,
    );
  }
}
