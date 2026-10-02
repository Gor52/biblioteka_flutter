import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';

class BookRepo {
  static const _key = 'books_v1';
  final SharedPreferences _prefs;
  List<Book> _db = [];

  BookRepo(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _db = [
        const Book(id: 1, title: 'Война и мир', isbn: '9785171123456', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [3]),
        const Book(id: 2, title: 'Мастер и Маргарита', isbn: '9785171123458', year: 1940, pages: 480, publisherId: 1, authorIds: [3], genreIds: [1, 3]),
      ];
      _save();
    } else {
      try { 
        _db = (jsonDecode(raw) as List).map((e) => Book.fromJson(e)).toList(); 
      } catch (_) { 
        _db = []; 
      }
    }
  }

  Future<void> _save() async => await _prefs.setString(_key, jsonEncode(_db.map((b) => b.toJson()).toList()));

  Future<PageData<Book>> fetch(ListFilter f) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var items = _db.where((b) => f.showDeleted || !b.isDeleted).toList();

    if (f.search.trim().isNotEmpty) {
      final s = f.search.trim().toLowerCase();
      items = items.where((b) => b.title.toLowerCase().contains(s) || b.isbn.toLowerCase().contains(s)).toList();
    }
    if (f.genreId != null) items = items.where((b) => b.genreIds.contains(f.genreId)).toList();
    if (f.publisherId != null) items = items.where((b) => b.publisherId == f.publisherId).toList();
    
    items.sort((a, b) {
      int cmp = switch (f.sortBy) { 
        'year' => a.year.compareTo(b.year), 
        'pages' => a.pages.compareTo(b.pages), 
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()) 
      };
      return f.isAscending ? cmp : -cmp;
    });

    final start = (f.page - 1) * f.limit;
    if (start >= items.length) {
      return PageData(items: [], totalItems: items.length, currentPage: f.page, pageSize: f.limit);
    }
    final end = (start + f.limit > items.length) ? items.length : (start + f.limit);
    return PageData(items: items.sublist(start, end), totalItems: items.length, currentPage: f.page, pageSize: f.limit);
  }

  Future<Book?> findById(int id) async {
    try { return _db.firstWhere((b) => b.id == id); } catch (_) { return null; }
  }

  bool isIsbnTaken(String isbn, {int? excludeId}) {
    final clean = isbn.replaceAll(RegExp(r'[-\s]'), '');
    return _db.any((b) => b.id != excludeId && b.isbn.replaceAll(RegExp(r'[-\s]'), '') == clean);
  }

  int countBooksByPublisher(int publisherId) {
    return _db.where((b) => b.publisherId == publisherId && !b.isDeleted).length;
  }

  Future<void> saveOrUpdate(Book book) async {
    final index = _db.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      _db[index] = book;
    } else {
      final newId = _db.isEmpty ? 1 : (_db.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _db.add(Book(
        id: newId,
        title: book.title,
        isbn: book.isbn,
        year: book.year,
        pages: book.pages,
        publisherId: book.publisherId,
        authorIds: book.authorIds,
        genreIds: book.genreIds,
        copiesTotal: book.copiesTotal,
        copiesAvailable: book.copiesAvailable,
      )); 
    }
    await _save();
  }

  Future<void> removeSoft(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
    }
    await _save();
  }

  Future<void> removeHard(List<int> ids) async {
    _db.removeWhere((b) => ids.contains(b.id) && b.isDeleted);
    await _save();
  }

  Future<void> restore(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((b) => b.id == id && b.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(clearDeletedAt: true);
    }
    await _save();
  }
}