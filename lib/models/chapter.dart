class Chapter {
  final BigInt id;
  final String name;
  final BigInt startNode;
  final List<BigInt> nodes;
  final List<BigInt> characters;
  final int status;
  final BigInt author;

  Chapter({
    required this.id,
    required this.name,
    required this.startNode,
    required this.nodes,
    required this.characters,
    required this.status,
    required this.author,
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

  // Метод для безопасного парсинга списка BigInt
  static List<BigInt> safeBigIntListParse(List<dynamic>? list) {
    if (list == null) return [];
    return list.map((e) => safeBigIntParse(e.toString()) ?? BigInt.zero).toList();
  }

  // Метод для безопасного парсинга Map<DateTime, BigInt>
  static Map<DateTime, BigInt> safeDateTimeBigIntMapParse(Map<String, dynamic>? map) {
    if (map == null) return {};
    return map.map((key, value) {
      try {
        final dateTime = DateTime.parse(key);
        return MapEntry(dateTime, safeBigIntParse(value.toString()) ?? BigInt.zero);
      } catch (e) {
        print('Ошибка парсинга даты или BigInt: $key - $value - $e');
        return MapEntry(DateTime.now(), BigInt.zero);
      }
    });
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: safeBigIntParse(json['Id']),
      name: json['Name'] ?? '',
      startNode: safeBigIntParse(json['StartNode']),
      nodes: safeBigIntListParse(json['Nodes']),
      characters: safeBigIntListParse(json['Characters']),
      status: json['Status'] ?? 0,
      author: safeBigIntParse(json['Author']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'start_node': startNode.toString(),
      'nodes': nodes.map((e) => e.toString()).toList(),
      'characters': characters.map((e) => e.toString()).toList(),
      'status': status,
      'author': author.toString(),
    };
  }

  @override
  String toString() {
    return 'Chapter(id: $id, name: $name, startNode: $startNode, '
        'nodes: $nodes, characters: $characters, status: $status, author: $author)';
  }
}