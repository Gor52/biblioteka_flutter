import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';
import '../repositories/book_repo.dart';

enum ScreenState { loading, data, empty, error }

class BookProvider extends ChangeNotifier {
  final BookRepo repo;
  BookProvider(this.repo);

  ListFilter _filter = const ListFilter(sortBy: 'title');
  PageData<Book> _pageData = PageData.empty();
  ScreenState _state = ScreenState.loading;
  String? _errMsg;
  final Set<int> _selectedIds = {};

  ListFilter get filter => _filter;
  PageData<Book> get data => _pageData;
  ScreenState get state => _state;
  Set<int> get selectedIds => _selectedIds;
  String? get error => _errMsg;

  Future<void> updateFilter(ListFilter next) async {
    _filter = next;
    _selectedIds.clear();
    await _fetch();
  }

  void toggleSelection(int id) {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    notifyListeners();
  }

  Future<void> executeBatch(String action) async {
    if (_selectedIds.isEmpty) return;
    _state = ScreenState.loading;
    notifyListeners();
    
    final ids = _selectedIds.toList();
    if (action == 'soft') await repo.removeSoft(ids);
    if (action == 'hard') await repo.removeHard(ids);
    if (action == 'restore') await repo.recover(ids);
    
    _selectedIds.clear();
    await _fetch();
  }

  Future<void> _fetch() async {
    _state = ScreenState.loading;
    notifyListeners();
    try {
      _pageData = await repo.fetch(_filter);
      _state = _pageData.items.isEmpty ? ScreenState.empty : ScreenState.data;
    } catch (e) {
      _state = ScreenState.error;
      _errMsg = e.toString();
    }
    notifyListeners();
  }
}