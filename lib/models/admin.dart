class Admin {
  final BigInt id;
  final String name;
  final int adminStatus;
  final List<dynamic> createdChapters;
  final List<dynamic> requestSent;
  final List<dynamic> requestsReceived;

  Admin({
    required this.id,
    required this.name,
    required this.adminStatus,
    required this.createdChapters,
    required this.requestSent,
    required this.requestsReceived,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    // Преобразуем ID в BigInt
    final idString = json['id'].toString();
    final idBigInt = BigInt.parse(idString);

    return Admin(
      id: idBigInt,
      name: json['name'],
      adminStatus: json['adminStatus'],
      createdChapters: json['createdChapters'] ?? [],
      requestSent: json['requestSent'] ?? [],
      requestsReceived: json['requestsReceived'] ?? [],
    );
  }
}