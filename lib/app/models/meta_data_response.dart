class MetaDataResponse {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;
  final int? from;
  final int? to;

  MetaDataResponse({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.from,
    this.to,
  });

  bool get hasNextPage =>
      currentPage != null && lastPage != null && currentPage! < lastPage!;

  bool get hasPreviousPage => currentPage != null && currentPage! > 1;

  factory MetaDataResponse.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return MetaDataResponse();
    return MetaDataResponse(
      total: int.tryParse('${json['total'] ?? ''}'),
      perPage: int.tryParse('${json['per_page'] ?? ''}'),
      currentPage: int.tryParse('${json['current_page'] ?? ''}'),
      lastPage: int.tryParse('${json['last_page'] ?? ''}'),
      from: int.tryParse('${json['from'] ?? ''}'),
      to: int.tryParse('${json['to'] ?? ''}'),
    );
  }
}
