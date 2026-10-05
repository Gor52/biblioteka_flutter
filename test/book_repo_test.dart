import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:biblioteka_vga/repositories/book_repo.dart';
import 'package:biblioteka_vga/models/book.dart';
import 'package:biblioteka_vga/models/list_filter.dart';
import 'package:biblioteka_vga/core/api_exceptions.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
import 'book_repo_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late BookRepo bookRepo;

  setUp(() {
    mockDio = MockDio();
    bookRepo = BookRepo(mockDio);
  });

  group('BookRepo Tests', () {
    test('1. Успешное получение списка книг (200 OK)', () async {
      final responseData = {
        'items': [
          {'id': 1, 'title': 'Test Book', 'isbn': '123', 'year': 2020, 'pages': 100, 'copiesTotal': 5, 'publisherId': 1, 'authorIds': [1], 'genreIds': [1], 'isDeleted': false}
        ],
        'page': 1,
        'limit': 10,
        'total': 1
      };

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), cancelToken: anyNamed('cancelToken')))
          .thenAnswer((_) async => Response(data: responseData, statusCode: 200, requestOptions: RequestOptions(path: '')));

      final pageData = await bookRepo.fetch(ListFilter());

      expect(pageData.items.length, 1);
      expect(pageData.items.first.title, 'Test Book');
      expect(pageData.totalItems, 1);
    });

    test('2. Обработка недоступности сервера (500 Server Error)', () async {
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), cancelToken: anyNamed('cancelToken')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(statusCode: 500, requestOptions: RequestOptions(path: '')),
            type: DioExceptionType.badResponse,
          ));

      expect(() => bookRepo.fetch(ListFilter()), throwsA(isA<ApiException>()));
    });

    test('3. Разбор ошибки валидации (422 Unprocessable Entity)', () async {
      final book = Book(id: 0, title: 'Err', isbn: '000', year: 2020, pages: 10, copiesTotal: 1, publisherId: 1, authorIds: [1], genreIds: [1]);
      
      when(mockDio.post(any, data: anyNamed('data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              statusCode: 422, 
              data: {'errors': {'isbn': 'Такой ISBN уже существует'}},
              requestOptions: RequestOptions(path: '')
            ),
            type: DioExceptionType.badResponse,
            error: const ValidationException('Ошибка валидации', {'isbn': 'Такой ISBN уже существует'}),
          ));

      try {
        await bookRepo.saveOrUpdate(book);
        fail('Должно быть выброшено ValidationException');
      } catch (e) {
        expect(e, isA<ValidationException>());
        expect((e as ValidationException).errors['isbn'], 'Такой ISBN уже существует');
      }
    });

    test('4. Обработка конфликта (409 Conflict)', () async {
      when(mockDio.post('/books/bulk-hard-delete', data: anyNamed('data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              statusCode: 409, 
              data: {'message': 'Записи используются'},
              requestOptions: RequestOptions(path: '')
            ),
            type: DioExceptionType.badResponse,
            error: const ConflictException('Записи используются'),
          ));

      expect(() => bookRepo.removeHard([1]), throwsA(isA<ConflictException>()));
    });

    test('5. Успешное сохранение новой книги (POST)', () async {
      final book = Book(id: 0, title: 'New Book', isbn: '456', year: 2021, pages: 200, copiesTotal: 2, publisherId: 1, authorIds: [1], genreIds: [1]);
      
      when(mockDio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => Response(statusCode: 201, requestOptions: RequestOptions(path: '')));

      await expectLater(bookRepo.saveOrUpdate(book), completes);
    });
  });
}