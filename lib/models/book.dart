class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int genreId;
  final int publisherId;
  final DateTime? deletedAt;

  const Book({
    required this.id, required this.title, required this.isbn, required this.year,
    required this.pages, required this.genreId, required this.publisherId, this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Book copyWith({DateTime? deletedAt, bool restore = false}) {
    return Book(
      id: id, title: title, isbn: isbn, year: year, pages: pages,
      genreId: genreId, publisherId: publisherId,
      deletedAt: restore ? null : (deletedAt ?? this.deletedAt),
    );
  }
}