import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../models/app_user.dart'; // Обязательно для использования Role

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final role = user?.role ?? Role.reader;

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? 'Библиотека — ${user.fullName}' : 'Управление библиотекой'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- ОБЩИЕ ФУНКЦИИ (Доступны всем) ---
              const Text('Каталог', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.go('/books'),
                icon: const Icon(Icons.book), label: const Text('Каталог книг'),
              ),
              const SizedBox(height: 24),

              // --- УНИКАЛЬНАЯ ФУНКЦИЯ ЧИТАТЕЛЯ ---
              if (role == Role.reader) ...[
                const Text('Личный кабинет', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.go('/my-loans'),
                  icon: const Icon(Icons.bookmark), label: const Text('Мои выдачи и продление'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(height: 24),
              ],

              // --- ФУНКЦИИ БИБЛИОТЕКАРЯ И АДМИНА ---
              if (auth.has(Role.librarian)) ...[
                const Text('Управление библиотекой', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 8),
                
                // Уникальная функция только для библиотекаря
                if (role == Role.librarian) ...[
                  FilledButton.icon(
                    onPressed: () => context.go('/desk'),
                    icon: const Icon(Icons.assignment_turned_in), label: const Text('Оформление выдач'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                ],

                // Справочники, доступные библиотекарю и админу
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
                const SizedBox(height: 24),
              ],

              // --- УНИКАЛЬНАЯ ФУНКЦИЯ АДМИНИСТРАТОРА ---
              if (role == Role.admin) ...[
                const Text('Система', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.settings), label: const Text('Панель администратора'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}