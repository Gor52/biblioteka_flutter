import '../models/author.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';

class AuthorRepo {
  final List<Author> _db = [
    const Author(id: 1, lastName: 'Пушкин', country: 'Россия', birthYear: 1799),
    const Author(id: 2, lastName: 'Толстой', country: 'Россия', birthYear: 1828),
    const Author(id: 3, lastName: 'Шекспир', country: 'Англия', birthYear: 1564),
    const Author(id: 4, lastName: 'Оруэлл', country: 'Великобритания', birthYear: 1903),
    const Author(id: 5, lastName: 'Ремарк', country: 'Германия', birthYear: 1898),
    const Author(id: 6, lastName: 'Хемингуэй', country: 'США', birthYear: 1899),
    const Author(id: 7, lastName: 'Достоевский', country: 'Россия', birthYear: 1821),
    const Author(id: 8, lastName: 'Лондон', country: 'США', birthYear: 1876),
    const Author(id: 9, lastName: 'Диккенс', country: 'Англия', birthYear: 1812),
    const Author(id: 10, lastName: 'Дюма', country: 'Франция', birthYear: 1802),
  ];

  Future<PageData<Author>> fetch(ListFilter f) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var items = _db.where((a) => f.showDeleted || !a.isDeleted).toList();

    if (f.search.trim().isNotEmpty) {
      final q = f.search.trim().toLowerCase();
      items = items.where((a) => a.lastName.toLowerCase().contains(q) || a.country.toLowerCase().contains(q)).toList();
    }

    items.sort((a, b) {
      int comp = switch (f.sortBy) {
        'country' => a.country.compareTo(b.country),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.compareTo(b.lastName),
      };
      return f.isAscending ? comp : -comp;
    });

    final total = items.length;
    final start = (f.page - 1) * f.limit;
    final end = (start + f.limit).clamp(0, total);
    final paged = start >= total ? <Author>[] : items.sublist(start, end);

    return PageData(items: paged, currentPage: f.page, pageSize: f.limit, totalItems: total);
  }

  Future<void> removeSoft(List<int> ids) async {
    for (var id in ids) {
      final idx = _db.indexWhere((a) => a.id == id && !a.isDeleted);
      if (idx != -1) _db[idx] = _db[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  Future<void> removeHard(List<int> ids) async => _db.removeWhere((a) => ids.contains(a.id));

  Future<void> recover(List<int> ids) async {
    for (var id in ids) {
      final idx = _db.indexWhere((a) => a.id == id);
      if (idx != -1) _db[idx] = _db[idx].copyWith(restore: true);
    }
  }
}