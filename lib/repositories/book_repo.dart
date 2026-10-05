import 'package:dio/dio.dart';
import '../models/book.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';
import '../core/api_exceptions.dart';

class BookRepo {
  final Dio _dio;
  CancelToken? _searchToken; 

  BookRepo(this._dio);

  Future<PageData<Book>> fetch(ListFilter f) async {
    _searchToken?.cancel('Отменено новым запросом'); 
    _searchToken = CancelToken();

    return guard(() async {
      final response = await _dio.get('/books', cancelToken: _searchToken, queryParameters: {
        if (f.search.trim().isNotEmpty) 'search': f.search.trim(),
        if (f.genreId != null) 'genreId': f.genreId,
        if (f.publisherId != null) 'publisherId': f.publisherId,
        'sort': '${f.sortBy},${f.isAscending ? 'asc' : 'desc'}',
        'page': f.page,
        'limit': f.limit,
        if (f.showDeleted) 'deleted': true,
      });
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List).map((e) => Book.fromJson(e)).toList();
      return PageData(
        items: items, 
        currentPage: data['page'] as int? ?? 1, 
        pageSize: data['limit'] as int? ?? f.limit, 
        totalItems: data['total'] as int? ?? 0
      );
    });
  }

  Future<Book?> findById(int id) => guard(() async {
    final response = await _dio.get('/books/$id');
    return Book.fromJson(response.data);
  });

  Future<void> saveOrUpdate(Book book) => guard(() async {
    if (book.id == 0) {
      await _dio.post('/books', data: book.toJson()); 
    } else {
      await _dio.put('/books/${book.id}', data: book.toJson());
    }
  });

  Future<void> removeSoft(List<int> ids) => guard(() => _dio.post('/books/bulk-soft-delete', data: {'ids': ids}));
  Future<void> removeHard(List<int> ids) => guard(() => _dio.post('/books/bulk-hard-delete', data: {'ids': ids}));
  Future<void> restore(List<int> ids) => guard(() => _dio.post('/books/bulk-restore', data: {'ids': ids}));
}