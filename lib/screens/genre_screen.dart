import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/genre_provider.dart';
import '../state/book_provider.dart' show ScreenState;
import '../models/list_filter.dart';
import '../models/genre.dart';
import '../widgets/adaptive_grid.dart';

class GenreScreen extends StatefulWidget {
  final ListFilter initFilter;
  const GenreScreen({super.key, required this.initFilter});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initFilter.search;
    WidgetsBinding.instance.addPostFrameCallback((_) => 
      context.read<GenreProvider>().updateFilter(widget.initFilter)
    );
  }

  void _applyFilter(ListFilter f) {
    context.read<GenreProvider>().updateFilter(f);
    context.go(Uri(path: '/genres', queryParameters: {
      if (f.search.isNotEmpty) 'search': f.search, 
      'sort': f.sortBy, 
      'asc': f.isAscending.toString(),
      'page': f.page.toString(), 
      'limit': f.limit.toString(), 
      if (f.showDeleted) 'deleted': 'true',
    }).toString());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<GenreProvider>();
    final f = prov.filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'), 
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          Row(
            children: [
              const Text('Удаленные'), 
              Switch(value: f.showDeleted, onChanged: (v) => _applyFilter(f.copyWith(showDeleted: v, page: 1)))
            ]
          ),
          if (prov.selectedIds.isNotEmpty && !f.showDeleted) 
            IconButton(icon: const Icon(Icons.delete), onPressed: () => prov.executeBatch('soft')),
          if (prov.selectedIds.isNotEmpty && f.showDeleted) 
            IconButton(icon: const Icon(Icons.restore), onPressed: () => prov.executeBatch('restore')),
          if (prov.selectedIds.isNotEmpty) 
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => prov.executeBatch('hard')),
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/genres/new')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), 
            child: TextField(
              controller: _searchCtrl, 
              decoration: const InputDecoration(labelText: 'Поиск по названию', prefixIcon: Icon(Icons.search)), 
              onSubmitted: (v) => _applyFilter(f.copyWith(search: v, page: 1))
            )
          ),
          Expanded(
            child: prov.state == ScreenState.loading ? const Center(child: CircularProgressIndicator()) :
                   prov.state == ScreenState.empty ? const Center(child: Text('Пусто.')) :
                   AdaptiveDataGrid<Genre>(
                     items: prov.data.items, 
                     idExtractor: (g) => g.id, 
                     isDeleted: (g) => g.isDeleted,
                     selectedIds: prov.selectedIds, 
                     onToggle: prov.toggleSelection, 
                     currentSort: f.sortBy, 
                     isAscending: f.isAscending,
                     onSort: (key) => _applyFilter(f.copyWith(sortBy: key, isAscending: f.sortBy == key ? !f.isAscending : true)),
                     onRowTap: (id) => context.go('/genres/$id'),
                     columns: [ColumnDef(title: 'Название', sortKey: 'name', valueBuilder: (g) => g.name)],
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