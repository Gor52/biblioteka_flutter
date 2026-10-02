import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/genre.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/genre_repo.dart';

class GenreFormScreen extends StatefulWidget {
  final int? genreId;
  const GenreFormScreen({super.key, this.genreId});
  bool get isEditing => genreId != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final genre = await context.read<GenreRepo>().findById(widget.genreId!);
      if (genre != null) _nameCtrl.text = genre.name;
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<GenreRepo>().saveOrUpdate(Genre(id: widget.genreId ?? 0, name: _nameCtrl.text));
    _isDirty = false;
    if (mounted) context.go('/genres');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return GenericFormLayout(
      title: widget.isEditing ? 'Редактирование жанра' : 'Новый жанр',
      isDirty: _isDirty, formKey: _formKey, submitLabel: 'Сохранить',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, onSubmit: _submit, onBack: () => context.go('/genres'),
      fields: [TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Название *'), validator: AppValidators.requiredField)],
    );
  }
}