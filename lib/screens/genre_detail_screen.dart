import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/genre_repo.dart';
import '../models/genre.dart';
import '../widgets/generic_detail_layout.dart';

class GenreDetailScreen extends StatelessWidget {
  final int genreId;
  const GenreDetailScreen({super.key, required this.genreId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Genre?>(
      future: context.read<GenreRepo>().findById(genreId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final genre = snapshot.data;
        if (genre == null) return const Scaffold(body: Center(child: Text('Жанр не найден')));
        
        return GenericDetailLayout(
          title: genre.name,
          headerIcon: Icons.category,
          isDeleted: genre.isDeleted,
          onBack: () => context.go('/genres'),
          onEdit: () => context.go('/genres/${genre.id}/edit'),
          children: const [
            ListTile(leading: Icon(Icons.info_outline), title: Text('Тип'), subtitle: Text('Литературный жанр')),
          ],
        );
      },
    );
  }
}