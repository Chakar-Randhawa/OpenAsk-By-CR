class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final int followerCount;
  final int questionCount;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    this.followerCount = 0,
    this.questionCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'followerCount': followerCount,
      'questionCount': questionCount,
      'isActive': isActive,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'HelpCircle',
      followerCount: (map['followerCount'] ?? 0) as int,
      questionCount: (map['questionCount'] ?? 0) as int,
      isActive: map['isActive'] ?? true,
    );
  }
}
