import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../models/author.dart';
import '../models/publisher.dart';
import '../models/genre.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/book_repo.dart';
import '../repositories/publisher_repo.dart';
import '../repositories/author_repo.dart';
import '../repositories/genre_repo.dart';
import '../core/api_exceptions.dart';

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
  
  int? _selectedPublisherId;
  List<int> _selectedAuthorIds = [];
  List<int> _selectedGenreIds = [];
  
  bool _isLoading = true;
  bool _isDirty = false;
  bool _saving = false;
  Map<String, String> _serverErrors = {};

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
        _selectedPublisherId = book.publisherId;
        _selectedAuthorIds = book.authorIds;
        _selectedGenreIds = book.genreIds;
      }
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      final book = Book(
        id: widget.bookId ?? 0, 
        title: _titleCtrl.text,
        isbn: _isbnCtrl.text,
        year: int.parse(_yearCtrl.text),
        pages: int.parse(_pagesCtrl.text),
        publisherId: _selectedPublisherId!,
        authorIds: _selectedAuthorIds,
        genreIds: _selectedGenreIds,
        copiesTotal: int.parse(_copiesTotalCtrl.text),
      );
      
      await context.read<BookRepo>().saveOrUpdate(book);
      _isDirty = false;
      if (mounted) context.go('/books');
      
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate(); 
    } on ConflictException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.orange));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

@override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final allPublishers = context.watch<PublisherRepo>().getAllActive();
    final allAuthors = context.watch<AuthorRepo>().getAllActive();
    final allGenres = context.watch<GenreRepo>().getAllActive();

    return GenericFormLayout(
      title: widget.isEditing ? 'Редактирование книги' : 'Новая книга',
      isDirty: _isDirty, 
      formKey: _formKey, 
      submitLabel: _saving ? 'Сохранение...' : 'Сохранить книгу',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, 
      onSubmit: _saving ? () {} : _submit, 
      onBack: () => context.go('/books'),
      fields: [
        TextFormField(
          controller: _titleCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Название *'), 
          validator: (v) => _serverErrors['title'] ?? AppValidators.requiredField(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _isbnCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'ISBN *'), 
          validator: (v) => _serverErrors['isbn'] ?? AppValidators.isbn(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearCtrl, 
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Год издания *'), 
                validator: (v) => _serverErrors['year'] ?? AppValidators.year(v),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _pagesCtrl, 
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Страниц *'), 
                validator: (v) => _serverErrors['pages'] ?? AppValidators.positiveInt(v),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _copiesTotalCtrl, 
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Всего экземпляров *'), 
                validator: (v) => _serverErrors['copiesTotal'] ?? AppValidators.positiveInt(v),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        FutureBuilder<List<Publisher>>(
          future: allPublishers,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            return DropdownButtonFormField<int>(
              value: _selectedPublisherId,
              decoration: const InputDecoration(labelText: 'Издательство *'),
              items: items.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: _saving ? null : (v) {
                setState(() {
                  _selectedPublisherId = v;
                  _isDirty = true;
                });
              },
              validator: (v) => _serverErrors['publisherId'] ?? (v == null ? 'Выберите издательство' : null),
            );
          }
        ),
        const SizedBox(height: 24),

        FutureBuilder<List<Author>>(
          future: allAuthors,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            return FormField<List<int>>(
              initialValue: _selectedAuthorIds,
              validator: (v) => _serverErrors['authorIds'] ?? ((v == null || v.isEmpty) ? 'Выберите хотя бы одного автора' : null),
              builder: (field) {
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Авторы *',
                    errorText: field.errorText,
                    border: const OutlineInputBorder(),
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: items.map((a) {
                      final isSelected = field.value!.contains(a.id);
                      return FilterChip(
                        label: Text('${a.lastName} ${a.firstName}'.trim()),
                        selected: isSelected,
                        onSelected: _saving ? null : (selected) {
                          final next = List<int>.from(field.value!);
                          if (selected) next.add(a.id);
                          else next.remove(a.id);
                          field.didChange(next);
                          setState(() {
                            _selectedAuthorIds = next;
                            _isDirty = true;
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            );
          }
        ),
        const SizedBox(height: 24),

        FutureBuilder<List<Genre>>(
          future: allGenres,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            return FormField<List<int>>(
              initialValue: _selectedGenreIds,
              validator: (v) => _serverErrors['genreIds'] ?? ((v == null || v.isEmpty) ? 'Выберите хотя бы один жанр' : null),
              builder: (field) {
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Жанры *',
                    errorText: field.errorText,
                    border: const OutlineInputBorder(),
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: items.map((g) {
                      final isSelected = field.value!.contains(g.id);
                      return FilterChip(
                        label: Text(g.name),
                        selected: isSelected,
                        onSelected: _saving ? null : (selected) {
                          final next = List<int>.from(field.value!);
                          if (selected) next.add(g.id);
                          else next.remove(g.id);
                          field.didChange(next);
                          setState(() {
                            _selectedGenreIds = next;
                            _isDirty = true;
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            );
          }
        ),
      ],
    );
  }
}