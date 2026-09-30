import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/book_repo.dart';
import 'repositories/author_repo.dart';
import 'state/book_provider.dart';
import 'state/author_provider.dart';
import 'router.dart';

void main() {
  usePathUrlStrategy(); 
  
  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepo>(create: (_) => BookRepo()),
        Provider<AuthorRepo>(create: (_) => AuthorRepo()),
        ChangeNotifierProvider(create: (ctx) => BookProvider(ctx.read<BookRepo>())),
        ChangeNotifierProvider(create: (ctx) => AuthorProvider(ctx.read<AuthorRepo>())),
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
      routerConfig: appRouter,
    );
  }
}