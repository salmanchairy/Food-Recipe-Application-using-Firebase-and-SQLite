class RecipeField {
  static final List<String> values = [
    id,
    userId,
    title,
    imageUrl,
    description,
    instructions,
    calories,
    duration,
    rating,
    category,
  ];

  static const String id = 'id';
  static const String userId = 'userId';
  static const String title = 'title';
  static const String imageUrl = 'imageUrl';
  static const String description = 'description';
  static const String instructions = 'instructions';
  static const String calories = 'calories';
  static const String duration = 'duration';
  static const String rating = 'rating';
  static const String category = 'category';
}

class Recipe {
  final int? id;
  final String userId;
  final String title;
  final String? imageUrl;
  final String description;
  final String instructions;
  final int calories;
  final int duration;
  final double rating;
  final String category;
  final bool isFavorite;

  const Recipe({
    this.id,
    required this.userId,
    required this.title,
    this.imageUrl,
    required this.description,
    required this.instructions,
    required this.calories,
    required this.duration,
    required this.rating,
    this.category = 'Popular',
    this.isFavorite = false,
  });

  /// Copy object (dipakai saat update)
  Recipe copy({
    int? id,
    String? userId,
    String? title,
    String? imageUrl,
    String? description,
    String? instructions,
    int? calories,
    int? duration,
    double? rating,
    String? category,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      calories: calories ?? this.calories,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// From SQLite
  static Recipe fromJson(Map<String, dynamic> json) => Recipe(
        id: json[RecipeField.id] as int?,
        userId: json[RecipeField.userId]?.toString() ?? '',
        title: json[RecipeField.title]?.toString() ?? '',
        imageUrl: json[RecipeField.imageUrl]?.toString(),
        description: json[RecipeField.description]?.toString() ?? '',
        instructions: json[RecipeField.instructions]?.toString() ?? '',
        calories: json[RecipeField.calories] as int? ?? 0,
        duration: json[RecipeField.duration] as int? ?? 0,
        rating: (json[RecipeField.rating] as num?)?.toDouble() ?? 0.0,
        category: json[RecipeField.category]?.toString() ?? 'Popular',
        isFavorite: false,
      );

  /// To SQLite
  Map<String, dynamic> toJson() => {
        RecipeField.id: id,
        RecipeField.userId: userId,
        RecipeField.title: title,
        RecipeField.imageUrl: imageUrl,
        RecipeField.description: description,
        RecipeField.instructions: instructions,
        RecipeField.calories: calories,
        RecipeField.duration: duration,
        RecipeField.rating: rating,
        RecipeField.category: category,
      };
}
