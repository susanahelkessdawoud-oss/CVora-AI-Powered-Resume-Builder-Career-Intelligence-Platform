import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/education.dart';
import '../../../models/resume.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/state_views.dart';

/// Step 4 — education entries.
class EducationStep extends StatelessWidget {
  final Resume resume;
  final ValueChanged<Resume> onChanged;

  const EducationStep({
    super.key,
    required this.resume,
    required this.onChanged,
  });

  Future<void> _addOrEdit(BuildContext context, {Education? existing}) async {
    final result = await showModalBottomSheet<Education>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EducationForm(existing: existing),
    );
    if (result == null) return;

    final list = List<Education>.from(resume.educations);
    final index = list.indexWhere((e) => e.id == result.id);
    if (index >= 0) {
      list[index] = result;
    } else {
      list.add(result);
    }
    onChanged(resume.copyWith(educations: list));
  }

  void _delete(Education edu) {
    final list = resume.educations.where((e) => e.id != edu.id).toList();
    onChanged(resume.copyWith(educations: list));
  }

  @override
  Widget build(BuildContext context) {
    final items = resume.educations;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () => _addOrEdit(context),
            icon: const Icon(Icons.add),
            label: const Text('Add education'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyView(
                  icon: Icons.school_outlined,
                  title: 'No education added',
                  message: 'Add your degree, bootcamp or other studies here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final edu = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(edu.degree.isEmpty
                            ? edu.institution
                            : edu.degree),
                        subtitle: Text([edu.institution, edu.yearRange]
                            .where((s) => s.isNotEmpty)
                            .join(' · ')),
                        onTap: () => _addOrEdit(context, existing: edu),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(edu),
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

class _EducationForm extends StatefulWidget {
  final Education? existing;
  const _EducationForm({this.existing});

  @override
  State<_EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends State<_EducationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _institution;
  late final TextEditingController _degree;
  late final TextEditingController _field;
  late final TextEditingController _start;
  late final TextEditingController _end;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _institution = TextEditingController(text: e?.institution ?? '');
    _degree = TextEditingController(text: e?.degree ?? '');
    _field = TextEditingController(text: e?.field ?? '');
    _start = TextEditingController(text: e?.startYear?.toString() ?? '');
    _end = TextEditingController(text: e?.endYear?.toString() ?? '');
  }

  @override
  void dispose() {
    _institution.dispose();
    _degree.dispose();
    _field.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Education(
        id: widget.existing?.id ?? const Uuid().v4(),
        institution: _institution.text.trim(),
        degree: _degree.text.trim(),
        field: _field.text.trim(),
        startYear: int.tryParse(_start.text.trim()),
        endYear: int.tryParse(_end.text.trim()),
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
                  ? 'Add education'
                  : 'Edit education',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(
                controller: _institution,
                label: 'Institution',
                required: true,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Institution is required'
                    : null,
              ),
              AppTextField(
                controller: _degree,
                label: 'Degree',
                required: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Degree is required' : null,
              ),
              AppTextField(
                controller: _field,
                label: 'Field of study',
                hint: 'e.g. Computer Science',
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _start,
                      label: 'Start year',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _end,
                      label: 'End year',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
