import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/publisher_provider.dart';
import '../state/book_provider.dart' show ScreenState;
import '../repositories/book_repo.dart';
import '../models/list_filter.dart';
import '../models/publisher.dart';
import '../widgets/adaptive_grid.dart';

class PublisherScreen extends StatefulWidget {
  final ListFilter initFilter;
  const PublisherScreen({super.key, required this.initFilter});

  @override
  State<PublisherScreen> createState() => _PublisherScreenState();
}

class _PublisherScreenState extends State<PublisherScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initFilter.search;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PublisherProvider>().updateFilter(widget.initFilter));
  }

  void _applyFilter(ListFilter f) {
    context.read<PublisherProvider>().updateFilter(f);
    context.go(Uri(path: '/publishers', queryParameters: {
      if (f.search.isNotEmpty) 'search': f.search, 
      'sort': f.sortBy, 'asc': f.isAscending.toString(), 'page': f.page.toString(), 'limit': f.limit.toString(), 
      if (f.showDeleted) 'deleted': 'true',
    }).toString());
  }

  void _confirmDelete(BuildContext context, PublisherProvider prov, String action) {
    final bookRepo = context.read<BookRepo>();
    for (final id in prov.selectedIds) {
      final bookCount = bookRepo.countBooksByPublisher(id);
      if (bookCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Отказ: Издательство (ID: $id) нельзя удалить. Привязано книг: $bookCount.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
        return; 
      }
    }
    
    if (action == 'soft') { prov.executeBatch('soft'); return; }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Внимание! Жесткое удаление'),
        content: Text('Вы собираетесь физически уничтожить ${prov.selectedIds.length} записей без возможности восстановления. Продолжить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { prov.executeBatch('hard'); Navigator.pop(ctx); },
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PublisherProvider>();
    final f = prov.filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательства'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          Row(children: [const Text('Удаленные'), Switch(value: f.showDeleted, onChanged: (v) => _applyFilter(f.copyWith(showDeleted: v, page: 1)))]),
          if (prov.selectedIds.isNotEmpty && !f.showDeleted) IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, prov, 'soft')),
          if (prov.selectedIds.isNotEmpty && f.showDeleted) IconButton(icon: const Icon(Icons.restore), onPressed: () => prov.executeBatch('restore')),

          if (prov.selectedIds.isNotEmpty) IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _confirmDelete(context, prov, 'hard')),
          
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/publishers/new')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), 
            child: TextField(controller: _searchCtrl, decoration: const InputDecoration(labelText: 'Поиск', prefixIcon: Icon(Icons.search)), onSubmitted: (v) => _applyFilter(f.copyWith(search: v, page: 1)))
          ),
          Expanded(
            child: prov.state == ScreenState.loading ? const Center(child: CircularProgressIndicator()) :
                   prov.state == ScreenState.empty ? const Center(child: Text('Список пуст.')) :
                   AdaptiveDataGrid<Publisher>(
                     items: prov.data.items, idExtractor: (p) => p.id, isDeleted: (p) => p.isDeleted,
                     selectedIds: prov.selectedIds, onToggle: prov.toggleSelection, currentSort: f.sortBy, isAscending: f.isAscending,
                     onSort: (key) => _applyFilter(f.copyWith(sortBy: key, isAscending: f.sortBy == key ? !f.isAscending : true)),
                     onRowTap: (id) => context.go('/publishers/$id'),
                     columns: [
                       ColumnDef(title: 'Название', sortKey: 'name', valueBuilder: (p) => p.name),
                       ColumnDef(title: 'Город', sortKey: 'city', valueBuilder: (p) => p.city),
                     ],
                   ),
          ),
          if (prov.state == ScreenState.data)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.first_page), onPressed: f.page > 1 ? () => _applyFilter(f.copyWith(page: 1)) : null),
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: prov.data.canGoBack ? () => _applyFilter(f.copyWith(page: f.page - 1)) : null),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Стр ${f.page} из ${prov.data.totalPages} (Всего: ${prov.data.totalItems})')),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: prov.data.canGoForward ? () => _applyFilter(f.copyWith(page: f.page + 1)) : null),
                  IconButton(icon: const Icon(Icons.last_page), onPressed: f.page < prov.data.totalPages ? () => _applyFilter(f.copyWith(page: prov.data.totalPages)) : null),
                  const SizedBox(width: 24),
                  DropdownButton<int>(
                    value: [10, 25, 50].contains(f.limit) ? f.limit : 10, underline: const SizedBox(),
                    items: const [DropdownMenuItem(value: 10, child: Text('10 шт')), DropdownMenuItem(value: 25, child: Text('25 шт')), DropdownMenuItem(value: 50, child: Text('50 шт'))],
                    onChanged: (v) { if (v != null) _applyFilter(f.copyWith(limit: v, page: 1)); },
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}