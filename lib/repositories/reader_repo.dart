import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reader.dart';
import '../models/library_card.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';

class ReaderRepo {
  static const _key = 'readers_v1';
  final SharedPreferences _prefs;
  List<Reader> _db = [];

  ReaderRepo(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _db = [
        Reader(
          id: 1,
          fullName: 'Иван Иванов',
          email: 'ivan@example.com',
          phone: '+7 (999) 123-45-67', 
          card: LibraryCard(cardNumber: 'БК-001', issuedAt: DateTime.now()),
        ),
        Reader(
          id: 2,
          fullName: 'Анна Смирнова',
          email: 'anna@example.com',
          phone: '+7 (999) 765-43-21', 
          card: LibraryCard(cardNumber: 'БК-002', issuedAt: DateTime.now()),
        ),
      ];
      _save();
    } else {
      try {
        _db = (jsonDecode(raw) as List).map((e) => Reader.fromJson(e)).toList();
      } catch (_) {
        _db = [];
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(_db.map((r) => r.toJson()).toList()));
  }

  Future<PageData<Reader>> fetch(ListFilter f) async {
    await Future.delayed(const Duration(milliseconds: 200)); 
    var items = _db.where((r) => f.showDeleted || !r.isDeleted).toList();

    if (f.search.trim().isNotEmpty) {
      final s = f.search.trim().toLowerCase();
      items = items.where((r) =>
          r.fullName.toLowerCase().contains(s) ||
          r.email.toLowerCase().contains(s) ||
          r.phone.toLowerCase().contains(s) ||
          r.card.cardNumber.toLowerCase().contains(s)).toList();
    }
    
    items.sort((a, b) {
      int cmp = switch (f.sortBy) {
        'email' => a.email.compareTo(b.email),
        'cardNumber' => a.card.cardNumber.compareTo(b.card.cardNumber),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())
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

  Future<Reader?> findById(int id) async {
    try {
      return _db.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isEmailTaken(String email, {int? excludeId}) {
    final cleanEmail = email.trim().toLowerCase();
    return _db.any((r) => r.id != excludeId && r.email.trim().toLowerCase() == cleanEmail);
  }

  Future<void> saveOrUpdate(Reader reader) async {
    final index = _db.indexWhere((r) => r.id == reader.id);
    if (index != -1) {
      _db[index] = reader;
    } else {
      final newId = _db.isEmpty ? 1 : (_db.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _db.add(Reader(
        id: newId,
        fullName: reader.fullName,
        email: reader.email,
        phone: reader.phone, 
        card: reader.card,
      ));
    }
    await _save();
  }

  Future<void> removeSoft(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(deletedAt: DateTime.now());
    }
    await _save();
  }

  Future<void> removeHard(List<int> ids) async {
    _db.removeWhere((r) => ids.contains(r.id) && r.isDeleted);
    await _save();
  }

  Future<void> restore(List<int> ids) async {
    for (final id in ids) {
      final i = _db.indexWhere((r) => r.id == id && r.isDeleted);
      if (i != -1) _db[i] = _db[i].copyWith(clearDeletedAt: true);
    }
    await _save();
  }
}