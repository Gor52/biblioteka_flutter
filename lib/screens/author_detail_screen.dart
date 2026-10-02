import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/author_repo.dart';
import '../models/author.dart';
import '../widgets/generic_detail_layout.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int authorId;
  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Author?>(
      future: context.read<AuthorRepo>().findById(authorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final author = snapshot.data;
        if (author == null) {
          return const Scaffold(body: Center(child: Text('Автор не найден')));
        }
        
        return GenericDetailLayout(
          title: '${author.lastName} ${author.firstName}'.trim(),
          subtitle: 'Писатель',
          headerIcon: Icons.person,
          isDeleted: author.isDeleted,
          onBack: () => context.go('/authors'),
          onEdit: () => context.go('/authors/${author.id}/edit'),
          children: [
            ListTile(
              leading: const Icon(Icons.public), 
              title: const Text('Страна'), 
              subtitle: Text(author.country)
            ),
            ListTile(
              leading: const Icon(Icons.cake), 
              title: const Text('Год рождения'), 
              subtitle: Text(author.birthYear.toString())
            ),
          ],
        );
      },
    );
  }
}