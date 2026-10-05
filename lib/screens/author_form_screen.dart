import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/author.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/author_repo.dart';
import '../core/api_exceptions.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? authorId;
  const AuthorFormScreen({super.key, this.authorId});
  
  bool get isEditing => authorId != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _birthYearCtrl = TextEditingController();
  
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
      final author = await context.read<AuthorRepo>().findById(widget.authorId!);
      if (author != null) {
        _lastNameCtrl.text = author.lastName;
        _firstNameCtrl.text = author.firstName;
        _countryCtrl.text = author.country;
        _birthYearCtrl.text = author.birthYear.toString();
      }
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      final author = Author(
        id: widget.authorId ?? 0, 
        lastName: _lastNameCtrl.text,
        firstName: _firstNameCtrl.text,
        country: _countryCtrl.text,
        birthYear: int.parse(_birthYearCtrl.text),
      );
      
      await context.read<AuthorRepo>().saveOrUpdate(author);
      _isDirty = false;
      if (mounted) context.go('/authors');
      
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
      title: widget.isEditing ? 'Редактирование автора' : 'Новый автор',
      isDirty: _isDirty, 
      formKey: _formKey, 
      submitLabel: _saving ? 'Сохранение...' : 'Сохранить',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, 
      onSubmit: _saving ? () {} : _submit, 
      onBack: () => context.go('/authors'),
      fields: [
        TextFormField(
          controller: _lastNameCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Фамилия *'), 
          validator: (v) => _serverErrors['lastName'] ?? AppValidators.requiredField(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstNameCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Имя'), 
          validator: (v) => _serverErrors['firstName'],
          onChanged: (_) => setState(() => _isDirty = true),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _countryCtrl, 
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Страна *'), 
                validator: (v) => _serverErrors['country'] ?? AppValidators.requiredField(v),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _birthYearCtrl, 
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Год рождения *'), 
                validator: (v) => _serverErrors['birthYear'] ?? AppValidators.year(v),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}