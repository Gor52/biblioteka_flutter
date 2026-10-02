import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genre.dart';
import '../models/publisher.dart';

class LookupRepository {
  static const _genreKey = 'genres_v1';
  static const _publisherKey = 'publishers_v1';
  final SharedPreferences _prefs;

  List<Genre> _genres = [];
  List<Publisher> _publishers = [];

  LookupRepository(this._prefs) {
    _init();
  }

  void _init() {
    final gRaw = _prefs.getString(_genreKey);
    if (gRaw == null) {
      _genres = const [
        Genre(id: 1, name: 'Фантастика'),
        Genre(id: 2, name: 'Детектив'),
        Genre(id: 3, name: 'Роман'),
        Genre(id: 4, name: 'Научпоп'),
      ];
      _saveGenres();
    } else {
      try {
        final list = jsonDecode(gRaw) as List;
        _genres = list.map((e) => Genre.fromJson(e)).toList();
      } catch (_) {
        _genres = [];
      }
    }

    final pRaw = _prefs.getString(_publisherKey);
    if (pRaw == null) {
      _publishers = const [
        Publisher(id: 1, name: 'АСТ', city: 'Москва'),
        Publisher(id: 2, name: 'ЭКСМО', city: 'Москва'),
        Publisher(id: 3, name: 'Питер', city: 'Санкт-Петербург'),
      ];
      _savePublishers();
    } else {
      try {
        final list = jsonDecode(pRaw) as List;
        _publishers = list.map((e) => Publisher.fromJson(e)).toList();
      } catch (_) {
        _publishers = [];
      }
    }
  }

  Future<void> _saveGenres() async =>
      await _prefs.setString(_genreKey, jsonEncode(_genres.map((e) => e.toJson()).toList()));

  Future<void> _savePublishers() async =>
      await _prefs.setString(_publisherKey, jsonEncode(_publishers.map((e) => e.toJson()).toList()));

  List<Genre> get genres => List.unmodifiable(_genres);
  List<Publisher> get publishers => List.unmodifiable(_publishers);

  Publisher? getPublisherById(int id) {
    try {
      return _publishers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}