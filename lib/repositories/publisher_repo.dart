import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/publisher.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';

class PublisherRepo {
  static const _key = 'publishers_v2'; // Изменен ключ, так как обновили модель
  final SharedPreferences _prefs;
  List<Publisher> _db = [];

  PublisherRepo(this._prefs) { _restore(); }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _db = [
        const Publisher(id: 1, name: 'АСТ', city: 'Москва'),
        const Publisher(id: 2, name: 'ЭКСМО', city: 'Москва'),
        const Publisher(id: 3, name: 'Питер', city: 'Санкт-Петербург'),
      ];
      _save();
    } else {
      try { _db = (jsonDecode(raw) as List).map((e) => Publisher.fromJson(e)).toList(); } catch (_) { _db = []; }
    }
  }

  Future<void> _save() async => await _prefs.setString(_key, jsonEncode(_db.map((p) => p.toJson()).toList()));
  
  // Возвращаем только активные издательства для формы книги
  List<Publisher> getAllActive() => _db.where((p) => !p.isDeleted).toList();

  Future<PageData<Publisher>> fetch(ListFilter f) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var items = _db.where((p) => f.showDeleted || !p.isDeleted).toList(); // Учитываем корзину

    if (f.search.trim().isNotEmpty) {
      final s = f.search.trim().toLowerCase();
      items = items.where((p) => p.name.toLowerCase().contains(s) || p.city.toLowerCase().contains(s)).toList();
    }
    
    items.sort((a, b) => f.isAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    final start = (f.page - 1) * f.limit;
    if (start >= items.length) return PageData(items: [], totalItems: items.length, currentPage: f.page, pageSize: f.limit);
    final end = (start + f.limit > items.length) ? items.length : (start + f.limit);
    return PageData(items: items.sublist(start, end), totalItems: items.length, currentPage: f.page, pageSize: f.limit);
  }

  Future<Publisher?> findById(int id) async {
    try { return _db.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }

  Future<void> saveOrUpdate(Publisher publisher) async {
    final index = _db.indexWhere((p) => p.id == publisher.id);
    if (index != -1) _db[index] = publisher;
    else {
      final newId = _db.isEmpty ? 1 : (_db.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _db.add(Publisher(id: newId, name: publisher.name, city: publisher.city));
    }
    await _save();
  }

  Future<void> removeSoft(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
    }
    await _save();
  }

  Future<void> removeHard(List<int> ids) async {
    _db.removeWhere((p) => ids.contains(p.id));
    await _save();
  }

  Future<void> restore(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((p) => p.id == id && p.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(clearDeletedAt: true);
    }
    await _save();
  }
}