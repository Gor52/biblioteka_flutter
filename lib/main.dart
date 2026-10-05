import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/api_client.dart';
import 'router.dart';
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

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>(create: (_) => buildDio()),
        
        ProxyProvider<Dio, BookRepo>(update: (_, dio, __) => BookRepo(dio)),
        ProxyProvider<Dio, AuthorRepo>(update: (_, dio, __) => AuthorRepo(dio)),
        ProxyProvider<Dio, ReaderRepo>(update: (_, dio, __) => ReaderRepo(dio)),
        ProxyProvider<Dio, PublisherRepo>(update: (_, dio, __) => PublisherRepo(dio)),
        ProxyProvider<Dio, GenreRepo>(update: (_, dio, __) => GenreRepo(dio)),
        
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
    return MaterialApp.router(
      title: 'Библиотечная система',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      routerConfig: router, 
    );
  }
}