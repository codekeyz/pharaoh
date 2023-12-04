class CreateTodoRequest {
  String content;
  bool isCompleted;

  CreateTodoRequest(this.content, this.isCompleted);

  Map<String, dynamic> toJson() {
    return {
      "content": content,
      "isCompleted": isCompleted,
    };
  }
}
