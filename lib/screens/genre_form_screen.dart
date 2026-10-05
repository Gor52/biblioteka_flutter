import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/genre.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/genre_repo.dart';
import '../core/api_exceptions.dart';

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
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final genre = await context.read<GenreRepo>().findById(widget.genreId!);
      if (genre != null) {
        _nameCtrl.text = genre.name;
      }
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      final genre = Genre(
        id: widget.genreId ?? 0, 
        name: _nameCtrl.text,
      );
      
      await context.read<GenreRepo>().saveOrUpdate(genre);
      _isDirty = false;
      if (mounted) context.go('/genres');
      
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

    return GenericFormLayout(
      title: widget.isEditing ? 'Редактирование жанра' : 'Новый жанр',
      isDirty: _isDirty, 
      formKey: _formKey, 
      submitLabel: _saving ? 'Сохранение...' : 'Сохранить',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, 
      onSubmit: _saving ? () {} : _submit, 
      onBack: () => context.go('/genres'),
      fields: [
        TextFormField(
          controller: _nameCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Название жанра *'), 
          validator: (v) => _serverErrors['name'] ?? AppValidators.requiredField(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
      ],
    );
  }
}