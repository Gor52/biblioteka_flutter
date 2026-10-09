import 'package:go_router/go_router.dart';
import 'models/list_filter.dart';
import 'models/app_user.dart';
import 'state/auth_provider.dart';

import 'widgets/inactivity_watcher.dart'; 

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forbidden_screen.dart';

import 'screens/role_specific_screens.dart';
import 'screens/registration_screen.dart';

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

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (loggedIn && isPublic) {
        return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return InactivityWatcher(child: child);
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginScreen(from: state.uri.queryParameters['from']),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegistrationScreen(),
          ),
          GoRoute(
            path: '/forbidden',
            builder: (context, state) => const ForbiddenScreen(),
          ),
          GoRoute(
            path: '/', 
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/my-loans',
            redirect: (context, state) => auth.user?.role == Role.reader ? null : '/forbidden',
            builder: (context, state) => const MyLoansScreen(),
          ),
          GoRoute(
            path: '/desk',
            redirect: (context, state) => auth.user?.role == Role.librarian ? null : '/forbidden',
            builder: (context, state) => const LibrarianDeskScreen(),
          ),
          GoRoute(
            path: '/admin',
            redirect: (context, state) => auth.user?.role == Role.admin ? null : '/forbidden',
            builder: (context, state) => const AdminPanelScreen(),
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
          GoRoute(
            path: '/books/new', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, __) => const BookFormScreen(),
          ),
          GoRoute(
            path: '/books/:id/edit', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, state) => BookFormScreen(bookId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/books/:id', 
            builder: (_, state) => BookDetailScreen(bookId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
          ),

          GoRoute(
            path: '/authors',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
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
          GoRoute(
            path: '/authors/new', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, __) => const AuthorFormScreen(),
          ),
          GoRoute(
            path: '/authors/:id/edit', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, state) => AuthorFormScreen(authorId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/authors/:id', 
            builder: (_, state) => AuthorDetailScreen(authorId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
          ),

          GoRoute(
            path: '/readers',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
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
          GoRoute(
            path: '/readers/new', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, __) => const ReaderFormScreen(),
          ),
          GoRoute(
            path: '/readers/:id/edit', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, state) => ReaderFormScreen(readerId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/readers/:id', 
            builder: (_, state) => ReaderDetailScreen(readerId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
          ),

          GoRoute(
            path: '/publishers',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
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
          GoRoute(
            path: '/publishers/new', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, __) => const PublisherFormScreen(),
          ),
          GoRoute(
            path: '/publishers/:id/edit', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, state) => PublisherFormScreen(publisherId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/publishers/:id', 
            builder: (_, state) => PublisherDetailScreen(pubId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
          ),

          GoRoute(
            path: '/genres',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
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
          GoRoute(
            path: '/genres/new', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, __) => const GenreFormScreen(),
          ),
          GoRoute(
            path: '/genres/:id/edit', 
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (_, state) => GenreFormScreen(genreId: int.tryParse(state.pathParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/genres/:id', 
            builder: (_, state) => GenreDetailScreen(genreId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
          ),
        ],
      ),
    ],
  );
}