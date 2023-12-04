class Pagination<T> {
  int count;
  List<Map<String, dynamic>> data;
  int page;

  Pagination({required this.data, required this.count, required this.page});

  Map<String, dynamic> toJson() => {
        "results": data,
        "page": page,
        "totalCount": count,
      };
}
