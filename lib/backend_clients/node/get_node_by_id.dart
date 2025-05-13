import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../models/node.dart';

Future<ChapterNode?> getNodeById(BigInt nodeId) async {
  try {
    final url = Uri.parse('http://localhost:8080/get-node-by-id');

    final requestBody = {'id': nodeId.toString()};

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      print("получаем ответ на один узел");
      print(response.body);
      final jsonData = jsonDecode(response.body);

      print(ChapterNode.fromJson(jsonData['node']));

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