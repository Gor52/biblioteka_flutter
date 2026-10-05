import 'package:dio/dio.dart';
import '../models/author.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';
import '../core/api_exceptions.dart';

class AuthorRepo {
  final Dio _dio;
  CancelToken? _searchToken;
  List<Author>? _cache;

  AuthorRepo(this._dio);

  Future<PageData<Author>> fetch(ListFilter f) async {
    _searchToken?.cancel('Отменено новым запросом');
    _searchToken = CancelToken();

    return guard(() async {
      final response = await _dio.get('/authors', cancelToken: _searchToken, queryParameters: {
        if (f.search.trim().isNotEmpty) 'search': f.search.trim(),
        'sort': '${f.sortBy},${f.isAscending ? 'asc' : 'desc'}',
        'page': f.page,
        'limit': f.limit,
        if (f.showDeleted) 'deleted': true,
      });
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List).map((e) => Author.fromJson(e)).toList();
      return PageData(
        items: items, 
        currentPage: data['page'] as int? ?? 1, 
        pageSize: data['limit'] as int? ?? f.limit, 
        totalItems: data['total'] as int? ?? 0
      );
    });
  }

  Future<List<Author>> getAllActive() async {
    if (_cache != null) return _cache!;
    return guard(() async {
      final response = await _dio.get('/authors', queryParameters: {'all': true, 'deleted': false});
      _cache = (response.data['items'] as List).map((e) => Author.fromJson(e)).toList();
      return _cache!;
    });
  }

  Future<Author?> findById(int id) => guard(() async {
    final response = await _dio.get('/authors/$id');
    return Author.fromJson(response.data);
  });

  Future<void> saveOrUpdate(Author author) => guard(() async {
    if (author.id == 0) {
      await _dio.post('/authors', data: author.toJson());
    } else {
      await _dio.put('/authors/${author.id}', data: author.toJson());
    }
    _cache = null; 
  });

  Future<void> removeSoft(List<int> ids) => guard(() async {
    await _dio.post('/authors/bulk-soft-delete', data: {'ids': ids});
    _cache = null;
  });

  Future<void> removeHard(List<int> ids) => guard(() async {
    await _dio.post('/authors/bulk-hard-delete', data: {'ids': ids});
    _cache = null;
  });

  Future<void> restore(List<int> ids) => guard(() async {
    await _dio.post('/authors/bulk-restore', data: {'ids': ids});
    _cache = null;
  });
}