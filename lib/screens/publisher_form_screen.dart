import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/publisher.dart';
import '../utils/validators.dart';
import '../widgets/generic_form_layout.dart';
import '../repositories/publisher_repo.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? pubId;
  const PublisherFormScreen({super.key, this.pubId});
  bool get isEditing => pubId != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  
  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isEditing) {
      final pub = await context.read<PublisherRepo>().findById(widget.pubId!);
      if (pub != null) {
        _nameCtrl.text = pub.name;
        _cityCtrl.text = pub.city;
      }
    }
    setState(() => _isLoading = false);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    await context.read<PublisherRepo>().saveOrUpdate(Publisher(
      id: widget.pubId ?? 0, 
      name: _nameCtrl.text, 
      city: _cityCtrl.text,
    ));
    _isDirty = false;
    if (mounted) context.go('/publishers');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return GenericFormLayout(
      title: widget.isEditing ? 'Редактирование издательства' : 'Новое издательство',
      isDirty: _isDirty, formKey: _formKey, submitLabel: 'Сохранить',
      onMarkDirty: () { if (!_isDirty) setState(() => _isDirty = true); }, onSubmit: _submit,
      onBack: () => context.go('/publishers'),
      fields: [
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Название *'), validator: AppValidators.requiredField),
        const SizedBox(height: 16),
        TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'Город *'), validator: AppValidators.requiredField),
      ],
    );
  }
}