import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/publisher_provider.dart';
import '../state/book_provider.dart' show ScreenState;
import '../models/list_filter.dart';
import '../models/publisher.dart';
import '../widgets/adaptive_grid.dart';
import '../core/api_exceptions.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => 
      context.read<PublisherProvider>().updateFilter(widget.initFilter)
    );
  }

  void _applyFilter(ListFilter f) {
    context.read<PublisherProvider>().updateFilter(f);
    context.go(Uri(path: '/publishers', queryParameters: {
      if (f.search.isNotEmpty) 'search': f.search, 
      'sort': f.sortBy, 
      'asc': f.isAscending.toString(),
      'page': f.page.toString(), 
      'limit': f.limit.toString(), 
      if (f.showDeleted) 'deleted': 'true',
    }).toString());
  }

  void _confirmDelete(BuildContext context, PublisherProvider prov, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Удалить выбранные издательства (${prov.selectedIds.length} шт)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            style: action == 'hard' ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await prov.executeBatch(action);
                // ДОБАВЛЕНО УВЕДОМЛЕНИЕ ОБ УСПЕХЕ
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Успешно удалено'), backgroundColor: Colors.green));
              } on ConflictException catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.orange.shade700));
              } on ApiException catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
              }
            },
            child: const Text('Подтвердить'),
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
          Row(
            children: [
              const Text('Удаленные'), 
              Switch(value: f.showDeleted, onChanged: (v) => _applyFilter(f.copyWith(showDeleted: v, page: 1)))
            ]
          ),
          if (prov.selectedIds.isNotEmpty && !f.showDeleted) 
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, prov, 'soft')),
          if (prov.selectedIds.isNotEmpty && f.showDeleted) 
            IconButton(icon: const Icon(Icons.restore), onPressed: () => prov.executeBatch('restore')),
          if (prov.selectedIds.isNotEmpty) 
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _confirmDelete(context, prov, 'hard')),
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/publishers/new')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), 
            child: TextField(
              controller: _searchCtrl, 
              decoration: const InputDecoration(labelText: 'Поиск по названию или городу', prefixIcon: Icon(Icons.search)), 
              onSubmitted: (v) => _applyFilter(f.copyWith(search: v, page: 1))
            )
          ),
          Expanded(
            child: switch (prov.state) {
              ScreenState.loading => const Center(child: CircularProgressIndicator()),
              ScreenState.empty => const Center(child: Text('Издательства не найдены.')),
              ScreenState.error => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${prov.error}', style: const TextStyle(color: Colors.red, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => prov.updateFilter(prov.filter),
                        label: const Text('Повторить попытку'),
                      )
                    ],
                  ),
                ),
              ScreenState.data => AdaptiveDataGrid<Publisher>(
                items: prov.data.items, 
                idExtractor: (p) => p.id, 
                isDeleted: (p) => p.isDeleted,
                selectedIds: prov.selectedIds, 
                onToggle: prov.toggleSelection, 
                currentSort: f.sortBy, 
                isAscending: f.isAscending,
                onSort: (key) => _applyFilter(f.copyWith(sortBy: key, isAscending: f.sortBy == key ? !f.isAscending : true)),
                onRowTap: (id) => context.go('/publishers/$id'),
                columns: [
                  ColumnDef(title: 'Название', sortKey: 'name', valueBuilder: (p) => p.name),
                  ColumnDef(title: 'Город', sortKey: 'city', valueBuilder: (p) => p.city),
                ],
              ),
            },
          ),
          if (prov.state == ScreenState.data)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.first_page), onPressed: f.page > 1 ? () => _applyFilter(f.copyWith(page: 1)) : null),
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: prov.data.canGoBack ? () => _applyFilter(f.copyWith(page: f.page - 1)) : null),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Стр ${f.page} из ${prov.data.totalPages} (Всего: ${prov.data.totalItems})'),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: prov.data.canGoForward ? () => _applyFilter(f.copyWith(page: f.page + 1)) : null),
                  IconButton(icon: const Icon(Icons.last_page), onPressed: f.page < prov.data.totalPages ? () => _applyFilter(f.copyWith(page: prov.data.totalPages)) : null),
                  const SizedBox(width: 24),
                  DropdownButton<int>(
                    value: [10, 25, 50].contains(f.limit) ? f.limit : 10,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10 шт')),
                      DropdownMenuItem(value: 25, child: Text('25 шт')),
                      DropdownMenuItem(value: 50, child: Text('50 шт')),
                    ],
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