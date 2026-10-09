import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../state/auth_provider.dart';
import '../core/api_exceptions.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  bool _isLoading = true;
  List<dynamic> myLoans = [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    try {
      final dio = context.read<Dio>();
      final readerId = context.read<AuthProvider>().user?.readerId;
      
      final res = await dio.get('/loans?limit=100');
      
      setState(() {
        myLoans = (res.data['items'] as List).where((loan) {
          return loan['readerId'] == readerId && loan['isReturned'] != true;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _extendLoan(Map<String, dynamic> loan) async {
    try {
      final dio = context.read<Dio>();
      final currentDueDate = DateTime.parse(loan['dueDate']);
      final newDueDate = currentDueDate.add(const Duration(days: 7)).toIso8601String();

      await dio.put('/loans/${loan['id']}', data: {
        'dueDate': newDueDate,
        'extended': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Срок сдачи успешно продлен на 7 дней')),
        );
        _loadLoans(); 
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при продлении')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final readerId = user?.readerId;

    return Scaffold(
      appBar: AppBar(title: const Text('Личный кабинет читателя')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.account_box, size: 40, color: Colors.blue),
                    title: Text(user?.fullName ?? 'Неизвестно', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID профиля в базе: ${readerId ?? "Не привязан"}'),
                  ),
                ),
              ),
              Expanded(
                child: myLoans.isEmpty 
                  ? const Center(child: Text('У вас нет активных выдач'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: myLoans.length,
                      itemBuilder: (context, index) {
                        final loan = myLoans[index];
                        final dueDate = DateTime.parse(loan['dueDate']);
                        final isOverdue = dueDate.isBefore(DateTime.now());
                        final isExtended = loan['extended'] == true;

                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.book, color: isOverdue ? Colors.red : Colors.green),
                            title: Text(loan['bookTitle']),
                            subtitle: Text(
                              'Сдать до: ${dueDate.day.toString().padLeft(2, '0')}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.year}',
                              style: TextStyle(color: isOverdue ? Colors.red : null, fontWeight: isOverdue ? FontWeight.bold : null),
                            ),
                            trailing: FilledButton.tonal(
                              onPressed: isExtended ? null : () => _extendLoan(loan),
                              child: const Text('Продлить'),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}

class LibrarianDeskScreen extends StatefulWidget {
  const LibrarianDeskScreen({super.key});

  @override
  State<LibrarianDeskScreen> createState() => _LibrarianDeskScreenState();
}

class _LibrarianDeskScreenState extends State<LibrarianDeskScreen> {
  bool _isLoading = true;
  
  List<dynamic> _books = [];
  List<dynamic> _readers = [];
  List<dynamic> _activeLoans = [];
  
  int? _selectedBookId;
  int? _selectedReaderId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dio = context.read<Dio>();
      final results = await Future.wait([
        dio.get('/books?limit=100'),
        dio.get('/readers?limit=100'),
        dio.get('/loans?limit=100'),
      ]);

      setState(() {
        _books = results[0].data['items'] ?? [];
        _readers = results[1].data['items'] ?? [];
        _activeLoans = (results[2].data['items'] as List)
            .where((l) => l['isReturned'] != true)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _issueBook() async {
    if (_selectedBookId == null || _selectedReaderId == null) return;

    final reader = _readers.firstWhere((r) => r['id'] == _selectedReaderId);
    final book = _books.firstWhere((b) => b['id'] == _selectedBookId);

    try {
      final dio = context.read<Dio>();
      final dueDate = DateTime.now().add(const Duration(days: 14)).toIso8601String();
      
      await dio.post('/loans', data: {
        'readerId': reader['id'],
        'readerName': reader['fullName'],
        'bookId': book['id'],
        'bookTitle': book['title'],
        'issueDate': DateTime.now().toIso8601String(),
        'dueDate': dueDate,
        'extended': false,
        'isReturned': false,
      });

      setState(() {
        _selectedBookId = null;
        _selectedReaderId = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выдача успешно оформлена')));
        _loadData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка оформления выдачи')));
      }
    }
  }

  Future<void> _returnBook(int loanId) async {
    try {
      final dio = context.read<Dio>();
      await dio.put('/loans/$loanId', data: {
        'isReturned': true,
        'returnDate': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Книга возвращена в библиотеку')));
        _loadData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка при возврате')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рабочий стол библиотекаря')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Оформление новой выдачи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Выберите читателя', border: OutlineInputBorder()),
                        value: _selectedReaderId,
                        items: _readers.map((r) => DropdownMenuItem<int>(
                          value: r['id'],
                          child: Text(r['fullName']),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedReaderId = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Выберите книгу', border: OutlineInputBorder()),
                        value: _selectedBookId,
                        items: _books.map((b) => DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text('${b['title']} (Остаток: ${b['copiesTotal'] ?? 1})'),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedBookId = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: (_selectedBookId == null || _selectedReaderId == null) ? null : _issueBook,
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0), child: Text('Выдать')),
                    ),
                  ],
                ),
                const Divider(height: 48),
                const Text('Активные выдачи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: _activeLoans.isEmpty 
                    ? const Center(child: Text('Нет активных выдач'))
                    : ListView.builder(
                        itemCount: _activeLoans.length,
                        itemBuilder: (context, index) {
                          final loan = _activeLoans[index];
                          final issueDate = DateTime.parse(loan['issueDate']);
                          return Card(
                            child: ListTile(
                              title: Text('${loan['bookTitle']} -> ${loan['readerName']}'),
                              subtitle: Text('Выдана: ${issueDate.day.toString().padLeft(2, '0')}.${issueDate.month.toString().padLeft(2, '0')}.${issueDate.year}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.assignment_return, color: Colors.blue),
                                tooltip: 'Принять возврат',
                                onPressed: () => _returnBook(loan['id']),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final dio = context.read<Dio>();
      final res = await dio.get('/users');
      
      setState(() {
        _users = res.data['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showSnackBar('Ошибка загрузки пользователей');
    }
  }

  Future<void> _changeRole(int userId, String newRole) async {
    try {
      final dio = context.read<Dio>();
      await dio.put('/users/$userId/role', data: {'role': newRole});
      _showSnackBar('Роль успешно изменена');
      _loadUsers(); 
    } on ApiException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Ошибка при изменении роли');
    }
  }

  Future<void> _restoreAll() async {
    try {
      final dio = context.read<Dio>();
      await dio.post('/system/bulk-restore');
      _showSnackBar('Все удаленные записи успешно восстановлены');
    } on ApiException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Ошибка при восстановлении базы данных');
    }
  }

  Future<void> _hardDeleteAll() async {
    try {
      final dio = context.read<Dio>();
      await dio.post('/system/bulk-hard-delete');
      _showSnackBar('Корзина базы данных успешно очищена');
    } on ApiException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Ошибка при физическом удалении данных');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: message.contains('Отказ') || message.contains('Ошибка') ? Colors.red : Colors.green
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        backgroundColor: Colors.red.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Управление ролями пользователей', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _users.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isSelf = user['username'] == 'admin';

                      return ListTile(
                        leading: Icon(Icons.person, color: user['role'] == 'admin' ? Colors.red : Colors.blue),
                        title: Text('${user['fullName']} (${user['username']})'),
                        subtitle: Text(user['email']),
                        trailing: isSelf 
                          ? const Text('Вы', style: TextStyle(color: Colors.grey))
                          : DropdownButton<String>(
                              value: user['role'],
                              items: const [
                                DropdownMenuItem(value: 'reader', child: Text('Читатель')),
                                DropdownMenuItem(value: 'librarian', child: Text('Библиотекарь')),
                                DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                              ],
                              onChanged: (val) {
                                if (val != null && val != user['role']) {
                                  _changeRole(user['id'], val);
                                }
                              },
                            ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Управление базой данных', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: Colors.orange.shade50,
                  leading: const Icon(Icons.restore, color: Colors.orange),
                  title: const Text('Восстановить удаленные записи'),
                  trailing: FilledButton.tonal(
                    onPressed: _restoreAll, 
                    child: const Text('Восстановить'),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: Colors.red.shade50,
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Физическое удаление (Очистка корзины)'),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _hardDeleteAll, 
                    child: const Text('Удалить навсегда'),
                  ),
                ),
              ],
            ),
    );
  }
}