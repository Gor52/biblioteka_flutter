class ListFilter {
  final String search;
  final String sortBy;
  final bool isAscending;
  final int page;
  final int limit;
  final bool showDeleted;
  
  final int? genreId;
  final int? publisherId;
  final int? minYear;

  const ListFilter({
    this.search = '',
    this.sortBy = 'id',
    this.isAscending = true,
    this.page = 1,
    this.limit = 10,
    this.showDeleted = false,
    this.genreId,
    this.publisherId,
    this.minYear,
  });

  static const _clear = Object();

  ListFilter copyWith({
    String? search, String? sortBy, bool? isAscending, int? page, int? limit, bool? showDeleted,
    Object? genreId = _clear, Object? publisherId = _clear, Object? minYear = _clear,
  }) {
    return ListFilter(
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      isAscending: isAscending ?? this.isAscending,
      page: page ?? 1, 
      limit: limit ?? this.limit,
      showDeleted: showDeleted ?? this.showDeleted,
      genreId: genreId == _clear ? this.genreId : genreId as int?,
      publisherId: publisherId == _clear ? this.publisherId : publisherId as int?,
      minYear: minYear == _clear ? this.minYear : minYear as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          sortBy == other.sortBy &&
          isAscending == other.isAscending &&
          page == other.page &&
          limit == other.limit &&
          showDeleted == other.showDeleted &&
          genreId == other.genreId &&
          publisherId == other.publisherId &&
          minYear == other.minYear;

  @override
  int get hashCode => Object.hash(
        search,
        sortBy,
        isAscending,
        page,
        limit,
        showDeleted,
        genreId,
        publisherId,
        minYear,
      );
}