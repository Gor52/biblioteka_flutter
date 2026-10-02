import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; 

import 'router.dart';
import 'repositories/book_repo.dart';
import 'repositories/author_repo.dart';
import 'repositories/reader_repo.dart';
import 'repositories/publisher_repo.dart';
import 'repositories/genre_repo.dart';

import 'state/book_provider.dart';
import 'state/author_provider.dart';
import 'state/reader_provider.dart';
import 'state/publisher_provider.dart';
import 'state/genre_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepo>(create: (_) => BookRepo(prefs)),
        Provider<AuthorRepo>(create: (_) => AuthorRepo(prefs)),
        Provider<ReaderRepo>(create: (_) => ReaderRepo(prefs)),
        Provider<PublisherRepo>(create: (_) => PublisherRepo(prefs)),
        Provider<GenreRepo>(create: (_) => GenreRepo(prefs)),
        
        ChangeNotifierProvider(create: (ctx) => BookProvider(ctx.read<BookRepo>())),
        ChangeNotifierProvider(create: (ctx) => AuthorProvider(ctx.read<AuthorRepo>())),
        ChangeNotifierProvider(create: (ctx) => ReaderProvider(ctx.read<ReaderRepo>())),
        ChangeNotifierProvider(create: (ctx) => PublisherProvider(ctx.read<PublisherRepo>())),
        ChangeNotifierProvider(create: (ctx) => GenreProvider(ctx.read<GenreRepo>())),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), 
        useMaterial3: true, 
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      routerConfig: router,
    );
  }
}