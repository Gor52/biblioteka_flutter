import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/book_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/author_screen.dart';
import 'screens/author_detail_screen.dart';
import 'models/list_filter.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/books',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return BookScreen(initFilter: ListFilter(
          search: q['search'] ?? '',
          sortBy: q['sort'] ?? 'title',
          isAscending: q['asc'] != 'false',
          page: int.tryParse(q['page'] ?? '1') ?? 1,
          limit: int.tryParse(q['limit'] ?? '10') ?? 10,
          showDeleted: q['deleted'] == 'true',
          genreId: int.tryParse(q['genre'] ?? ''),
          publisherId: int.tryParse(q['pub'] ?? ''),
          minYear: int.tryParse(q['year'] ?? ''),
        ));
      },
    ),
    GoRoute(
      path: '/books/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
        return BookDetailScreen(bookId: id);
      },
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return AuthorScreen(initFilter: ListFilter(
          search: q['search'] ?? '',
          sortBy: q['sort'] ?? 'lastName',
          isAscending: q['asc'] != 'false',
          page: int.tryParse(q['page'] ?? '1') ?? 1,
          limit: int.tryParse(q['limit'] ?? '10') ?? 10,
          showDeleted: q['deleted'] == 'true',
        ));
      },
    ),
    GoRoute(
      path: '/authors/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
        return AuthorDetailScreen(authorId: id);
      },
    ),
  ],
);