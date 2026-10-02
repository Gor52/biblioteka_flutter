class LibraryCard {
  final String cardNumber;
  final DateTime issuedAt;
  final bool isActive;

  const LibraryCard({
    required this.cardNumber,
    required this.issuedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'cardNumber': cardNumber,
        'issuedAt': issuedAt.toIso8601String(),
        'isActive': isActive,
      };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
        cardNumber: json['cardNumber'] as String? ?? '',
        issuedAt: json['issuedAt'] != null
            ? DateTime.parse(json['issuedAt'] as String)
            : DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
      );

  LibraryCard copyWith({String? cardNumber, DateTime? issuedAt, bool? isActive}) {
    return LibraryCard(
      cardNumber: cardNumber ?? this.cardNumber,
      issuedAt: issuedAt ?? this.issuedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}