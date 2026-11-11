import 'package:flutter/material.dart';

import '../../../models/resume.dart';
import '../../../utils/validators.dart';
import '../../../widgets/app_text_field.dart';

/// Step 1 — contact details and professional summary.
///
/// Controllers are seeded once in [initState] so the fields keep their text
/// and cursor position when the parent rebuilds (e.g. when the live score
/// updates). Every change reports a new Resume up to the builder.
class PersonalInfoStep extends StatefulWidget {
  final Resume resume;
  final ValueChanged<Resume> onChanged;

  const PersonalInfoStep({
    super.key,
    required this.resume,
    required this.onChanged,
  });

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _summary;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.resume.fullName);
    _title = TextEditingController(text: widget.resume.jobTitle);
    _email = TextEditingController(text: widget.resume.email);
    _phone = TextEditingController(text: widget.resume.phone);
    _location = TextEditingController(text: widget.resume.location);
    _summary = TextEditingController(text: widget.resume.summary);
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.resume.copyWith(
        fullName: _name.text,
        jobTitle: _title.text,
        email: _email.text,
        phone: _phone.text,
        location: _location.text,
        summary: _summary.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(
            controller: _name,
            label: 'Full name',
            required: true,
            validator: (v) => Validators.required(v, 'Full name'),
            onChanged: (_) => _emit(),
          ),
          AppTextField(
            controller: _title,
            label: 'Professional title',
            hint: 'e.g. Flutter Developer',
            onChanged: (_) => _emit(),
          ),
          AppTextField(
            controller: _email,
            label: 'Email',
            required: true,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            onChanged: (_) => _emit(),
          ),
          AppTextField(
            controller: _phone,
            label: 'Phone',
            keyboardType: TextInputType.phone,
            onChanged: (_) => _emit(),
          ),
          AppTextField(
            controller: _location,
            label: 'Location',
            hint: 'City, Country',
            onChanged: (_) => _emit(),
          ),
          AppTextField(
            controller: _summary,
            label: 'Professional summary',
            hint: 'A few sentences about who you are and what you do.',
            maxLines: 4,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}
