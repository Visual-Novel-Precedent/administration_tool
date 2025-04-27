import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

class RegistrationRequest {
  final String email;
  final String name;
  final String password;

  RegistrationRequest({
    required this.email,
    required this.name,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'password': password,
    };
  }
}

Future<int?> registerAdmin(String email, String name, String password) async {
  try {
    final uri = Uri.parse('http://localhost:8080/admin-registration');

    // Создаем экземпляр RegistrationRequest
    final request = RegistrationRequest(
      email: email,
      name: name,
      password: password,
    );

    print("запрос на регистрацию админа ");
    print(request);

    // Отправляем POST-запрос напрямую
    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(request.toJson()),
    );

    print('Заголовки ответа:');
    response.headers.forEach((key, value) {
      print('$key: $value');
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      return jsonData['id'];
    } else {
      throw Exception('Ошибка регистрации: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    if (e is ClientException) {
      print('Дополнительная информация о ClientException:');
      print('Сообщение: $e');
    }
    rethrow;
  }
}