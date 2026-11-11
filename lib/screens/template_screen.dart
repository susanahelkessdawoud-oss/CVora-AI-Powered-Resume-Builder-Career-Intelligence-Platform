import 'package:flutter/material.dart';

import '../models/resume.dart';
import 'preview_screen.dart';

/// Lets the user pick one of two visual styles before previewing.
class TemplateScreen extends StatefulWidget {
  final Resume resume;
  const TemplateScreen({super.key, required this.resume});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  late String _selected = widget.resume.templateId;

  static const _templates = [
    _TemplateOption(
      id: 'modern',
      name: 'Modern',
      description: 'Accent header, clean sections. Great all-rounder.',
      icon: Icons.dashboard_customize_outlined,
    ),
    _TemplateOption(
      id: 'classic',
      name: 'Classic',
      description: 'Centered, black-and-white, traditional and ATS-friendly.',
      icon: Icons.article_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a template')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _templates.length,
                itemBuilder: (context, i) {
                  final t = _templates[i];
                  final selected = t.id == _selected;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Icon(t.icon, size: 36),
                      title: Text(t.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t.description),
                      trailing: selected
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                          : const Icon(Icons.radio_button_unchecked),
                      onTap: () => setState(() => _selected = t.id),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  final updated =
                      widget.resume.copyWith(templateId: _selected);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PreviewScreen(resume: updated),
                    ),
                  );
                },
                child: const Text('Preview resume'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  const _TemplateOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
