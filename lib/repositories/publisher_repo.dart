import 'package:dio/dio.dart';
import '../models/publisher.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';
import '../core/api_exceptions.dart';

class PublisherRepo {
  final Dio _dio;
  CancelToken? _searchToken;
  List<Publisher>? _cache;

  PublisherRepo(this._dio);

  Future<PageData<Publisher>> fetch(ListFilter f) async {
    _searchToken?.cancel('Отменено новым запросом');
    _searchToken = CancelToken();

    return guard(() async {
      final response = await _dio.get('/publishers', cancelToken: _searchToken, queryParameters: {
        if (f.search.trim().isNotEmpty) 'search': f.search.trim(),
        'sort': '${f.sortBy},${f.isAscending ? 'asc' : 'desc'}',
        'page': f.page,
        'limit': f.limit,
        if (f.showDeleted) 'deleted': true,
      });
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List).map((e) => Publisher.fromJson(e)).toList();
      return PageData(
        items: items, 
        currentPage: data['page'] as int? ?? 1, 
        pageSize: data['limit'] as int? ?? f.limit, 
        totalItems: data['total'] as int? ?? 0
      );
    });
  }

  Future<List<Publisher>> getAllActive() async {
    if (_cache != null) return _cache!;
    return guard(() async {
      final response = await _dio.get('/publishers', queryParameters: {'all': true, 'deleted': false});
      _cache = (response.data['items'] as List).map((e) => Publisher.fromJson(e)).toList();
      return _cache!;
    });
  }

  Future<Publisher?> findById(int id) => guard(() async {
    final response = await _dio.get('/publishers/$id');
    return Publisher.fromJson(response.data);
  });

  Future<void> saveOrUpdate(Publisher publisher) => guard(() async {
    if (publisher.id == 0) {
      await _dio.post('/publishers', data: publisher.toJson());
    } else {
      await _dio.put('/publishers/${publisher.id}', data: publisher.toJson());
    }
    _cache = null; // Сброс кэша
  });

  Future<void> removeSoft(List<int> ids) => guard(() async {
    await _dio.post('/publishers/bulk-soft-delete', data: {'ids': ids});
    _cache = null;
  });

  Future<void> removeHard(List<int> ids) => guard(() async {
    await _dio.post('/publishers/bulk-hard-delete', data: {'ids': ids});
    _cache = null;
  });

  Future<void> restore(List<int> ids) => guard(() async {
    await _dio.post('/publishers/bulk-restore', data: {'ids': ids});
    _cache = null;
  });
}