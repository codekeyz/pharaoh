class Todo {
  String id;
  String content;
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;

  Todo({
    required this.id,
    required this.content,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      "content": content,
      "isCompleted": isCompleted,
      "createdAt": createdAt.toUtc().toIso8601String(),
      "updatedAt": updatedAt.toUtc().toIso8601String(),
    };
  }

  static Todo fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      content: json['content'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
