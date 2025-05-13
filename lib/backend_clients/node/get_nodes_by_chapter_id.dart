import 'dart:convert';

import 'package:http/http.dart';

import '../../models/node.dart';

class ChapterNodes {
  final List<ChapterNode> nodes;
  final ChapterNode? startNode;

  ChapterNodes({
    required this.nodes,
    required this.startNode,
  });

  factory ChapterNodes.fromJson(Map<String, dynamic> json) {
    void debugType(String key, dynamic value) {
      print('$key: ${value.runtimeType}');
    }

    debugType('nodes', json['nodes']);
    debugType('start_node', json['start_node']);


    // Обрабатываем nodes
    List<ChapterNode> processedNodes = [];
    dynamic nodesValue = json['nodes'];

    if (nodesValue != null) {
      if (nodesValue is int) {
        print('Warning: nodes is int, converting to empty list');
        processedNodes = [];
      } else if (nodesValue is Map<String, dynamic>) {
        processedNodes = (nodesValue['items'] ?? [])
            .map((nodeJson) => ChapterNode.fromJson(nodeJson))
            .toList();
      } else if (nodesValue is List<dynamic>) {
        processedNodes = nodesValue
            .map((nodeJson) => ChapterNode.fromJson(nodeJson))
            .toList();
      }
    }

    ChapterNode? processedStartNode;
    dynamic startNodeValue = json['start_node'];

    if (startNodeValue != null) {
      if (startNodeValue is int) {
        print('Warning: start_node is int, setting to null');
        processedStartNode = null;
      } else if (startNodeValue is Map<String, dynamic>) {
        processedStartNode = ChapterNode.fromJson(startNodeValue);
      }
    }

    print("получили ве узлы");
    print(processedNodes);
    print(processedStartNode);

    return ChapterNodes(
      nodes: processedNodes,
      startNode: processedStartNode,
    );
  }

  @override
  String toString() {
    return 'ChapterNodes('
        'nodes: ${nodes.length} items, '
        'startNode: ${startNode != null ? startNode.toString() : "null"}'
        ')';
  }
}

Future<ChapterNodes> getNodesByChapterId(BigInt chapterId) async {
  try {
    final uri = Uri.parse('http://localhost:8080/get-nodes-by-chapter');
    final requestBody = {
      'chapter_id': chapterId.toString(),
    };

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedResponse = jsonDecode(response.body);

      print('Ответ сервера:');
      print(decodedResponse);

      return ChapterNodes.fromJson(decodedResponse);
    } else {
      throw Exception('Ошибка при получении узлов: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}