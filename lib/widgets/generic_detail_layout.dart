import 'package:flutter/material.dart';

class GenericDetailLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData headerIcon;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final List<Widget> children;
  final bool isDeleted;

  const GenericDetailLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.headerIcon,
    required this.onBack,
    required this.onEdit,
    required this.children,
    this.isDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр записи', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: BackButton(onPressed: onBack),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              color: isDeleted ? Colors.red.shade50 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: isDeleted ? Colors.red.shade100 : Colors.indigo.shade50,
                      child: Icon(headerIcon, size: 40, color: isDeleted ? Colors.red : Colors.indigo),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title, 
                      textAlign: TextAlign.center, 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isDeleted ? TextDecoration.lineThrough : null,
                      )
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                    if (isDeleted)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('[Запись удалена]', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    const Divider(height: 32),
                    
                    ...children, 
                    
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}