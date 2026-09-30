class Author {
  final int id;
  final String lastName;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  const Author({
    required this.id, required this.lastName, required this.country, 
    required this.birthYear, this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Author copyWith({DateTime? deletedAt, bool restore = false}) {
    return Author(
      id: id, lastName: lastName, country: country, birthYear: birthYear,
      deletedAt: restore ? null : (deletedAt ?? this.deletedAt),
    );
  }
}