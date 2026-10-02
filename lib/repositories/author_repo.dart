import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/author.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';

class AuthorRepo {
  static const _key = 'authors_v1';
  final SharedPreferences _prefs;
  List<Author> _db = [];

  AuthorRepo(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _db = [
        const Author(id: 1, lastName: 'Толстой', firstName: 'Лев', country: 'Россия', birthYear: 1828),
        const Author(id: 2, lastName: 'Достоевский', firstName: 'Федор', country: 'Россия', birthYear: 1821),
        const Author(id: 3, lastName: 'Булгаков', firstName: 'Михаил', country: 'СССР', birthYear: 1891),
      ];
      _save();
    } else {
      try {
        _db = (jsonDecode(raw) as List).map((e) => Author.fromJson(e)).toList();
      } catch (_) {
        _db = [];
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(_db.map((a) => a.toJson()).toList()));
  }

  List<Author> getAllActive() {
    return _db.where((a) => !a.isDeleted).toList();
  }

  Future<PageData<Author>> fetch(ListFilter f) async {
    await Future.delayed(const Duration(milliseconds: 200)); 
    var items = _db.where((a) => f.showDeleted || !a.isDeleted).toList();

    if (f.search.trim().isNotEmpty) {
      final s = f.search.trim().toLowerCase();
      items = items.where((a) =>
          a.lastName.toLowerCase().contains(s) ||
          a.firstName.toLowerCase().contains(s)).toList();
    }
    
    items.sort((a, b) {
      int cmp = switch (f.sortBy) {
        'firstName' => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase())
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

  Future<Author?> findById(int id) async {
    try {
      return _db.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOrUpdate(Author author) async {
    final index = _db.indexWhere((a) => a.id == author.id);
    if (index != -1) {
      _db[index] = author;
    } else {
      final newId = _db.isEmpty ? 1 : (_db.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _db.add(Author(
        id: newId,
        lastName: author.lastName,
        firstName: author.firstName,
        country: author.country,
        birthYear: author.birthYear,
      ));
    }
    await _save();
  }

  Future<void> removeSoft(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
    }
    await _save();
  }

  Future<void> removeHard(List<int> ids) async {
    _db.removeWhere((a) => ids.contains(a.id) && a.isDeleted);
    await _save();
  }

  Future<void> restore(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((a) => a.id == id && a.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(clearDeletedAt: true);
    }
    await _save();
  }
}