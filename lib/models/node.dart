class ChapterNode {
  final BigInt id;
  final String slug;
  final Map<int, Event> events;
  final BigInt chapterId;
  late BigInt music;
  late BigInt background;
  final Branching branching;
  final EndInfo end;
  final String comment;

  ChapterNode({
    required this.id,
    required this.slug,
    required this.events,
    required this.chapterId,
    required this.music,
    required this.background,
    required this.branching,
    required this.end,
    required this.comment,
  });

  // Методы для безопасной конвертации BigInt
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

  static Map<int, Event> safeIntEventMapParse(
      dynamic? map, Function(dynamic) eventFactory) {
    if (map == null) return {};

    if (map is! Map) {
      print('Warning: Expected Map, got ${map.runtimeType}');
      return {};
    }

    return map.map((key, value) {
      try {
        final int keyInt = int.parse(key.toString());
        return MapEntry(keyInt, eventFactory(value));
      } catch (e) {
        print('Ошибка парсинга Map<int, Event>: $key - $value - $e');
        return MapEntry(0, eventFactory({}));
      }
    });
  }

  factory ChapterNode.fromJson(Map<String, dynamic> json) {
    // Добавляем дополнительные проверки типов
    Map<int, Event>? eventsMap;

    if (json['Events'] != null) {
      if (json['Events'] is Map) {
        eventsMap = safeIntEventMapParse(
            json['Events'], (value) => Event.fromJson(value));
      } else if (json['Events'] is int) {
        print('Warning: Events is int, converting to empty map');
        eventsMap = {};
      }
    }

    return ChapterNode(
      id: json['Id'] != null ? safeBigIntParse(json['Id']) : BigInt.zero,
      slug: json['Slug'] ?? '',
      events: eventsMap ?? {},
      chapterId: json['ChapterId'] != null
          ? safeBigIntParse(json['ChapterId'])
          : BigInt.zero,
      music:
          json['Music'] != null ? safeBigIntParse(json['Music']) : BigInt.zero,
      background: json['Background'] != null
          ? safeBigIntParse(json['Background'])
          : BigInt.zero,
      branching: json['Branching'] != null
          ? Branching.fromJson(json['Branching'])
          : Branching(flag: false, condition: {}),
      end: json['End'] != null
          ? EndInfo.fromJson(json['End'])
          : EndInfo(flag: false, endResult: '', endText: ''),
      comment: json['Comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id.toString(),
      'Slug': slug,
      'Events':
          events.map((key, value) => MapEntry(key.toString(), value.toJson())),
      'ChapterId': chapterId.toString(),
      'Music': music.toString(),
      'Background': background.toString(),
      'Branching': branching.toJson(),
      'End': end.toJson(),
      'Comment': comment.toString(),
    };
  }

  @override
  String toString() {
    return 'Node(id: $id, slug: $slug, events: $events, chapterId: $chapterId, '
        'music: $music, background: $background, branching: $branching, end: $end, comment: $comment)';
  }
}

class Branching {
  final bool flag;
  final Map<String, BigInt> condition;

  Branching({
    required this.flag,
    required this.condition,
  });

  static Map<String, BigInt> safeStringBigIntMapParse(
      Map<String, dynamic>? map) {
    if (map == null) return {};
    return map.map((key, value) {
      try {
        return MapEntry(key, BigInt.parse(value.toString()));
      } catch (e) {
        print('Ошибка парсинга Map<String, BigInt>: $key - $value - $e');
        return MapEntry(key, BigInt.zero);
      }
    });
  }

  factory Branching.fromJson(Map<String, dynamic> json) {
    return Branching(
      flag: json['branching_flag'] ?? false,
      condition: safeStringBigIntMapParse(json['condition']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Flag': flag,
      'Condition':
          condition.map((key, value) => MapEntry(key, value.toString())),
    };
  }

  @override
  String toString() {
    return 'Branching(flag: $flag, condition: $condition)';
  }
}

class EndInfo {
  final bool flag;
  final String endResult;
  final String endText;

  EndInfo({
    required this.flag,
    required this.endResult,
    required this.endText,
  });

  factory EndInfo.fromJson(Map<String, dynamic> json) {
    return EndInfo(
      flag: json['end_flag'] ?? false,
      endResult: json['end_result'] ?? '',
      endText: json['end_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'end_flag': flag,
      'end_result': endResult,
      'end_text': endText,
    };
  }

  @override
  String toString() {
    return 'EndInfo(flag: $flag, endResult: $endResult, endText: $endText)';
  }
}

class Event {
  final BigInt type;
  final BigInt character;
  final BigInt sound;
  final Map<BigInt, Map<BigInt, BigInt>> charactersInEvent;
  final String text;

  Event({
    required this.type,
    required this.character,
    required this.sound,
    required this.charactersInEvent,
    required this.text,
  });

  static Map<BigInt, Map<BigInt, BigInt>> safeBigIntMapOfMapsParse(
      Map<String, dynamic>? map) {
    if (map == null) return {};
    return map.map((key, value) {
      try {
        final BigInt keyBig = BigInt.parse(key);
        final innerMap =
            (value as Map<String, dynamic>).map((innerKey, innerValue) {
          try {
            return MapEntry(
                BigInt.parse(innerKey), BigInt.parse(innerValue.toString()));
          } catch (e) {
            print(
                'Ошибка парсинга внутренней карты: $innerKey - $innerValue - $e');
            return MapEntry(BigInt.zero, BigInt.zero);
          }
        });
        return MapEntry(keyBig, innerMap);
      } catch (e) {
        print(
            'Ошибка парсинга Map<BigInt, Map<BigInt, BigInt>>: $key - $value - $e');
        return MapEntry(BigInt.zero, {});
      }
    });
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      type: safeBigIntParse(json['type']),
      character: safeBigIntParse(json['character']),
      sound: safeBigIntParse(json['sound']),
      charactersInEvent: safeBigIntMapOfMapsParse(json['characters_in_event']),
      text: json['text'] ?? '',
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'character': character.toString(),
      'sound': sound.toString(),
      'characters_in_event': charactersInEvent.map(
        (key, value) => MapEntry(
            key.toString(),
            value.map((innerKey, innerValue) =>
                MapEntry(innerKey.toString(), innerValue.toString()))),
      ),
      'text': text,
    };
  }

  @override
  String toString() {
    return 'Event(type: $type, character: $character, sound: $sound, '
        'charactersInEvent: $charactersInEvent, text: $text)';
  }
}
