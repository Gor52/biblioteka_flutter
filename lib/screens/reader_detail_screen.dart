import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../repositories/reader_repo.dart';
import '../models/reader.dart';
import '../widgets/generic_detail_layout.dart';

class ReaderDetailScreen extends StatelessWidget {
  final int readerId;
  const ReaderDetailScreen({super.key, required this.readerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Reader?>(
      future: context.read<ReaderRepo>().findById(readerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final reader = snapshot.data;
        if (reader == null) {
          return const Scaffold(body: Center(child: Text('Читатель не найден')));
        }
        
        return GenericDetailLayout(
          title: reader.fullName,
          subtitle: reader.email,
          headerIcon: Icons.card_membership,
          isDeleted: reader.isDeleted,
          onBack: () => context.go('/readers'),
          onEdit: () => context.go('/readers/${reader.id}/edit'),
          children: [
            ListTile(
              leading: const Icon(Icons.phone), 
              title: const Text('Телефон'), 
              subtitle: Text(reader.phone)
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Читательский билет', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)
              ),
            ),
            ListTile(
              leading: const Icon(Icons.pin), 
              title: const Text('Номер билета'), 
              subtitle: Text(reader.card.cardNumber)
            ),
            ListTile(
              leading: Icon(
                reader.card.isActive ? Icons.check_circle : Icons.cancel, 
                color: reader.card.isActive ? Colors.green : Colors.red
              ), 
              title: const Text('Статус'), 
              subtitle: Text(reader.card.isActive ? "Активен" : "Заблокирован")
            ),
          ],
        );
      },
    );
  }
}