class MetaDataResponse {
  final num? totalItems;
  final num? itemsPerPage;
  final num? currentPage;
  final num? totalPages;
  final bool? hasNextPage;
  final bool? hasPreviousPage;

  MetaDataResponse({
    this.totalItems,
    this.itemsPerPage,
    this.currentPage,
    this.totalPages,
    this.hasNextPage,
    this.hasPreviousPage,
  });

  MetaDataResponse.fromJson(dynamic json)
    : totalItems = json['totalItems'],
      itemsPerPage = json['itemsPerPage'],
      currentPage = json['currentPage'],
      totalPages = json['totalPages'],
      hasNextPage = json['hasNextPage'],
      hasPreviousPage = json['hasPreviousPage'];
}
