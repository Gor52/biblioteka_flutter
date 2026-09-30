import 'package:flutter/material.dart';

class ColumnDef<T> {
  final String title;
  final String sortKey;
  final String Function(T) valueBuilder;
  const ColumnDef({required this.title, required this.sortKey, required this.valueBuilder});
}

class AdaptiveDataGrid<T> extends StatelessWidget {
  final List<T> items;
  final List<ColumnDef<T>> columns;
  final int Function(T) idExtractor;
  final bool Function(T) isDeleted;
  final Set<int> selectedIds;
  final Function(int) onToggle;
  final String currentSort;
  final bool isAscending;
  final Function(String) onSort;
  final Function(int)? onRowTap;

  const AdaptiveDataGrid({
    super.key, 
    required this.items, 
    required this.columns,
    required this.idExtractor, 
    required this.isDeleted,
    required this.selectedIds, 
    required this.onToggle,
    required this.currentSort, 
    required this.isAscending, 
    required this.onSort,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final id = idExtractor(item);
              final deleted = isDeleted(item);
              return Card(
                color: selectedIds.contains(id) ? Colors.blue.withOpacity(0.1) : (deleted ? Colors.red.withOpacity(0.05) : null),
                child: ListTile(
                  leading: Checkbox(value: selectedIds.contains(id), onChanged: (_) => onToggle(id)),
                  title: Text(
                    columns.first.valueBuilder(item), 
                    style: TextStyle(decoration: deleted ? TextDecoration.lineThrough : null)
                  ),
                  subtitle: Text(
                    columns.skip(1).map((c) => '${c.title}: ${c.valueBuilder(item)}').join(' • ')
                  ),
                  onTap: () => onRowTap?.call(id),
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
              child: DataTable(
                sortColumnIndex: columns.indexWhere((c) => c.sortKey == currentSort).clamp(0, columns.length),
                sortAscending: isAscending,
                columns: columns.map((c) => DataColumn(label: Text(c.title), onSort: (_, __) => onSort(c.sortKey))).toList(),
                rows: items.map((item) {
                  final id = idExtractor(item);
                  final deleted = isDeleted(item);
                  return DataRow(
                    selected: selectedIds.contains(id),
                    onSelectChanged: (_) => onToggle(id),
                    color: deleted ? WidgetStatePropertyAll(Colors.red.withOpacity(0.05)) : null,
                    cells: columns.asMap().entries.map((entry) {
                      final index = entry.key;
                      final c = entry.value;
                      final cellWidget = Text(
                        c.valueBuilder(item), 
                        style: TextStyle(decoration: deleted ? TextDecoration.lineThrough : null)
                      );
                      if (index == 0 && onRowTap != null) {
                        return DataCell(
                          InkWell(
                            onTap: () => onRowTap!(id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                c.valueBuilder(item), 
                                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)
                              ),
                            ),
                          ),
                        );
                      }
                      return DataCell(cellWidget);
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }
    );
  }
}