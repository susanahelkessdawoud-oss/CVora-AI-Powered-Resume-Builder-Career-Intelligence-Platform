import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'resume_builder_screen.dart';

/// First step of the creation flow.
///
/// Lets the user decide whether they want a full **CV** (a complete
/// professional / academic history) or a short, job-targeted **Resume**,
/// then previews the rest of the journey:
/// Choose Template -> Add Information -> AI/ATS Optimization -> Export PDF.
class DocumentTypeScreen extends StatefulWidget {
  const DocumentTypeScreen({super.key});

  @override
  State<DocumentTypeScreen> createState() => _DocumentTypeScreenState();
}

class _DocumentTypeScreenState extends State<DocumentTypeScreen> {
  // 'cv' or 'resume'
  String selected = 'resume';

  static const Map<String, Map<String, dynamic>> _options = {
    'cv': {
      'title': 'Create a CV',
      'tagline': 'Your complete professional & academic profile',
      'icon': Icons.menu_book_outlined,
      'length': 'Usually longer (2+ pages)',
      'content': 'Detailed career & academic history',
      'focus': 'A complete professional profile',
      'bestFor': 'Academia, research, government & many countries',
      'quote': '"Here is my complete professional and academic history."',
    },
    'resume': {
      'title': 'Create a Resume',
      'tagline': 'A short, job-targeted version of your experience',
      'icon': Icons.description_outlined,
      'length': 'Usually 1-2 pages',
      'content': 'Relevant experience only',
      'focus': 'Targeted to a specific job',
      'bestFor': 'Job applications, especially US / Canada',
      'quote':
          '"Here are the experiences and skills that make me suitable for THIS job."',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What would you like to build?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Not sure which one you need? Here\'s the difference.',
                      style: TextStyle(fontSize: 13, color: AppTheme.grey),
                    ),
                    const SizedBox(height: 18),

                    _optionCard('cv'),
                    const SizedBox(height: 14),
                    _optionCard('resume'),

                    const SizedBox(height: 18),
                    _infoBanner(),

                    const SizedBox(height: 30),
                    const Text(
                      'Your journey',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here\'s what happens next.',
                      style: TextStyle(fontSize: 13, color: AppTheme.grey),
                    ),
                    const SizedBox(height: 16),
                    _flowPreview(),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ResumeBuilderScreen(documentType: selected),
                            ),
                          );
                        },
                        child: Text(
                          selected == 'cv'
                              ? 'Continue with CV'
                              : 'Continue with Resume',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(gradient: AppTheme.navyGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 4),
              const Text(
                'CVORA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Build. Refine. Get Hired.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Organize your experience  ·  Refine your CV  ·  Achieve your career goals',
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(String key) {
    final option = _options[key]!;
    final isSelected = selected == key;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      onTap: () => setState(() => selected = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.navy.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.navy : Colors.black12,
            width: isSelected ? 2 : 1,
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
                    color: AppTheme.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(option['icon'] as IconData, color: AppTheme.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option['tagline'] as String,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.grey),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.navy : Colors.black26,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _detailRow('Length', option['length'] as String),
            _detailRow('Content', option['content'] as String),
            _detailRow('Focus', option['focus'] as String),
            _detailRow('Common for', option['bestFor'] as String),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                option['quote'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppTheme.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Not sure which term applies to you? In many countries "CV" is used '
              'to mean either document, so CVora supports both — you can switch '
              'formats later from your document\'s settings.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowPreview() {
    final steps = [
      {'icon': Icons.dashboard_customize_outlined, 'label': 'Choose\nTemplate'},
      {'icon': Icons.edit_note_outlined, 'label': 'Add\nInformation'},
      {'icon': Icons.auto_awesome_outlined, 'label': 'AI / ATS\nOptimize'},
      {'icon': Icons.picture_as_pdf_outlined, 'label': 'Export\nPDF'},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return const Expanded(
            child: Icon(Icons.chevron_right, color: Colors.black26),
          );
        }
        final step = steps[i ~/ 2];
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.navy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(step['icon'] as IconData, color: AppTheme.navy, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              step['label'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }),
    );
  }
}
