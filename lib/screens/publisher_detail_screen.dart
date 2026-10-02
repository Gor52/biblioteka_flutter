import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/publisher_repo.dart';
import '../models/publisher.dart';
import '../widgets/generic_detail_layout.dart';

class PublisherDetailScreen extends StatelessWidget {
  final int pubId;
  const PublisherDetailScreen({super.key, required this.pubId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Publisher?>(
      future: context.read<PublisherRepo>().findById(pubId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final pub = snapshot.data;
        if (pub == null) return const Scaffold(body: Center(child: Text('Издательство не найдено')));
        
        return GenericDetailLayout(
          title: pub.name,
          headerIcon: Icons.business,
          onBack: () => context.go('/publishers'),
          onEdit: () => context.go('/publishers/${pub.id}/edit'),
          children: [
            ListTile(leading: const Icon(Icons.location_city), title: const Text('Город'), subtitle: Text(pub.city)),
          ],
        );
      },
    );
  }
}