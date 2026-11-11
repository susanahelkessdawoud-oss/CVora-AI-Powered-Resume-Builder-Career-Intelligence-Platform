import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/experience.dart';
import '../../../models/resume.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/state_views.dart';

/// Step 2 — a reorder-free list of work experiences. Experience is optional;
/// an empty state makes that clear so users are never pushed to invent jobs.
class ExperienceStep extends StatelessWidget {
  final Resume resume;
  final ValueChanged<Resume> onChanged;

  const ExperienceStep({
    super.key,
    required this.resume,
    required this.onChanged,
  });

  Future<void> _addOrEdit(BuildContext context, {Experience? existing}) async {
    final result = await showModalBottomSheet<Experience>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExperienceForm(existing: existing),
    );
    if (result == null) return;

    final list = List<Experience>.from(resume.experiences);
    final index = list.indexWhere((e) => e.id == result.id);
    if (index >= 0) {
      list[index] = result;
    } else {
      list.add(result);
    }
    onChanged(resume.copyWith(experiences: list));
  }

  void _delete(Experience exp) {
    final list =
        resume.experiences.where((e) => e.id != exp.id).toList();
    onChanged(resume.copyWith(experiences: list));
  }

  @override
  Widget build(BuildContext context) {
    final items = resume.experiences;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () => _addOrEdit(context),
            icon: const Icon(Icons.add),
            label: const Text('Add experience'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyView(
                  icon: Icons.work_outline,
                  title: 'No experience added',
                  message:
                      'Experience is optional. You can skip this and focus '
                      'on skills, projects and education instead.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final exp = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(exp.position.isEmpty
                            ? exp.company
                            : exp.position),
                        subtitle: Text([exp.company, exp.dateRange]
                            .where((s) => s.isNotEmpty)
                            .join(' · ')),
                        onTap: () => _addOrEdit(context, existing: exp),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(exp),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ExperienceForm extends StatefulWidget {
  final Experience? existing;
  const _ExperienceForm({this.existing});

  @override
  State<_ExperienceForm> createState() => _ExperienceFormState();
}

class _ExperienceFormState extends State<_ExperienceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _company;
  late final TextEditingController _position;
  late final TextEditingController _description;
  late final TextEditingController _start;
  late final TextEditingController _end;
  bool _isCurrent = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _company = TextEditingController(text: e?.company ?? '');
    _position = TextEditingController(text: e?.position ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _start = TextEditingController(text: e?.startDate ?? '');
    _end = TextEditingController(text: e?.endDate ?? '');
    _isCurrent = e?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _company.dispose();
    _position.dispose();
    _description.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Experience(
        id: widget.existing?.id ?? const Uuid().v4(),
        company: _company.text.trim(),
        position: _position.text.trim(),
        description: _description.text.trim(),
        startDate: _start.text.trim(),
        endDate: _isCurrent ? '' : _end.text.trim(),
        isCurrent: _isCurrent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.existing == null
                  ? 'Add experience'
                  : 'Edit experience',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(
                controller: _position,
                label: 'Position',
                required: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Position is required' : null,
              ),
              AppTextField(
                controller: _company,
                label: 'Company',
                required: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Company is required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _start,
                      label: 'Start',
                      hint: 'e.g. 2023',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _end,
                      label: 'End',
                      hint: 'e.g. 2025',
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I currently work here'),
                value: _isCurrent,
                onChanged: (v) => setState(() => _isCurrent = v),
              ),
              AppTextField(
                controller: _description,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
