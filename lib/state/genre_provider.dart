import 'package:flutter/material.dart';
import '../models/genre.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';
import '../repositories/genre_repo.dart';
import 'book_provider.dart'; 

class GenreProvider extends ChangeNotifier {
  final GenreRepo repo;
  GenreProvider(this.repo);

  ListFilter _filter = const ListFilter();
  PageData<Genre> _data = const PageData(items: [], totalItems: 0, currentPage: 1, pageSize: 10);
  ScreenState _state = ScreenState.loading;
  String _error = '';
  final Set<int> _selectedIds = {};

  ListFilter get filter => _filter;
  PageData<Genre> get data => _data;
  ScreenState get state => _state;
  String get error => _error;
  Set<int> get selectedIds => _selectedIds;

  Future<void> updateFilter(ListFilter newFilter) async {
    _filter = newFilter;
    _selectedIds.clear();
    await loadData();
  }

  Future<void> loadData() async {
    _state = ScreenState.loading;
    notifyListeners();
    try {
      _data = await repo.fetch(_filter);
      _state = _data.items.isEmpty ? ScreenState.empty : ScreenState.data;
    } catch (e) {
      _error = e.toString();
      _state = ScreenState.error;
    }
    notifyListeners();
  }

  void toggleSelection(int id) {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    notifyListeners();
  }

  Future<void> executeBatch(String action) async {
    final ids = _selectedIds.toList();
    if (action == 'soft') await repo.removeSoft(ids);
    else if (action == 'hard') await repo.removeHard(ids);
    else if (action == 'restore') await repo.restore(ids);
    _selectedIds.clear();
    await loadData();
  }
}