class PageData<T> {
  final List<T> items;
  final int currentPage;
  final int pageSize;
  final int totalItems;

  const PageData({
    required this.items,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
  });

  int get totalPages => totalItems == 0 ? 1 : (totalItems / pageSize).ceil();
  bool get canGoBack => currentPage > 1;
  bool get canGoForward => currentPage < totalPages;

  PageData.empty() : items = <T>[], currentPage = 1, pageSize = 10, totalItems = 0;
}