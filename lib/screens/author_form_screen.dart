import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/author.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/author_repo.dart';

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
    if (!_formKey.currentState!.validate()) return;
    
    await context.read<AuthorRepo>().saveOrUpdate(Author(
      id: widget.authorId ?? 0, 
      lastName: _lastNameCtrl.text,
      firstName: _firstNameCtrl.text,
      country: _countryCtrl.text,
      birthYear: int.parse(_birthYearCtrl.text),
    ));
    
    _isDirty = false;
    if (mounted) context.go('/authors');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GenericFormLayout(
      title: widget.isEditing ? 'Редактирование автора' : 'Новый автор',
      isDirty: _isDirty, 
      formKey: _formKey, 
      submitLabel: 'Сохранить автора',
      onMarkDirty: () { 
        if (!_isDirty) setState(() => _isDirty = true); 
      }, 
      onSubmit: _submit, 
      onBack: () => context.go('/authors'), // Явный путь назад для правильной работы роутера
      fields: [
        const Text('Основная информация', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _lastNameCtrl, 
          decoration: const InputDecoration(labelText: 'Фамилия *'), 
          validator: AppValidators.requiredField
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstNameCtrl, 
          decoration: const InputDecoration(labelText: 'Имя')
        ),
        const SizedBox(height: 24),

        const Text('Дополнительные данные', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _countryCtrl, 
                decoration: const InputDecoration(labelText: 'Страна *'), 
                validator: AppValidators.requiredField
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _birthYearCtrl, 
                decoration: const InputDecoration(labelText: 'Год рождения *'), 
                keyboardType: TextInputType.number, 
                validator: AppValidators.year
              ),
            ),
          ],
        ),
      ],
    );
  }
}