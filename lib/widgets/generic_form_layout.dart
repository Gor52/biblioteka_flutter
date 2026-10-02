import 'package:flutter/material.dart';

class GenericFormLayout extends StatelessWidget {
  final String title;
  final bool isDirty;
  final GlobalKey<FormState> formKey;
  final VoidCallback onMarkDirty;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final String submitLabel;
  final List<Widget> fields;

  const GenericFormLayout({
    super.key, required this.title, required this.isDirty, required this.formKey,
    required this.onMarkDirty, required this.onSubmit, required this.onBack,
    required this.submitLabel, required this.fields,
  });

  Future<bool> _onWillPop(BuildContext context) async {
    if (!isDirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Вы уверены, что хотите выйти без сохранения? Все данные будут утеряны.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context);
        if (shouldPop && context.mounted) onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          leading: BackButton(onPressed: () async {
            if (await _onWillPop(context)) onBack();
          }),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: formKey,
                    onChanged: onMarkDirty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Divider(height: 32),
                        ...fields,
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          onPressed: onSubmit,
                          icon: const Icon(Icons.save),
                          label: Text(submitLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}