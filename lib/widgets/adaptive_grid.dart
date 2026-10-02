import 'package:flutter/material.dart';

class ColumnDef<T> {
  final String title;
  final String sortKey;
  final String Function(T) valueBuilder;
  ColumnDef({required this.title, required this.sortKey, required this.valueBuilder});
}

class AdaptiveDataGrid<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T) idExtractor;
  final bool Function(T) isDeleted;
  final Set<int> selectedIds; 
  final Function(int) onToggle;
  final String currentSort;
  final bool isAscending;
  final Function(String) onSort;
  final Function(int)? onRowTap;
  final List<ColumnDef<T>> columns;

  const AdaptiveDataGrid({
    super.key, required this.items, required this.idExtractor, required this.isDeleted,
    required this.selectedIds, required this.onToggle, required this.currentSort,
    required this.isAscending, required this.onSort, required this.columns, this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth < 600) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            final id = idExtractor(item);
            final deleted = isDeleted(item);
            return Card(
              color: deleted ? Colors.red.shade50 : Colors.white,
              child: ListTile(
                leading: Checkbox(value: selectedIds.contains(id), onChanged: (_) => onToggle(id)),
                title: Text(
                  columns.first.valueBuilder(item), 
                  style: TextStyle(decoration: deleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)
                ),
                subtitle: Text(columns.skip(1).map((c) => '${c.title}: ${c.valueBuilder(item)}').join('\n')),
                onTap: onRowTap != null ? () => onRowTap!(id) : null,
              ),
            );
          },
        );
      }

      return Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth - 32), // Растягиваем на всю ширину
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
              showCheckboxColumn: true,
              sortColumnIndex: columns.indexWhere((c) => c.sortKey == currentSort).clamp(0, columns.length - 1),
              sortAscending: isAscending,
              columns: columns.map((c) => DataColumn(
                label: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)), 
                onSort: (_, __) => onSort(c.sortKey)
              )).toList(),
              rows: items.map((item) {
                final id = idExtractor(item);
                final deleted = isDeleted(item);
                return DataRow(
                  color: deleted ? WidgetStateProperty.all(Colors.red.shade50) : null,
                  selected: selectedIds.contains(id),
                  onSelectChanged: (_) => onToggle(id),
                  cells: columns.map((c) => DataCell(
                    Text(c.valueBuilder(item), style: TextStyle(decoration: deleted ? TextDecoration.lineThrough : null)),
                    onTap: onRowTap != null ? () => onRowTap!(id) : null,
                  )).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      );
    });
  }
}