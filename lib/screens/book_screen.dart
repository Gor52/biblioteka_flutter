import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/book_provider.dart';
import '../models/list_filter.dart';
import '../models/book.dart';
import '../widgets/adaptive_grid.dart';

class BookScreen extends StatefulWidget {
  final ListFilter initFilter;
  const BookScreen({super.key, required this.initFilter});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initFilter.search;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().updateFilter(widget.initFilter);
    });
  }

  @override
  void didUpdateWidget(covariant BookScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prov = context.read<BookProvider>();
    if (widget.initFilter != prov.filter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prov.updateFilter(widget.initFilter);
        if (_searchCtrl.text != widget.initFilter.search) {
          _searchCtrl.text = widget.initFilter.search;
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(ListFilter f) {
    context.read<BookProvider>().updateFilter(f);
    
    context.go(Uri(path: '/books', queryParameters: {
      if (f.search.isNotEmpty) 'search': f.search,
      'sort': f.sortBy, 'asc': f.isAscending.toString(),
      'page': f.page.toString(), 'limit': f.limit.toString(),
      if (f.showDeleted) 'deleted': 'true',
      if (f.genreId != null) 'genre': f.genreId.toString(),
      if (f.publisherId != null) 'pub': f.publisherId.toString(),
      if (f.minYear != null) 'year': f.minYear.toString(),
    }).toString());
  }

  void _onSearch(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final prov = context.read<BookProvider>();
      _applyFilter(prov.filter.copyWith(search: val));
    });
  }

  void _confirmAction(BuildContext context, BookProvider prov, String action) {
    final actionNames = {'soft': 'удалить', 'hard': 'удалить навсегда', 'restore': 'восстановить'};
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы действительно хотите ${actionNames[action]} выбранные записи (${prov.selectedIds.length} шт)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              prov.executeBatch(action);
              Navigator.pop(ctx);
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookProvider>();
    final f = prov.filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          Row(
            children: [
              const Text('Показать удаленные'),
              Switch(value: f.showDeleted, onChanged: (v) => _applyFilter(f.copyWith(showDeleted: v))),
            ],
          ),
          if (prov.selectedIds.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Выбрано: ${prov.selectedIds.length}')),
            if (!f.showDeleted) 
              IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmAction(context, prov, 'soft'), tooltip: 'В корзину'),
            if (f.showDeleted) 
              IconButton(icon: const Icon(Icons.restore), onPressed: () => _confirmAction(context, prov, 'restore'), tooltip: 'Восстановить'),
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _confirmAction(context, prov, 'hard'), tooltip: 'Удалить навсегда'),
          ]
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                SizedBox(width: 200, child: TextField(controller: _searchCtrl, decoration: const InputDecoration(labelText: 'Поиск (Название/ISBN)', border: OutlineInputBorder()), onChanged: _onSearch)),
                SizedBox(width: 150, child: DropdownButtonFormField<int?>(value: f.genreId, decoration: const InputDecoration(labelText: 'Жанр', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: null, child: Text('Все')), DropdownMenuItem(value: 1, child: Text('Фантастика')), DropdownMenuItem(value: 2, child: Text('Детектив')), DropdownMenuItem(value: 3, child: Text('Роман'))], onChanged: (v) => _applyFilter(f.copyWith(genreId: v)))),
                SizedBox(width: 150, child: DropdownButtonFormField<int?>(value: f.publisherId, decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: null, child: Text('Все')), DropdownMenuItem(value: 1, child: Text('АСТ')), DropdownMenuItem(value: 2, child: Text('ЭКСМО'))], onChanged: (v) => _applyFilter(f.copyWith(publisherId: v)))),
              ],
            ),
          ),
          Expanded(
            child: switch (prov.state) {
              ScreenState.loading => const Center(child: CircularProgressIndicator()),
              ScreenState.error => Center(child: Text('Ошибка: ${prov.error}')),
              ScreenState.empty => const Center(child: Text('Список пуст. Измените фильтры.')),
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
                  ColumnDef(title: 'Год', sortKey: 'year', valueBuilder: (b) => b.year.toString()),
                  ColumnDef(title: 'Страниц', sortKey: 'pages', valueBuilder: (b) => b.pages.toString()),
                ],
              ),
            },
          ),
          if (prov.state == ScreenState.data)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.first_page), onPressed: prov.data.canGoBack ? () => _applyFilter(f.copyWith(page: 1)) : null),
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: prov.data.canGoBack ? () => _applyFilter(f.copyWith(page: f.page - 1)) : null),
                  Text('Стр ${f.page} из ${prov.data.totalPages} (Всего: ${prov.data.totalItems})'),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: prov.data.canGoForward ? () => _applyFilter(f.copyWith(page: f.page + 1)) : null),
                  IconButton(icon: const Icon(Icons.last_page), onPressed: prov.data.canGoForward ? () => _applyFilter(f.copyWith(page: prov.data.totalPages)) : null),
                  const SizedBox(width: 20),
                  DropdownButton<int>(value: f.limit, items: [10, 25, 50].map((s) => DropdownMenuItem(value: s, child: Text('$s шт'))).toList(), onChanged: (v) => _applyFilter(f.copyWith(limit: v)))
                ],
              ),
            )
        ],
      ),
    );
  }
}