import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/reader.dart';
import '../models/library_card.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/reader_repo.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? readerId;
  const ReaderFormScreen({super.key, this.readerId});
  bool get isEditing => readerId != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  final _cardNumberCtrl = TextEditingController(text: 'БК-001');
  bool _cardIsActive = true;
  DateTime _issuedAt = DateTime.now();
  
  String? _emailErrorText;
  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final reader = await context.read<ReaderRepo>().findById(widget.readerId!);
      if (reader != null) {
        _nameCtrl.text = reader.fullName;
        _emailCtrl.text = reader.email;
        _phoneCtrl.text = reader.phone;
        _cardNumberCtrl.text = reader.card.cardNumber;
        _cardIsActive = reader.card.isActive;
        _issuedAt = reader.card.issuedAt;
      }
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    setState(() => _emailErrorText = null);
    if (!_formKey.currentState!.validate()) return;
    
    final repo = context.read<ReaderRepo>();

    if (repo.isEmailTaken(_emailCtrl.text, excludeId: widget.readerId)) {
      setState(() {
        _emailErrorText = 'Этот E-mail уже используется';
        _formKey.currentState!.validate();
      });
      return;
    }

    final reader = Reader(
      id: widget.readerId ?? 0, 
      fullName: _nameCtrl.text, 
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      card: LibraryCard(cardNumber: _cardNumberCtrl.text, issuedAt: _issuedAt, isActive: _cardIsActive),
    );
    
    await repo.saveOrUpdate(reader);
    _isDirty = false;
    if (mounted) context.go('/readers');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return GenericFormLayout(
      title: widget.isEditing ? 'Редактирование читателя' : 'Новый читатель',
      isDirty: _isDirty, 
      formKey: _formKey, 
      submitLabel: 'Сохранить читателя',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, 
      onSubmit: _submit,
      onBack: () => context.go('/readers'),
      fields: [
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'ФИО *'), validator: AppValidators.requiredField),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl, 
          decoration: const InputDecoration(labelText: 'E-mail *'), 
          validator: (v) { if (_emailErrorText != null) return _emailErrorText; return AppValidators.email(v); }
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Телефон *'), validator: AppValidators.requiredField),
        
        const SizedBox(height: 32),
        const Text('Читательский билет (Вложенная сущность 1:1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
        const Divider(),
        const SizedBox(height: 8),
        TextFormField(controller: _cardNumberCtrl, decoration: const InputDecoration(labelText: 'Номер билета *'), validator: AppValidators.requiredField),
        SwitchListTile(
          title: const Text('Билет активен'), 
          value: _cardIsActive, 
          onChanged: (v) => setState(() { _cardIsActive = v; _isDirty = true; })
        )
      ],
    );
  }
}