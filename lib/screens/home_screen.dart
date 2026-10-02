import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление библиотекой')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/books'),
              icon: const Icon(Icons.book), label: const Text('Каталог книг'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/authors'),
              icon: const Icon(Icons.person), label: const Text('Справочник авторов'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/readers'),
              icon: const Icon(Icons.card_membership), label: const Text('Читатели'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/publishers'),
              icon: const Icon(Icons.business), label: const Text('Издательства'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/genres'),
              icon: const Icon(Icons.category), label: const Text('Жанры'),
            ),
          ],
        ),
      ),
    );
  }
}