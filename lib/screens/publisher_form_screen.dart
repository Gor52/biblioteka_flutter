import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/publisher.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/publisher_repo.dart';
import '../core/api_exceptions.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? publisherId;
  const PublisherFormScreen({super.key, this.publisherId});
  
  bool get isEditing => publisherId != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  
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
      final pub = await context.read<PublisherRepo>().findById(widget.publisherId!);
      if (pub != null) {
        _nameCtrl.text = pub.name;
        _cityCtrl.text = pub.city;
      }
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      final pub = Publisher(
        id: widget.publisherId ?? 0, 
        name: _nameCtrl.text,
        city: _cityCtrl.text,
      );
      
      await context.read<PublisherRepo>().saveOrUpdate(pub);
      _isDirty = false;
      if (mounted) context.go('/publishers');
      
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
      title: widget.isEditing ? 'Редактирование издательства' : 'Новое издательство',
      isDirty: _isDirty, 
      formKey: _formKey, 
      submitLabel: _saving ? 'Сохранение...' : 'Сохранить',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, 
      onSubmit: _saving ? () {} : _submit, 
      onBack: () => context.go('/publishers'),
      fields: [
        TextFormField(
          controller: _nameCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Название издательства *'), 
          validator: (v) => _serverErrors['name'] ?? AppValidators.requiredField(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityCtrl, 
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Город *'), 
          validator: (v) => _serverErrors['city'] ?? AppValidators.requiredField(v),
          onChanged: (_) => setState(() => _isDirty = true),
        ),
      ],
    );
  }
}