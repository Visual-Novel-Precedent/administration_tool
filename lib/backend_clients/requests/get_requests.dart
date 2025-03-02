import 'dart:convert';


import 'package:http/http.dart';

import '../../models/request.dart';

class GetRequestsRequest {
  final BigInt userId;

  GetRequestsRequest({required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId.toString(),
    };
  }
}

class RequestsResponse {
  final List<Requests> requests;

  RequestsResponse({required this.requests});

  factory RequestsResponse.fromJson(Map<String, dynamic> json) {
    List<Requests> requestsList = [];

    if (json['my_requests'] != null) {
      json['my_requests'].forEach((requestJson) {
        requestsList.add(Requests.fromJson(requestJson));
      });
    }

    return RequestsResponse(requests: requestsList);
  }
}

Future<List<Requests>> getRequestsByUserId(BigInt userId) async {
  try {
    final uri = Uri.parse('http://localhost:8080/my-requests');

    final requestBody = {
      'id': userId.toString(),
    };

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      print("кesp requests");
      print(response.body);
      print(jsonDecode(response.body));
      final RequestsResponse requestsResponse = RequestsResponse.fromJson(jsonDecode(response.body));
      print("запросы");
      print(requestsResponse.requests);
      return requestsResponse.requests;
    } else {
      throw Exception('Ошибка при получении запросов: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки рпи получении запросов: $e');
    rethrow;
  }
}