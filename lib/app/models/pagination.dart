/// Model untuk pagination metadata dari API response
class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  const Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  /// Empty pagination untuk response tanpa data
  const Pagination.empty()
    : total = 0,
      perPage = 0,
      currentPage = 0,
      lastPage = 0,
      from = 0,
      to = 0;

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;

  factory Pagination.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const Pagination.empty();
    }

    return Pagination(
      total: int.tryParse('${json['total'] ?? '0'}') ?? 0,
      perPage: int.tryParse('${json['per_page'] ?? '0'}') ?? 0,
      currentPage: int.tryParse('${json['current_page'] ?? '0'}') ?? 0,
      lastPage: int.tryParse('${json['last_page'] ?? '0'}') ?? 0,
      from: int.tryParse('${json['from'] ?? '0'}') ?? 0,
      to: int.tryParse('${json['to'] ?? '0'}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'per_page': perPage,
    'current_page': currentPage,
    'last_page': lastPage,
    'from': from,
    'to': to,
  };
}
