import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/book_provider.dart';
import '../repositories/genre_repo.dart';
import '../repositories/publisher_repo.dart';
import '../models/list_filter.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../widgets/adaptive_grid.dart';

class BookScreen extends StatefulWidget {
  final ListFilter initFilter;
  const BookScreen({super.key, required this.initFilter});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initFilter.search;
    WidgetsBinding.instance.addPostFrameCallback((_) => 
      context.read<BookProvider>().updateFilter(widget.initFilter)
    );
  }

  void _applyFilter(ListFilter f) {
    context.read<BookProvider>().updateFilter(f);
    context.go(Uri(path: '/books', queryParameters: {
      if (f.search.isNotEmpty) 'search': f.search, 
      'sort': f.sortBy, 
      'asc': f.isAscending.toString(),
      'page': f.page.toString(), 
      'limit': f.limit.toString(), 
      if (f.showDeleted) 'deleted': 'true',
      if (f.genreId != null) 'genre': f.genreId.toString(),
      if (f.publisherId != null) 'pub': f.publisherId.toString(),
    }).toString());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookProvider>();
    final f = prov.filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
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
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/books/new')),
        ],
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16.0), 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchCtrl, 
                    decoration: const InputDecoration(labelText: 'Поиск (Название/ISBN)', prefixIcon: Icon(Icons.search)), 
                    onSubmitted: (v) => _applyFilter(f.copyWith(search: v, page: 1))
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  flex: 1,
                  child: FutureBuilder<List<Genre>>(
                    future: context.read<GenreRepo>().getAllActive(),
                    builder: (context, snapshot) {
                      final genres = snapshot.data ?? [];
                      return DropdownButtonFormField<int?>(
                        value: f.genreId,
                        decoration: const InputDecoration(labelText: 'Жанр'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Все жанры')),
                          ...genres.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                        ],
                        onChanged: (v) => _applyFilter(ListFilter(search: f.search, sortBy: f.sortBy, isAscending: f.isAscending, page: 1, limit: f.limit, showDeleted: f.showDeleted, genreId: v, publisherId: f.publisherId)),
                      );
                    }
                  ),
                ),
                const SizedBox(width: 16),
                
                // Фильтр по издательствам (асинхронно берется из кэшированного API)
                Expanded(
                  flex: 1,
                  child: FutureBuilder<List<Publisher>>(
                    future: context.read<PublisherRepo>().getAllActive(),
                    builder: (context, snapshot) {
                      final publishers = snapshot.data ?? [];
                      return DropdownButtonFormField<int?>(
                        value: f.publisherId,
                        decoration: const InputDecoration(labelText: 'Издательство'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Все издательства')),
                          ...publishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        ],
                        onChanged: (v) => _applyFilter(ListFilter(search: f.search, sortBy: f.sortBy, isAscending: f.isAscending, page: 1, limit: f.limit, showDeleted: f.showDeleted, genreId: f.genreId, publisherId: v)),
                      );
                    }
                  ),
                ),
              ],
            )
          ),
          
          // ТАБЛИЦА С СОСТОЯНИЯМИ
          Expanded(
            child: switch (prov.state) {
              ScreenState.loading => const Center(child: CircularProgressIndicator()),
              ScreenState.empty => const Center(child: Text('Список пуст. Измените фильтры.')),
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
              ScreenState.data => AdaptiveDataGrid<Book>(
                items: prov.data.items,
                idExtractor: (b) => b.id,
                isDeleted: (b) => b.isDeleted,
                selectedIds: prov.selectedIds,
                onToggle: prov.toggleSelection,
                currentSort: f.sortBy,
                isAscending: f.isAscending,
                onSort: (key) => _applyFilter(f.copyWith(sortBy: key, isAscending: f.sortBy == key ? !f.isAscending : true)),
                onRowTap: (id) => context.go('/books/$id'),
                columns: [
                  ColumnDef(title: 'Название', sortKey: 'title', valueBuilder: (b) => b.title),
                  ColumnDef(title: 'ISBN', sortKey: 'isbn', valueBuilder: (b) => b.isbn),
                  ColumnDef(title: 'Год', sortKey: 'year', valueBuilder: (b) => b.year.toString()),
                  ColumnDef(title: 'Страниц', sortKey: 'pages', valueBuilder: (b) => b.pages.toString()),
                ],
              ),
            },
          ),
          
          // ПАГИНАЦИЯ (Снизу как на макете)
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