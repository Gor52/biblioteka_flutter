import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../models/author.dart';
import '../repositories/book_repo.dart';
import '../repositories/author_repo.dart';
import '../repositories/publisher_repo.dart';
import '../repositories/genre_repo.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';

class BookFormScreen extends StatefulWidget {
  final int? bookId;
  const BookFormScreen({super.key, this.bookId});
  bool get isEditing => bookId != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();           
  final _copiesTotalCtrl = TextEditingController();    
  final _copiesAvailableCtrl = TextEditingController(); 

  int? _selectedPublisherId;
  List<int> _selectedAuthorIds = [];
  List<int> _selectedGenreIds = [];
  String? _isbnErrorText;
  
  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final book = await context.read<BookRepo>().findById(widget.bookId!);
      if (book != null) {
        _titleCtrl.text = book.title;
        _isbnCtrl.text = book.isbn;
        _yearCtrl.text = book.year.toString();
        _pagesCtrl.text = book.pages.toString();
        _copiesTotalCtrl.text = book.copiesTotal.toString();
        _copiesAvailableCtrl.text = book.copiesAvailable.toString();
        
        _selectedPublisherId = book.publisherId;
        _selectedAuthorIds = List.from(book.authorIds);
        _selectedGenreIds = List.from(book.genreIds);
      }
    } else {
      _pagesCtrl.text = '100';
      _copiesTotalCtrl.text = '1';
      _copiesAvailableCtrl.text = '1';
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    setState(() => _isbnErrorText = null); 
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<BookRepo>();
    
    if (repo.isIsbnTaken(_isbnCtrl.text, excludeId: widget.bookId)) {
      setState(() {
        _isbnErrorText = 'Этот ISBN уже зарегистрирован';
        _formKey.currentState!.validate();
      });
      return;
    }

    await repo.saveOrUpdate(Book(
      id: widget.bookId ?? 0,
      title: _titleCtrl.text,
      isbn: _isbnCtrl.text,
      year: int.parse(_yearCtrl.text),
      pages: int.parse(_pagesCtrl.text),
      copiesTotal: int.parse(_copiesTotalCtrl.text),
      copiesAvailable: int.parse(_copiesAvailableCtrl.text),
      publisherId: _selectedPublisherId!,
      authorIds: _selectedAuthorIds,
      genreIds: _selectedGenreIds,
    ));
    
    _isDirty = false;
    if (mounted) context.go('/books');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final allPublishers = context.read<PublisherRepo>().getAllActive();
    final allAuthors = context.read<AuthorRepo>().getAllActive();
    final allGenres = context.read<GenreRepo>().getAllActive();
    
    List<Author> availableAuthors = allAuthors;
    if (_selectedPublisherId != null) {
      availableAuthors = allAuthors.where((a) => a.lastName.length % 2 == _selectedPublisherId! % 2).toList();
    }

    return GenericFormLayout(
      title: widget.isEditing ? 'Редактирование книги' : 'Новая книга',
      isDirty: _isDirty,
      formKey: _formKey,
      submitLabel: 'Сохранить книгу',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); },
      onSubmit: _submit,
      onBack: () => context.go('/books'),
      fields: [
        const Text('Основная информация', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Название *'), validator: AppValidators.requiredField),
        const SizedBox(height: 16),
        TextFormField(controller: _isbnCtrl, decoration: const InputDecoration(labelText: 'ISBN (10 или 13 цифр) *'), validator: (v) { if (_isbnErrorText != null) return _isbnErrorText; return AppValidators.isbn(v); }),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(child: TextFormField(controller: _yearCtrl, decoration: const InputDecoration(labelText: 'Год издания *'), keyboardType: TextInputType.number, validator: AppValidators.year)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _pagesCtrl, decoration: const InputDecoration(labelText: 'Кол-во страниц *'), keyboardType: TextInputType.number, validator: AppValidators.positiveInt)),
          ],
        ),
        const SizedBox(height: 24),

        const Text('Учет экземпляров', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _copiesTotalCtrl, decoration: const InputDecoration(labelText: 'Всего экземпляров *'), keyboardType: TextInputType.number, validator: AppValidators.positiveInt)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _copiesAvailableCtrl, decoration: const InputDecoration(labelText: 'Доступно для выдачи *'), keyboardType: TextInputType.number, validator: AppValidators.positiveInt)),
          ],
        ),
        const SizedBox(height: 24),

        const Text('Связи и категоризация', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedPublisherId,
          decoration: const InputDecoration(labelText: 'Издательство (М:1) *'),
          items: allPublishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
          onChanged: (v) { setState(() { _selectedPublisherId = v; _selectedAuthorIds.clear(); _isDirty = true; }); },
          validator: (v) => v == null ? 'Выберите издательство' : null,
        ),
        const SizedBox(height: 16),
        
        FormField<List<int>>(
          initialValue: _selectedAuthorIds,
          validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы одного автора' : null,
          builder: (field) => InputDecorator(
            decoration: InputDecoration(labelText: 'Авторы (M:N) *', errorText: field.errorText),
            child: Wrap(
              spacing: 8,
              children: availableAuthors.map((a) {
                final sel = field.value!.contains(a.id);
                return FilterChip(
                  label: Text(a.lastName), selected: sel,
                  onSelected: (_) {
                    final next = [...field.value!]; sel ? next.remove(a.id) : next.add(a.id);
                    field.didChange(next); setState(() { _selectedAuthorIds = next; _isDirty = true; });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        FormField<List<int>>(
          initialValue: _selectedGenreIds,
          validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы один жанр' : null,
          builder: (field) => InputDecorator(
            decoration: InputDecoration(labelText: 'Жанры (M:N) *', errorText: field.errorText),
            child: Wrap(
              spacing: 8,
              children: allGenres.map((g) {
                final sel = field.value!.contains(g.id);
                return FilterChip(
                  label: Text(g.name), selected: sel,
                  onSelected: (_) {
                    final next = [...field.value!]; sel ? next.remove(g.id) : next.add(g.id);
                    field.didChange(next); setState(() { _selectedGenreIds = next; _isDirty = true; });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}