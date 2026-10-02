class Author {
  final int id;
  final String lastName;
  final String firstName;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.lastName,
    this.firstName = '',
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'lastName': lastName,
        'firstName': firstName,
        'country': country,
        'birthYear': birthYear,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as int? ?? 0,
        lastName: json['lastName'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        country: json['country'] as String? ?? '',
        birthYear: json['birthYear'] as int? ?? 1900,
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
      );

  Author copyWith({
    String? lastName,
    String? firstName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}