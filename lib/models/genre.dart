class Genre {
  final int id;
  final String name;
  final DateTime? deletedAt; 

  const Genre({required this.id, required this.name, this.deletedAt});
  
  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'deletedAt': deletedAt?.toIso8601String()};
  
  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
  );
  
  Genre copyWith({String? name, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Genre(
      id: id, 
      name: name ?? this.name, 
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt)
    );
  }
}