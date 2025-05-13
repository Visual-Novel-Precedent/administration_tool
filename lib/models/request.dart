class Requests {
  final BigInt id;
  final int type;
  final int status;
  final BigInt requestingAdmin;
  final BigInt requestedChapterId;
  final String requestingAdminName;
  final String requestedChapterIdName;

  Requests({
    required this.id,
    required this.type,
    required this.status,
    required this.requestingAdmin,
    required this.requestedChapterId,
    required this.requestingAdminName,
    required this.requestedChapterIdName
  });

  static BigInt safeBigIntParse(String? value) {
    if (value == null || value.isEmpty) {
      return BigInt.zero;
    }
    try {
      return BigInt.parse(value);
    } catch (e) {
      print('Ошибка парсинга BigInt: $value - $e');
      return BigInt.zero;
    }
  }

  factory Requests.fromJson(Map<String, dynamic> json) {
    return Requests(
      id: safeBigIntParse(json['Id']),
      type: json['Type'] ?? 0,
      status: json['Status'] ?? 0,
      requestingAdmin: safeBigIntParse(json['RequestingAdmin']),
      requestedChapterId: safeBigIntParse(json['RequestedChapterId']),
      requestingAdminName: json['RequestingAdminName'] ?? '',
      requestedChapterIdName: json['RequestedChapterIdName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id.toString(),
      'Type': type,
      'Status': status,
      'RequestingAdmin': requestingAdmin.toString(),
      'RequestedChapterId': requestedChapterId.toString(),
      'RequestingAdminNae': requestingAdminName,
      'RequestedChapterIdName': requestedChapterIdName,
    };
  }

  @override
  String toString() {
    return 'Request(id: $id, type: $type, status: $status, '
        'requestingAdmin: $requestingAdmin, requestedChapterId: $requestedChapterId)';
  }
}