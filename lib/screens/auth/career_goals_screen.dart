import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

const _roleOptions = [
  'Data Analyst', 'BI Analyst', 'Software Engineer', 'Frontend Developer',
  'Backend Developer', 'Product Manager', 'UI/UX Designer', 'Marketing',
  'Project Manager', 'QA Engineer',
];

const _industryOptions = [
  'Telecom', 'Fintech', 'E-commerce', 'Healthcare', 'Education',
  'Government', 'Media', 'Consulting',
];

class CareerGoalsScreen extends StatefulWidget {
  const CareerGoalsScreen({super.key});

  @override
  State<CareerGoalsScreen> createState() => _CareerGoalsScreenState();
}

class _CareerGoalsScreenState extends State<CareerGoalsScreen> {
  final title = TextEditingController();
  final Set<String> roles = {};
  final Set<String> industries = {};
  String language = 'English';
  bool saving = false;

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
          'professionalTitle': title.text.trim(),
          'preferredRoles': roles.toList(),
          'preferredIndustries': industries.toList(),
          'preferredLanguage': language,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Non-blocking: career goals are a nice-to-have profile hint, not
        // something that should strand a newly created account.
      }
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _chipGroup(List<String> options, Set<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: isSelected,
          onSelected: (v) => setState(() => v ? selected.add(o) : selected.remove(o)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 1,
                    minHeight: 4,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Step 2 of 2 · Career goals',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What are you aiming for?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'This helps the AI tools tailor advice to you — you can change it anytime in your profile.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 24),
              const Text('Professional title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: title,
                decoration: const InputDecoration(hintText: 'e.g. Junior Data Analyst'),
              ),
              const SizedBox(height: 20),
              const Text('Preferred roles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 10),
              _chipGroup(_roleOptions, roles),
              const SizedBox(height: 20),
              const Text('Preferred industries', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 10),
              _chipGroup(_industryOptions, industries),
              const SizedBox(height: 20),
              const Text('Preferred language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('English'),
                    selected: language == 'English',
                    onSelected: (_) => setState(() => language = 'English'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('العربية'),
                    selected: language == 'Arabic',
                    onSelected: (_) => setState(() => language = 'Arabic'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Finish setup',
                onPressed: _finish,
                isLoading: saving,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
