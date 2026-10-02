import 'package:go_router/go_router.dart';
import 'models/list_filter.dart';

import 'screens/home_screen.dart';

import 'screens/book_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';

import 'screens/author_screen.dart';
import 'screens/author_detail_screen.dart';
import 'screens/author_form_screen.dart';

import 'screens/reader_screen.dart';
import 'screens/reader_detail_screen.dart';
import 'screens/reader_form_screen.dart';

import 'screens/publisher_screen.dart';
import 'screens/publisher_detail_screen.dart';
import 'screens/publisher_form_screen.dart';

import 'screens/genre_screen.dart';
import 'screens/genre_detail_screen.dart';
import 'screens/genre_form_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/', 
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/books',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return BookScreen(
          initFilter: ListFilter(
            search: q['search'] ?? '',
            sortBy: q['sort'] ?? 'title',
            isAscending: q['asc'] != 'false',
            page: int.tryParse(q['page'] ?? '1') ?? 1,
            limit: int.tryParse(q['limit'] ?? '10') ?? 10,
            showDeleted: q['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(path: '/books/new', builder: (_, __) => const BookFormScreen()),
    GoRoute(path: '/books/:id/edit', builder: (_, state) => BookFormScreen(bookId: int.tryParse(state.pathParameters['id'] ?? ''))),
    GoRoute(path: '/books/:id', builder: (_, state) => BookDetailScreen(bookId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),

    GoRoute(
      path: '/authors',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return AuthorScreen(
          initFilter: ListFilter(
            search: q['search'] ?? '',
            sortBy: q['sort'] ?? 'lastName',
            isAscending: q['asc'] != 'false',
            page: int.tryParse(q['page'] ?? '1') ?? 1,
            limit: int.tryParse(q['limit'] ?? '10') ?? 10,
            showDeleted: q['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(path: '/authors/new', builder: (_, __) => const AuthorFormScreen()),
    GoRoute(path: '/authors/:id/edit', builder: (_, state) => AuthorFormScreen(authorId: int.tryParse(state.pathParameters['id'] ?? ''))),
    GoRoute(path: '/authors/:id', builder: (_, state) => AuthorDetailScreen(authorId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),

    GoRoute(
      path: '/readers',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return ReaderScreen(
          initFilter: ListFilter(
            search: q['search'] ?? '',
            sortBy: q['sort'] ?? 'fullName',
            isAscending: q['asc'] != 'false',
            page: int.tryParse(q['page'] ?? '1') ?? 1,
            limit: int.tryParse(q['limit'] ?? '10') ?? 10,
            showDeleted: q['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(path: '/readers/new', builder: (_, __) => const ReaderFormScreen()),
    GoRoute(path: '/readers/:id/edit', builder: (_, state) => ReaderFormScreen(readerId: int.tryParse(state.pathParameters['id'] ?? ''))),
    GoRoute(path: '/readers/:id', builder: (_, state) => ReaderDetailScreen(readerId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),

    GoRoute(
      path: '/publishers',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return PublisherScreen(
          initFilter: ListFilter(
            search: q['search'] ?? '',
            sortBy: q['sort'] ?? 'name',
            isAscending: q['asc'] != 'false',
            page: int.tryParse(q['page'] ?? '1') ?? 1,
            limit: int.tryParse(q['limit'] ?? '10') ?? 10,
          ),
        );
      },
    ),
    GoRoute(path: '/publishers/new', builder: (_, __) => const PublisherFormScreen()),
    GoRoute(path: '/publishers/:id/edit', builder: (_, state) => PublisherFormScreen(pubId: int.tryParse(state.pathParameters['id'] ?? ''))),
    GoRoute(path: '/publishers/:id', builder: (_, state) => PublisherDetailScreen(pubId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),

    GoRoute(
      path: '/genres',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return GenreScreen(
          initFilter: ListFilter(
            search: q['search'] ?? '',
            sortBy: q['sort'] ?? 'name',
            isAscending: q['asc'] != 'false',
            page: int.tryParse(q['page'] ?? '1') ?? 1,
            limit: int.tryParse(q['limit'] ?? '10') ?? 10,
            showDeleted: q['deleted'] == 'true',
          ),
        );
      },
    ),
    GoRoute(path: '/genres/new', builder: (_, __) => const GenreFormScreen()),
    GoRoute(path: '/genres/:id/edit', builder: (_, state) => GenreFormScreen(genreId: int.tryParse(state.pathParameters['id'] ?? ''))),
    GoRoute(path: '/genres/:id', builder: (_, state) => GenreDetailScreen(genreId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),
  ],
);