import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'router.dart';
import 'state/auth_provider.dart';

import 'repositories/book_repo.dart';
import 'repositories/author_repo.dart';
import 'repositories/genre_repo.dart';
import 'repositories/publisher_repo.dart';
import 'repositories/reader_repo.dart';

import 'state/book_provider.dart';
import 'state/author_provider.dart';
import 'state/reader_provider.dart';
import 'state/genre_provider.dart';
import 'state/publisher_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  
  var authProvider = AuthProvider(prefs, Dio());
  final dio = buildDio(authProvider);
  
  // =========================================================================
  // ДОБАВЛЕННЫЙ БЛОК: Глобальный перехватчик для добавления токена ко всем запросам
  // =========================================================================
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Читаем актуальный токен из локального хранилища
        final token = prefs.getString('auth_access_token');
        
        // Если токен есть и заголовок еще не был добавлен вручную — прикрепляем его
        if (token != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
    ),
  );
  // =========================================================================

  authProvider = AuthProvider(prefs, dio);
  
  await authProvider.restore();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        
        ProxyProvider<Dio, BookRepo>(update: (_, d, __) => BookRepo(d)),
        ProxyProvider<Dio, AuthorRepo>(update: (_, d, __) => AuthorRepo(d)),
        ProxyProvider<Dio, ReaderRepo>(update: (_, d, __) => ReaderRepo(d)),
        ProxyProvider<Dio, PublisherRepo>(update: (_, d, __) => PublisherRepo(d)),
        ProxyProvider<Dio, GenreRepo>(update: (_, d, __) => GenreRepo(d)),
        
        ChangeNotifierProvider(create: (ctx) => BookProvider(ctx.read<BookRepo>())),
        ChangeNotifierProvider(create: (ctx) => AuthorProvider(ctx.read<AuthorRepo>())),
        ChangeNotifierProvider(create: (ctx) => ReaderProvider(ctx.read<ReaderRepo>())),
        ChangeNotifierProvider(create: (ctx) => GenreProvider(ctx.read<GenreRepo>())),
        ChangeNotifierProvider(create: (ctx) => PublisherProvider(ctx.read<PublisherRepo>())),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final router = buildRouter(auth);

    return MaterialApp.router(
      title: 'Библиотечная система',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), 
        useMaterial3: true,
      ),
      routerConfig: router, 
    );
  }
}