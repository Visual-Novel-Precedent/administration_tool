import 'dart:convert';

import 'package:http/http.dart';

BigInt? safeBigIntParse(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final trimmedValue = value.trim();
  if (!trimmedValue.contains(RegExp(r'^[-+]?[0-9]+$'))) {
    throw FormatException('Строка "$trimmedValue" не является допустимым числом');
  }

  try {
    return BigInt.parse(trimmedValue);
  } catch (e) {
    throw FormatException('Ошибка парсинга BigInt для значения "$trimmedValue": $e');
  }
}

Future<BigInt> createNode(BigInt chapterId, String slug, BigInt parentId) async {
  try {
    final uri = Uri.parse('http://localhost:8080/create-node');

    final requestBody = {
      'chapter_id': chapterId.toString(),
      'slug': slug,
      'parent': parentId.toString(),
    };

    print("req create node");
    print(requestBody);

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    print("попытка создать узел");
    print(response.body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);

      if (jsonMap['id'] == null) {
        throw Exception('Отсутствует идентификатор в ответе сервера');
      }

      return safeBigIntParse(jsonMap['id'].toString()) ?? BigInt.from(0);
    } else {
      throw Exception('Ошибка при создании узла: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}