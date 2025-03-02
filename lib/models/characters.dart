class Character {
  final BigInt id;
  final String name;
  final String slug;
  final String color;
  final Map<BigInt, BigInt> emotions;

  Character({
    required this.id,
    required this.name,
    required this.slug,
    required this.color,
    this.emotions = const {},
  });

  // Метод для безопасного парсинга BigInt из строки
  static BigInt safeBigIntParse(String? value) {
    if (value == null || value.isEmpty) {
      return BigInt.zero;
    }
    try {
      return BigInt.parse(value);
    } catch (e) {
      print('Ошибка парсинга BigInt: $value - $e');
      return BigInt.zero;
    }
  }

  // Метод для безопасного парсинга Map<BigInt, BigInt>
  static Map<BigInt, BigInt> safeBigIntMapParse(Map<String, dynamic>? map) {
    if (map == null) return {};
    return map.map((key, value) {
      try {
        return MapEntry(safeBigIntParse(key), safeBigIntParse(value.toString()));
      } catch (e) {
        print('Ошибка парсинга BigInt Map: $key - $value - $e');
        return MapEntry(BigInt.zero, BigInt.zero);
      }
    });
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: safeBigIntParse(json['Id']),
      name: json['Name'] ?? '',
      slug: json['Slug'] ?? '',
      color: json['Color'] ?? '',
      emotions: safeBigIntMapParse(json['Emotions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id.toString(),
      'Name': name,
      'Slug': slug,
      'Color': color,
      'Emotions': emotions.map((key, value) =>
          MapEntry(key.toString(), value.toString())),
    };
  }

  @override
  String toString() {
    return 'Character(id: $id, name: $name, slug: $slug, '
        'color: $color, emotions: $emotions)';
  }
}