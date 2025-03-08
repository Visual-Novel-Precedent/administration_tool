import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/node.dart';

Future<ChapterNode?> getNodeById(BigInt nodeId) async {
  try {
    // Создаем URL для запроса
    final url = Uri.parse('http://localhost:8080/get-node-by-id');

    // Подготавливаем тело запроса
    final requestBody = {'id': nodeId.toString()};

    // Настройка заголовков
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    // Отправляем POST-запрос
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    // Проверяем статус ответа
    if (response.statusCode == 200) {
      print("получаем ответ на один узел");
      print(response.body);
      // Извлекаем данные из JSON ответа
      final jsonData = jsonDecode(response.body);

      print(ChapterNode.fromJson(jsonData['node']));

      // Создаем объект ChapterNode из полученных данных
      return ChapterNode.fromJson(jsonData['node']);
    } else {
      print('Ошибка при получении узла: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Ошибка при выполнении запроса: $e');
    return null;
  }
}