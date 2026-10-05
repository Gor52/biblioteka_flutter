import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/reader.dart';
import '../models/library_card.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/reader_repo.dart';
import '../core/api_exceptions.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? readerId;
  const ReaderFormScreen({super.key, this.readerId});
  
  bool get isEditing => readerId != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  
  bool _isActive = true;
  DateTime _issuedAt = DateTime.now();

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
      final reader = await context.read<ReaderRepo>().findById(widget.readerId!);
      if (reader != null) {
        _fullNameCtrl.text = reader.fullName;
        _emailCtrl.text = reader.email;
        _phoneCtrl.text = reader.phone;
        _cardNumberCtrl.text = reader.card.cardNumber;
        _isActive = reader.card.isActive;
        _issuedAt = reader.card.issuedAt;
      }
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      final reader = Reader(
        id: widget.readerId ?? 0, 
        fullName: _fullNameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        card: LibraryCard(
          cardNumber: _cardNumberCtrl.text,
          isActive: _isActive,
          issuedAt: _issuedAt,
        )
      );
      
      await context.read<ReaderRepo>().saveOrUpdate(reader);
      _isDirty = false;
      if (mounted) context.go('/readers');
      
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
      title: widget.isEditing ? 'Редактирование читателя' : 'Новый читатель',
      isDirty: _isDirty, 
      formKey: _formKey, 
      submitLabel: _saving ? 'Сохранение...' : 'Сохранить',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, 
      onSubmit: _saving ? () {} : _submit, 
      onBack: () => context.go('/readers'),
      fields: [
        TextFormField(
          controller: _fullNameCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'ФИО *'), 
          validator: (v) => _serverErrors['fullName'] ?? AppValidators.requiredField(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCtrl, 
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'E-mail *'), 
                validator: (v) => _serverErrors['email'] ?? AppValidators.email(v),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl, 
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Телефон *'), 
                validator: (v) => _serverErrors['phone'] ?? AppValidators.requiredField(v),
                onChanged: (_) => setState(() => _isDirty = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Читательский билет (Связь 1:1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        TextFormField(
          controller: _cardNumberCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Номер билета *'), 
          validator: (v) => _serverErrors['cardNumber'] ?? AppValidators.requiredField(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Билет активен'),
          value: _isActive,
          onChanged: _saving ? null : (val) {
            setState(() {
              _isActive = val;
              _isDirty = true;
            });
          },
        ),
      ],
    );
  }
}