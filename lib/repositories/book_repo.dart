import '../models/book.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';

class BookRepo {
  final List<Book> _db = [
    const Book(id: 1, title: 'Мастер и Маргарита', isbn: '978-5-17-087888-1', year: 1967, pages: 416, genreId: 3, publisherId: 1),
    const Book(id: 2, title: 'Преступление и наказание', isbn: '978-5-699-10811-4', year: 1866, pages: 592, genreId: 3, publisherId: 2),
    const Book(id: 3, title: '1984', isbn: '978-5-17-099238-9', year: 1949, pages: 320, genreId: 1, publisherId: 1),
    const Book(id: 4, title: 'Дюна', isbn: '978-5-17-101744-9', year: 1965, pages: 704, genreId: 1, publisherId: 2),
    const Book(id: 5, title: 'Убийство в Восточном экспрессе', isbn: '978-5-699-11522-8', year: 1934, pages: 256, genreId: 2, publisherId: 1),
    const Book(id: 6, title: 'Десять негритят', isbn: '978-5-699-11523-5', year: 1939, pages: 320, genreId: 2, publisherId: 2),
    const Book(id: 7, title: 'Этюд в багровых тонах', isbn: '978-5-17-099244-0', year: 1887, pages: 224, genreId: 2, publisherId: 1),
    const Book(id: 8, title: 'Метро 2033', isbn: '978-5-17-102222-1', year: 2005, pages: 384, genreId: 1, publisherId: 2),
    const Book(id: 9, title: 'Евгений Онегин', isbn: '978-5-17-085555-4', year: 1833, pages: 224, genreId: 3, publisherId: 1),
    const Book(id: 10, title: 'Солярис', isbn: '978-5-17-091111-3', year: 1961, pages: 288, genreId: 1, publisherId: 2),
    const Book(id: 11, title: 'Анна Каренина', isbn: '978-5-699-12222-6', year: 1878, pages: 864, genreId: 3, publisherId: 1),
    const Book(id: 12, title: 'Гордость и предубеждение', isbn: '978-5-17-088888-0', year: 1813, pages: 416, genreId: 3, publisherId: 2),
    const Book(id: 13, title: 'Пикник на обочине', isbn: '978-5-17-077777-1', year: 1972, pages: 256, genreId: 1, publisherId: 1),
    const Book(id: 14, title: 'Три товарища', isbn: '978-5-17-066666-2', year: 1936, pages: 480, genreId: 3, publisherId: 2),
    const Book(id: 15, title: 'Великий Гэтсби', isbn: '978-5-17-055555-3', year: 1925, pages: 256, genreId: 3, publisherId: 1),
    const Book(id: 16, title: 'Марсианин', isbn: '978-5-17-044444-4', year: 2011, pages: 368, genreId: 1, publisherId: 2),
    const Book(id: 17, title: 'Собачье сердце', isbn: '978-5-17-033333-5', year: 1968, pages: 288, genreId: 3, publisherId: 1),
    const Book(id: 18, title: 'Дракула', isbn: '978-5-17-022222-6', year: 1897, pages: 416, genreId: 1, publisherId: 2),
    const Book(id: 19, title: 'Код да Винчи', isbn: '978-5-17-011111-7', year: 2003, pages: 544, genreId: 2, publisherId: 1),
    const Book(id: 20, title: 'Мёртвые души', isbn: '978-5-17-099999-8', year: 1842, pages: 352, genreId: 3, publisherId: 2),
    const Book(id: 21, title: 'Зов Ктулху', isbn: '978-5-17-088877-9', year: 1928, pages: 320, genreId: 1, publisherId: 1),
    const Book(id: 22, title: 'Девушка с татуировкой дракона', isbn: '978-5-699-13333-1', year: 2005, pages: 624, genreId: 2, publisherId: 2),
    const Book(id: 23, title: 'Граф Монте-Кристо', isbn: '978-5-699-14444-2', year: 1844, pages: 1200, genreId: 3, publisherId: 1),
    const Book(id: 24, title: 'Мы', isbn: '978-5-699-15555-3', year: 1920, pages: 224, genreId: 1, publisherId: 2),
    const Book(id: 25, title: 'Капитанская дочка', isbn: '978-5-699-16666-4', year: 1836, pages: 320, genreId: 3, publisherId: 1),
  ];

  Future<PageData<Book>> fetch(ListFilter f) async {

    await Future.delayed(const Duration(milliseconds: 300));

    var items = _db.where((b) => f.showDeleted || !b.isDeleted).toList();

    if (f.search.trim().isNotEmpty) {
      final q = f.search.trim().toLowerCase();
      items = items.where((b) => b.title.toLowerCase().contains(q) || b.isbn.toLowerCase().contains(q)).toList();
    }

    if (f.genreId != null) items = items.where((b) => b.genreId == f.genreId).toList();
    if (f.publisherId != null) items = items.where((b) => b.publisherId == f.publisherId).toList();
    if (f.minYear != null) items = items.where((b) => b.year >= f.minYear!).toList();

    items.sort((a, b) {
      int comp = switch (f.sortBy) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.compareTo(b.title),
      };
      return f.isAscending ? comp : -comp;
    });

    final total = items.length;
    final start = (f.page - 1) * f.limit;
    final end = (start + f.limit).clamp(0, total);
    final paged = start >= total ? <Book>[] : items.sublist(start, end);

    return PageData(items: paged, currentPage: f.page, pageSize: f.limit, totalItems: total);
  }

  Future<void> removeSoft(List<int> ids) async {
    for (var id in ids) {
      final idx = _db.indexWhere((b) => b.id == id && !b.isDeleted); 
      if (idx != -1) _db[idx] = _db[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  Future<void> removeHard(List<int> ids) async => _db.removeWhere((b) => ids.contains(b.id));

  Future<void> recover(List<int> ids) async {
    for (var id in ids) {
      final idx = _db.indexWhere((b) => b.id == id);
      if (idx != -1) _db[idx] = _db[idx].copyWith(restore: true);
    }
  }
}