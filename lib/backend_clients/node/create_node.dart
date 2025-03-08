
import 'dart:convert';

import 'package:http/http.dart';

Future<BigInt> createNode(BigInt chapterId, String slug) async {
  try {
    final uri = Uri.parse('http://localhost:8080/create-node');

    final requestBody = {
      'chapter_id': chapterId.toString(),
      'slug': slug,
    };

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return BigInt.parse(jsonMap['id'].toString());
    } else {
      throw Exception('Ошибка при создании узла: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}