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
    final rawUnlockedAt = map['unlockedAt'];

    return AchievementModel(
      id: docId,
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      icon: (map['icon'] as String?) ?? '🏆',
      category: (map['category'] as String?) ?? 'contribution',
      requiredThreshold: (map['requiredThreshold'] as int?) ?? 0,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      unlockedAt: rawUnlockedAt != null ? DateTime.tryParse(rawUnlockedAt.toString()) : null,
    );
  }
}
