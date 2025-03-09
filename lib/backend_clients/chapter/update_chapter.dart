import 'dart:convert';

import 'package:http/http.dart';

class UpdateChapterRequest {
  final BigInt id;
  final String? name;
  final BigInt? startNode;
  final List<BigInt>? nodes;
  final List<BigInt>? characters;
  final int? status;
  final BigInt? updateAuthorId;

  UpdateChapterRequest({
    required this.id,
    this.name,
    this.startNode,
    this.nodes,
    this.characters,
    this.status,
    this.updateAuthorId,
  });

  Map<String, dynamic> toJson() {


    return {
      'id': id.toString(),
      if (name != null) 'name': name,
      if (startNode != null) 'start_node': startNode.toString(),
      if (nodes != null) 'nodes': nodes!.map((e) => e.toString()).toList(),
      if (characters != null) 'characters': characters!.map((e) => e.toString()).toList(),
      if (status != null) 'status': status,
      if (updateAuthorId != null) 'update_author_id': updateAuthorId.toString(),
    };
  }
}

Future<bool> updateChapter(UpdateChapterRequest request) async {
  print("запрос на обновлнне главы");
  print(request);
  try {
    final uri = Uri.parse('http://localhost:8080/update-chapter');

    final requestBody = request.toJson();

    print('До вызова функции');
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
      throw Exception('Ошибка при обновлении главы: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}