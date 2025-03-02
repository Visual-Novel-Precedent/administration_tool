
import 'dart:convert';

import 'package:http/http.dart';

Future<bool> rejectRequest(BigInt requestId) async {
  try {
    final uri = Uri.parse('http://localhost:8080/reject-request');

    final requestBody = {
      'id_request': requestId.toString(),
    };

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Ошибка при отклонении запроса: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при отклонении запроса: $e');
    rethrow;
  }
}