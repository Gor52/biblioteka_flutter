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
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/authors'),
              icon: const Icon(Icons.person), label: const Text('Справочник авторов'),
            ),
          ],
        ),
      ),
    );
  }
}