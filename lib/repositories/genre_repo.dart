import 'package:dio/dio.dart';
import '../models/genre.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';
import '../core/api_exceptions.dart';

class GenreRepo {
  final Dio _dio;
  CancelToken? _searchToken;
  List<Genre>? _cache;

  GenreRepo(this._dio);

  Future<PageData<Genre>> fetch(ListFilter f) async {
    _searchToken?.cancel('Отменено новым запросом');
    _searchToken = CancelToken();

    return guard(() async {
      final response = await _dio.get('/genres', cancelToken: _searchToken, queryParameters: {
        if (f.search.trim().isNotEmpty) 'search': f.search.trim(),
        'sort': '${f.sortBy},${f.isAscending ? 'asc' : 'desc'}',
        'page': f.page,
        'limit': f.limit,
        if (f.showDeleted) 'deleted': true,
      });
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List).map((e) => Genre.fromJson(e)).toList();
      return PageData(
        items: items, 
        currentPage: data['page'] as int? ?? 1, 
        pageSize: data['limit'] as int? ?? f.limit, 
        totalItems: data['total'] as int? ?? 0
      );
    });
  }

  Future<List<Genre>> getAllActive() async {
    if (_cache != null) return _cache!;
    return guard(() async {
      final response = await _dio.get('/genres', queryParameters: {'all': true, 'deleted': false});
      _cache = (response.data['items'] as List).map((e) => Genre.fromJson(e)).toList();
      return _cache!;
    });
  }

  Future<Genre?> findById(int id) async {
    if (_cache != null) {
      try { 
        return _cache!.firstWhere((g) => g.id == id); 
      } catch (_) {
      }
    }
    return guard(() async {
      final response = await _dio.get('/genres/$id');
      return Genre.fromJson(response.data);
    });
  }

  Future<void> saveOrUpdate(Genre genre) => guard(() async {
    if (genre.id == 0) {
      await _dio.post('/genres', data: genre.toJson());
    } else {
      await _dio.put('/genres/${genre.id}', data: genre.toJson());
    }
    _cache = null; 
  });

  Future<void> removeSoft(List<int> ids) => guard(() async {
    await _dio.post('/genres/bulk-soft-delete', data: {'ids': ids});
    _cache = null; 
  });

  Future<void> removeHard(List<int> ids) => guard(() async {
    await _dio.post('/genres/bulk-hard-delete', data: {'ids': ids});
    _cache = null; 
  });

  Future<void> restore(List<int> ids) => guard(() async {
    await _dio.post('/genres/bulk-restore', data: {'ids': ids});
    _cache = null; 
  });
}