import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/author_repo.dart';
import '../models/author.dart';
import '../models/list_filter.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int authorId;
  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AuthorRepo>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Карточка автора (ID: $authorId)'),
        leading: BackButton(onPressed: () => context.go('/authors')),
      ),
      body: FutureBuilder<Author?>(
        future: _findAuthor(repo, authorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final author = snapshot.data;
          if (author == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Автор с таким ID не найден.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/authors'),
                    child: const Text('Вернуться к справочнику'),
                  ),
                ],
              ),
            );
          }

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
                        Text('Информация об авторе', style: Theme.of(context).textTheme.headlineSmall),
                        Chip(
                          label: Text(author.isDeleted ? 'Удален (в корзине)' : 'Активен', 
                            style: TextStyle(color: author.isDeleted ? Colors.red : Colors.green)),
                          backgroundColor: author.isDeleted ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    _buildInfoRow('Идентификатор (ID):', author.id.toString()),
                    _buildInfoRow('Фамилия:', author.lastName),
                    _buildInfoRow('Страна:', author.country),
                    _buildInfoRow('Год рождения:', author.birthYear.toString()),
                    if (author.deletedAt != null)
                      _buildInfoRow('Дата удаления:', author.deletedAt.toString()),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/authors'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Назад к списку авторов'),
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

  Future<Author?> _findAuthor(AuthorRepo repo, int id) async {
    final page = await repo.fetch(const ListFilter(limit: 1000, showDeleted: true));
    try {
      return page.items.firstWhere((a) => a.id == id);
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