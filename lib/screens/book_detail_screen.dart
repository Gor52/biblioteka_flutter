import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/book_repo.dart';
import '../models/book.dart';
import '../models/list_filter.dart';

class BookDetailScreen extends StatelessWidget {
  final int bookId;
  const BookDetailScreen({super.key, required this.bookId});

  static const Map<int, String> _genres = {
    1: 'Фантастика',
    2: 'Детектив',
    3: 'Роман',
  };

  static const Map<int, String> _publishers = {
    1: 'АСТ',
    2: 'ЭКСМО',
  };

  @override
  Widget build(BuildContext context) {
    final repo = context.read<BookRepo>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Карточка книги (ID: $bookId)'),
        leading: BackButton(onPressed: () => context.go('/books')),
      ),
      body: FutureBuilder<Book?>(
        future: _findBook(repo, bookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final book = snapshot.data;
          if (book == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Книга с таким ID не найдена.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/books'),
                    child: const Text('Вернуться к каталогу'),
                  ),
                ],
              ),
            );
          }

          final genreName = _genres[book.genreId] ?? 'Другой (ID: ${book.genreId})';
          final publisherName = _publishers[book.publisherId] ?? 'Другое (ID: ${book.publisherId})';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Детали издания', style: Theme.of(context).textTheme.headlineSmall),
                        Chip(
                          label: Text(book.isDeleted ? 'Удалена (в корзине)' : 'Активна', 
                            style: TextStyle(color: book.isDeleted ? Colors.red : Colors.green)),
                          backgroundColor: book.isDeleted ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    _buildInfoRow('Идентификатор (ID):', book.id.toString()),
                    _buildInfoRow('Название книги:', book.title),
                    _buildInfoRow('ISBN:', book.isbn),
                    _buildInfoRow('Год издания:', book.year.toString()),
                    _buildInfoRow('Количество страниц:', book.pages.toString()),
                    _buildInfoRow('Жанр:', genreName),
                    _buildInfoRow('Издательство:', publisherName),
                    if (book.deletedAt != null)
                      _buildInfoRow('Дата удаления:', book.deletedAt.toString()),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/books'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Назад к списку книг'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Book?> _findBook(BookRepo repo, int id) async {
    final page = await repo.fetch(const ListFilter(limit: 1000, showDeleted: true));
    try {
      return page.items.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 220, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}