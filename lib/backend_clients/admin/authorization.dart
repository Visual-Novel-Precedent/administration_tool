import 'dart:convert';

import 'package:http/http.dart';

import '../../models/admin.dart';

class RequestBody {
  final String email;
  final String password;

  RequestBody({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

Future<Admin> authorizationAdmin(String email, String password, {BigInt? id}) async {
  try {
    final uri = Uri.parse('http://localhost:8080/admin-authorization');

    final request = RequestBody(
      email: email,
      password: password,
    );

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
      print(response.body);
      final jsonData = jsonDecode(response.body);
      var res = Admin.fromJson(jsonData);
      return res;
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