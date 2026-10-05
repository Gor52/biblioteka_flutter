import 'package:dio/dio.dart';
import '../models/reader.dart';
import '../models/list_filter.dart';
import '../models/page_data.dart';
import '../core/api_exceptions.dart';

class ReaderRepo {
  final Dio _dio;
  CancelToken? _searchToken;

  ReaderRepo(this._dio);

  Future<PageData<Reader>> fetch(ListFilter f) async {
    _searchToken?.cancel('Отменено новым запросом');
    _searchToken = CancelToken();

    return guard(() async {
      final response = await _dio.get('/readers', cancelToken: _searchToken, queryParameters: {
        if (f.search.trim().isNotEmpty) 'search': f.search.trim(),
        'sort': '${f.sortBy},${f.isAscending ? 'asc' : 'desc'}',
        'page': f.page,
        'limit': f.limit,
        if (f.showDeleted) 'deleted': true,
      });
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List).map((e) => Reader.fromJson(e)).toList();
      return PageData(
        items: items, 
        currentPage: data['page'] as int? ?? 1, 
        pageSize: data['limit'] as int? ?? f.limit, 
        totalItems: data['total'] as int? ?? 0
      );
    });
  }

  Future<Reader?> findById(int id) => guard(() async {
    final response = await _dio.get('/readers/$id');
    return Reader.fromJson(response.data);
  });

  Future<void> saveOrUpdate(Reader reader) => guard(() async {
    if (reader.id == 0) {
      await _dio.post('/readers', data: reader.toJson());
    } else {
      await _dio.put('/readers/${reader.id}', data: reader.toJson());
    }
  });

  Future<void> removeSoft(List<int> ids) => guard(() => _dio.post('/readers/bulk-soft-delete', data: {'ids': ids}));
  Future<void> removeHard(List<int> ids) => guard(() => _dio.post('/readers/bulk-hard-delete', data: {'ids': ids}));
  Future<void> restore(List<int> ids) => guard(() => _dio.post('/readers/bulk-restore', data: {'ids': ids}));
}