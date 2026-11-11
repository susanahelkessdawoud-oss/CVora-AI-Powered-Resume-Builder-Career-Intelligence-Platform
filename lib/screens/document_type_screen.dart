import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'builder/resume_builder_screen.dart';

/// The "What would you like to build?" screen — lets the user choose between
/// a CV and a Resume before entering the builder, explaining the difference.
class DocumentTypeScreen extends StatefulWidget {
  const DocumentTypeScreen({super.key});

  @override
  State<DocumentTypeScreen> createState() => _DocumentTypeScreenState();
}

class _DocumentTypeScreenState extends State<DocumentTypeScreen> {
  DocType _selected = DocType.resume;

  void _continue() {
    final uid = AuthService().currentUser?.uid ?? 'unknown';
    final doc = Resume.create(uid, docType: _selected);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResumeBuilderScreen(existing: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header band
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brand, AppColors.brandBright],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                        ),
                        const Text('CVORA',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Build. Refine. Get Hired.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                      'Organize your experience  ·  Refine your CV  ·  '
                      'Achieve your career goals',
                      style: TextStyle(color: Color(0xFFD7DDFF), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What would you like to build?',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text("Not sure which one you need? Here's the difference.",
                        style: TextStyle(color: muted)),
                    const SizedBox(height: 20),
                    _DocCard(
                      selected: _selected == DocType.cv,
                      onTap: () => setState(() => _selected = DocType.cv),
                      icon: Icons.menu_book_rounded,
                      title: 'Create a CV',
                      subtitle: 'Your complete professional & academic profile',
                      rows: const [
                        ['Length', 'Usually longer (2+ pages)'],
                        ['Content', 'Detailed career & academic history'],
                        ['Focus', 'A complete professional profile'],
                        ['Common for', 'Academia, research, government'],
                      ],
                      quote:
                          '"Here is my complete professional and academic '
                          'history."',
                    ),
                    const SizedBox(height: 14),
                    _DocCard(
                      selected: _selected == DocType.resume,
                      onTap: () => setState(() => _selected = DocType.resume),
                      icon: Icons.description_rounded,
                      title: 'Create a Resume',
                      subtitle:
                          'A short, job-targeted version of your experience',
                      rows: const [
                        ['Length', 'Usually 1–2 pages'],
                        ['Content', 'Relevant experience only'],
                        ['Focus', 'Targeted to a specific job'],
                        ['Common for', 'Job applications (US / Canada)'],
                      ],
                      quote:
                          '"Here are the experiences and skills that make me '
                          'suitable for THIS job."',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x1AF59E0B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'In many countries "CV" means either document — '
                              'you can switch formats later from settings.',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Your journey',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const _JourneyRow(),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _continue,
                      child: Text('Continue with ${_selected.label}'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<List<String>> rows;
  final String quote;

  const _DocCard({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.brand : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: TextStyle(color: muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.brand : muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(r[0],
                            style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5)),
                      ),
                      Expanded(
                        child: Text(r[1],
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(quote,
                  style: TextStyle(
                      color: muted,
                      fontStyle: FontStyle.italic,
                      fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow();

  @override
  Widget build(BuildContext context) {
    const steps = [
      [Icons.grid_view_rounded, 'Choose\nTemplate'],
      [Icons.edit_note_rounded, 'Add\nInformation'],
      [Icons.auto_awesome_rounded, 'ATS\nOptimize'],
      [Icons.picture_as_pdf_rounded, 'Export\nPDF'],
    ];
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(steps[i][0] as IconData,
                    color: AppColors.brand, size: 22),
              ),
              const SizedBox(height: 6),
              Text(steps[i][1] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 11)),
            ],
          ),
          if (i < steps.length - 1)
            Icon(Icons.chevron_right, color: muted),
        ],
      ],
    );
  }
}
