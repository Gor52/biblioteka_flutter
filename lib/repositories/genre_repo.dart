import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genre.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';

class GenreRepo {
  static const _key = 'genres_v2';
  final SharedPreferences _prefs;
  List<Genre> _db = [];

  GenreRepo(this._prefs) { _restore(); }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _db = [const Genre(id: 1, name: 'Фантастика'), const Genre(id: 2, name: 'Детектив'), const Genre(id: 3, name: 'Роман')];
      _save();
    } else {
      try { _db = (jsonDecode(raw) as List).map((e) => Genre.fromJson(e)).toList(); } catch (_) { _db = []; }
    }
  }

  Future<void> _save() async => await _prefs.setString(_key, jsonEncode(_db.map((g) => g.toJson()).toList()));
  
  List<Genre> getAllActive() => _db.where((g) => !g.isDeleted).toList();

  Future<PageData<Genre>> fetch(ListFilter f) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var items = _db.where((g) => f.showDeleted || !g.isDeleted).toList();
    if (f.search.trim().isNotEmpty) {
      items = items.where((g) => g.name.toLowerCase().contains(f.search.trim().toLowerCase())).toList();
    }
    items.sort((a, b) => f.isAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    final start = (f.page - 1) * f.limit;
    if (start >= items.length) return PageData(items: [], totalItems: items.length, currentPage: f.page, pageSize: f.limit);
    final end = (start + f.limit > items.length) ? items.length : (start + f.limit);
    return PageData(items: items.sublist(start, end), totalItems: items.length, currentPage: f.page, pageSize: f.limit);
  }

  Future<Genre?> findById(int id) async {
    try { return _db.firstWhere((g) => g.id == id); } catch (_) { return null; }
  }

  Future<void> saveOrUpdate(Genre genre) async {
    final index = _db.indexWhere((g) => g.id == genre.id);
    if (index != -1) _db[index] = genre;
    else {
      final newId = _db.isEmpty ? 1 : (_db.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _db.add(Genre(id: newId, name: genre.name));
    }
    await _save();
  }

  Future<void> removeSoft(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((g) => g.id == id && !g.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
    }
    await _save();
  }

  Future<void> removeHard(List<int> ids) async {
    _db.removeWhere((g) => ids.contains(g.id) && g.isDeleted);
    await _save();
  }

  Future<void> restore(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((g) => g.id == id && g.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(clearDeletedAt: true);
    }
    await _save();
  }
}