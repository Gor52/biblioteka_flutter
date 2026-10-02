import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/book_repo.dart';
import '../repositories/publisher_repo.dart';
import '../repositories/author_repo.dart';
import '../repositories/genre_repo.dart';
import '../widgets/generic_detail_layout.dart';

class BookDetailScreen extends StatelessWidget {
  final int bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadData(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final data = snapshot.data;
        if (data == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Книга не найдена')));
        }
        
        final book = data['book'];
        final pubName = data['pubName'];
        final authors = data['authors'] as String;
        final genres = data['genres'] as String;

        return GenericDetailLayout(
          title: book.title,
          subtitle: 'Год издания: ${book.year}',
          headerIcon: Icons.book,
          isDeleted: book.isDeleted,
          onBack: () => context.go('/books'),
          onEdit: () => context.go('/books/${book.id}/edit'),
          children: [
            ListTile(
              leading: const Icon(Icons.people), 
              title: const Text('Авторы'), 
              subtitle: Text(authors.isEmpty ? 'Не указаны' : authors)
            ),
            ListTile(
              leading: const Icon(Icons.category), 
              title: const Text('Жанры'), 
              subtitle: Text(genres.isEmpty ? 'Не указаны' : genres)
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code), 
              title: const Text('ISBN'), 
              subtitle: Text(book.isbn)
            ),
            ListTile(
              leading: const Icon(Icons.business), 
              title: const Text('Издательство'), 
              subtitle: Text(pubName)
            ),
            ListTile(
              leading: const Icon(Icons.pages), 
              title: const Text('Страниц'), 
              subtitle: Text('${book.pages} стр.')
            ),
            ListTile(
              leading: const Icon(Icons.inventory), 
              title: const Text('Экземпляры (всего / доступно)'), 
              subtitle: Text('${book.copiesTotal} / ${book.copiesAvailable}')
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _loadData(BuildContext context) async {
    final book = await context.read<BookRepo>().findById(bookId);
    if (book == null) return null;

    final pub = await context.read<PublisherRepo>().findById(book.publisherId);

    final authorRepo = context.read<AuthorRepo>();
    final authorNames = <String>[];
    for (final id in book.authorIds) {
      final a = await authorRepo.findById(id);
      if (a != null) {
        authorNames.add('${a.lastName} ${a.firstName}'.trim());
      }
    }

    final genreRepo = context.read<GenreRepo>();
    final genreNames = <String>[];
    for (final id in book.genreIds) {
      final g = await genreRepo.findById(id);
      if (g != null) {
        genreNames.add(g.name);
      }
    }

    return {
      'book': book,
      'pubName': pub?.name ?? 'Неизвестно',
      'authors': authorNames.join(', '),
      'genres': genreNames.join(', '),
    };
  }
}