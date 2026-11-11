import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/resume.dart';
import '../../../models/skill.dart';

/// Step 3 — add skills as chips, each with a proficiency level.
class SkillsStep extends StatefulWidget {
  final Resume resume;
  final ValueChanged<Resume> onChanged;

  const SkillsStep({
    super.key,
    required this.resume,
    required this.onChanged,
  });

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  static const _levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

  final _controller = TextEditingController();
  String _level = 'Intermediate';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final list = List<Skill>.from(widget.resume.skills)
      ..add(Skill(id: const Uuid().v4(), name: name, level: _level));
    widget.onChanged(widget.resume.copyWith(skills: list));
    _controller.clear();
    setState(() {});
  }

  void _remove(Skill skill) {
    final list =
        widget.resume.skills.where((s) => s.id != skill.id).toList();
    widget.onChanged(widget.resume.copyWith(skills: list));
  }

  @override
  Widget build(BuildContext context) {
    final skills = widget.resume.skills;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Add your skills',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Tip: list at least three to strengthen your resume.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Skill',
                  hintText: 'e.g. Flutter',
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _level,
              onChanged: (v) => setState(() => _level = v ?? _level),
              items: _levels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Add skill'),
          ),
        ),
        const SizedBox(height: 16),
        if (skills.isEmpty)
          Text('No skills added yet.',
              style: Theme.of(context).textTheme.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (s) => Chip(
                    label: Text('${s.name} · ${s.level}'),
                    onDeleted: () => _remove(s),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
