import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class ResumeBuilderScreen extends StatefulWidget {
  final Resume? existing;
  final String documentType; // 'cv' or 'resume'

  const ResumeBuilderScreen({
    super.key,
    this.existing,
    this.documentType = 'resume',
  });

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  late PageController _pageController;
  int currentPage = 0;
  bool saving = false;

  final List<String> pages = [
    'Personal Info',
    'Summary',
    'Education',
    'Experience',
    'Skills',
    'Projects',
    'Achievements',
    'Certifications',
    'Style',
    'Template',
  ];

  // Personal info
  late final TextEditingController fullNameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController titleCtrl;

  // Summary
  late final TextEditingController summaryCtrl;

  // Education (single entry, matches the original single-item form)
  late final TextEditingController schoolCtrl;
  late final TextEditingController degreeCtrl;
  late final TextEditingController fieldOfStudyCtrl;

  // Experience
  late final TextEditingController jobTitleCtrl;
  late final TextEditingController companyCtrl;
  late final TextEditingController experienceDescCtrl;

  // Skills
  final List<String> skills = [];
  late final TextEditingController skillCtrl;

  // Projects
  late final TextEditingController projectNameCtrl;
  late final TextEditingController projectDescCtrl;
  late final TextEditingController projectLinkCtrl;

  // Achievements
  late final TextEditingController achievementCtrl;

  // Certifications
  late final TextEditingController certNameCtrl;
  late final TextEditingController certIssuerCtrl;
  late final TextEditingController certDateCtrl;

  String resumeStyle = 'modern';
  String template = 'template1';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    final r = widget.existing;
    fullNameCtrl = TextEditingController(text: r?.fullName ?? '');
    emailCtrl = TextEditingController(text: r?.email ?? '');
    phoneCtrl = TextEditingController(text: r?.phone ?? '');
    locationCtrl = TextEditingController(text: r?.location ?? '');
    titleCtrl = TextEditingController(text: r?.professionalTitle ?? '');
    summaryCtrl = TextEditingController(text: r?.professionalSummary ?? '');

    final edu = r?.education.isNotEmpty == true ? r!.education.first : null;
    schoolCtrl = TextEditingController(text: edu?.school ?? '');
    degreeCtrl = TextEditingController(text: edu?.degree ?? '');
    fieldOfStudyCtrl = TextEditingController(text: edu?.fieldOfStudy ?? '');

    final exp = r?.experience.isNotEmpty == true ? r!.experience.first : null;
    jobTitleCtrl = TextEditingController(text: exp?.jobTitle ?? '');
    companyCtrl = TextEditingController(text: exp?.company ?? '');
    experienceDescCtrl = TextEditingController(text: exp?.description ?? '');

    skills.addAll(r?.skills ?? []);
    skillCtrl = TextEditingController();

    final proj = r?.projects.isNotEmpty == true ? r!.projects.first : null;
    projectNameCtrl = TextEditingController(text: proj?.name ?? '');
    projectDescCtrl = TextEditingController(text: proj?.description ?? '');
    projectLinkCtrl = TextEditingController(text: proj?.link ?? '');

    final achievement = r?.achievements.isNotEmpty == true
        ? r!.achievements.first
        : null;
    achievementCtrl = TextEditingController(text: achievement?.title ?? '');

    final cert = r?.certifications.isNotEmpty == true
        ? r!.certifications.first
        : null;
    certNameCtrl = TextEditingController(text: cert?.name ?? '');
    certIssuerCtrl = TextEditingController(text: cert?.issuedBy ?? '');
    certDateCtrl = TextEditingController(text: cert?.issueDate ?? '');

    resumeStyle = r?.resumeType ?? 'modern';
    template = r?.template ?? 'template1';
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      fullNameCtrl,
      emailCtrl,
      phoneCtrl,
      locationCtrl,
      titleCtrl,
      summaryCtrl,
      schoolCtrl,
      degreeCtrl,
      fieldOfStudyCtrl,
      jobTitleCtrl,
      companyCtrl,
      experienceDescCtrl,
      skillCtrl,
      projectNameCtrl,
      projectDescCtrl,
      projectLinkCtrl,
      achievementCtrl,
      certNameCtrl,
      certIssuerCtrl,
      certDateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _addSkill() {
    final value = skillCtrl.text.trim();
    if (value.isEmpty || skills.contains(value)) return;
    setState(() {
      skills.add(value);
      skillCtrl.clear();
    });
  }

  Resume _buildResume() {
    final now = DateTime.now();
    final userId = AuthService.instance.currentUser?.id ?? '';

    return Resume(
      id: widget.existing?.id ?? '',
      userId: userId,
      fullName: fullNameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      professionalTitle: titleCtrl.text.trim(),
      professionalSummary: summaryCtrl.text.trim(),
      documentType: widget.documentType,
      resumeType: resumeStyle,
      template: template,
      education: schoolCtrl.text.trim().isEmpty
          ? []
          : [
              Education(
                id: widget.existing?.education.isNotEmpty == true
                    ? widget.existing!.education.first.id
                    : '',
                school: schoolCtrl.text.trim(),
                degree: degreeCtrl.text.trim(),
                fieldOfStudy: fieldOfStudyCtrl.text.trim(),
                startDate: '',
                endDate: '',
                description: '',
              ),
            ],
      experience: jobTitleCtrl.text.trim().isEmpty
          ? []
          : [
              Experience(
                id: widget.existing?.experience.isNotEmpty == true
                    ? widget.existing!.experience.first.id
                    : '',
                jobTitle: jobTitleCtrl.text.trim(),
                company: companyCtrl.text.trim(),
                startDate: '',
                endDate: '',
                description: experienceDescCtrl.text.trim(),
                isCurrentJob: false,
              ),
            ],
      skills: List<String>.from(skills),
      projects: projectNameCtrl.text.trim().isEmpty
          ? []
          : [
              Project(
                id: widget.existing?.projects.isNotEmpty == true
                    ? widget.existing!.projects.first.id
                    : '',
                name: projectNameCtrl.text.trim(),
                description: projectDescCtrl.text.trim(),
                link: projectLinkCtrl.text.trim(),
                technologies: '',
                startDate: '',
                endDate: '',
              ),
            ],
      achievements: achievementCtrl.text.trim().isEmpty
          ? []
          : [
              Achievement(
                id: widget.existing?.achievements.isNotEmpty == true
                    ? widget.existing!.achievements.first.id
                    : '',
                title: achievementCtrl.text.trim(),
                description: '',
                date: '',
              ),
            ],
      certifications: certNameCtrl.text.trim().isEmpty
          ? []
          : [
              Certification(
                id: widget.existing?.certifications.isNotEmpty == true
                    ? widget.existing!.certifications.first.id
                    : '',
                name: certNameCtrl.text.trim(),
                issuedBy: certIssuerCtrl.text.trim(),
                issueDate: certDateCtrl.text.trim(),
                expiryDate: '',
                link: '',
              ),
            ],
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _complete() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to save your resume.'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            ),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final resume = _buildResume();
      if (widget.existing == null) {
        await DatabaseService.instance.createResume(resume);
      } else {
        await DatabaseService.instance.updateResume(
          widget.existing!.id,
          resume,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showSaveError(e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showSaveError(Object error) {
    final message = error.toString();
    final isMissingTable = message.contains('Could not find the table');

    if (!isMissingTable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database not set up yet'),
        content: const Text(
          'Your Supabase project is missing the "resumes" table. Open the '
          'Supabase SQL Editor for your project and run the script from '
          'supabase/schema.sql in this repo, then try saving again.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentLabel = widget.documentType == 'cv' ? 'CV' : 'Resume';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${pages[currentPage]} · $documentLabel',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentPage + 1) / pages.length,
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              children: [
                _personalInfoPage(),
                _summaryPage(),
                _educationPage(),
                _experiencePage(),
                _skillsPage(),
                _projectsPage(),
                _achievementsPage(),
                _certificationsPage(),
                _stylePage(),
                _templatePage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : _previousPage,
                      child: const Text('Previous'),
                    ),
                  ),
                if (currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: saving ? null : _nextPage,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            currentPage == pages.length - 1
                                ? 'Complete'
                                : 'Next',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: fullNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Professional Title',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: summaryCtrl,
        maxLines: 10,
        decoration: const InputDecoration(
          labelText: 'Professional Summary',
          hintText: 'Enter your professional summary...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _educationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: schoolCtrl,
            decoration: const InputDecoration(
              labelText: 'School/University',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: degreeCtrl,
            decoration: const InputDecoration(
              labelText: 'Degree',
              prefixIcon: Icon(Icons.card_membership),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: fieldOfStudyCtrl,
            decoration: const InputDecoration(
              labelText: 'Field of Study',
              prefixIcon: Icon(Icons.subject_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _experiencePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: jobTitleCtrl,
            decoration: const InputDecoration(
              labelText: 'Job Title',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: companyCtrl,
            decoration: const InputDecoration(
              labelText: 'Company',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: experienceDescCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your responsibilities...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: skillCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Skill',
                    prefixIcon: Icon(Icons.star_outline),
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addSkill,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      onDeleted: () => setState(() => skills.remove(skill)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: projectNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: projectDescCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your project...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: projectLinkCtrl,
            decoration: const InputDecoration(
              labelText: 'Project Link (Optional)',
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: achievementCtrl,
            decoration: const InputDecoration(
              labelText: 'Achievement',
              prefixIcon: Icon(Icons.emoji_events_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _certificationsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: certNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Certification Name',
              prefixIcon: Icon(Icons.verified_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: certIssuerCtrl,
            decoration: const InputDecoration(
              labelText: 'Issued By',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: certDateCtrl,
            decoration: const InputDecoration(
              labelText: 'Issue Date',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stylePage() {
    final styles = [
      {
        'value': 'modern',
        'name': 'Modern',
        'desc': 'Clean and contemporary design',
      },
      {
        'value': 'professional',
        'name': 'Professional',
        'desc': 'Traditional and formal layout',
      },
      {
        'value': 'creative',
        'name': 'Creative',
        'desc': 'Colorful and artistic design',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: styles
            .map(
              (s) => _pickerCard(
                thumbnail: _StyleThumbnail(style: s['value']!),
                title: s['name']!,
                subtitle: s['desc']!,
                selected: resumeStyle == s['value'],
                onTap: () => setState(() => resumeStyle = s['value']!),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _templatePage() {
    final templates = [
      {
        'value': 'template1',
        'name': 'Template 1',
        'desc': 'Classic single column layout',
      },
      {
        'value': 'template2',
        'name': 'Template 2',
        'desc': 'Two column sidebar layout',
      },
      {
        'value': 'template3',
        'name': 'Template 3',
        'desc': 'Modern card-based layout',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: templates
            .map(
              (t) => _pickerCard(
                thumbnail: _TemplateThumbnail(template: t['value']!),
                title: t['name']!,
                subtitle: t['desc']!,
                selected: template == t['value'],
                onTap: () => setState(() => template = t['value']!),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _pickerCard({
    required Widget thumbnail,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.purple.withValues(alpha: 0.06)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: selected ? AppTheme.purple : Colors.black12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              thumbnail,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.grey),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppTheme.purple : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small mock resume "picture" so users can see what a visual style
/// looks like without needing real design assets.
class _StyleThumbnail extends StatelessWidget {
  final String style;

  const _StyleThumbnail({required this.style});

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case 'professional':
        return _frame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 14, color: const Color(0xFF2D3748)),
              const SizedBox(height: 6),
              _bar(width: 34, height: 4, color: const Color(0xFF2D3748)),
              const SizedBox(height: 4),
              _bar(width: 44, height: 3),
              const SizedBox(height: 3),
              _bar(width: 40, height: 3),
              const SizedBox(height: 3),
              _bar(width: 30, height: 3),
            ],
          ),
        );
      case 'creative':
        return _frame(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 14,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.purple, AppTheme.blue],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 34, height: 4, color: AppTheme.purple),
                    const SizedBox(height: 5),
                    _bar(width: double.infinity, height: 3),
                    const SizedBox(height: 3),
                    _bar(width: 30, height: 3),
                    const SizedBox(height: 3),
                    _bar(width: 36, height: 3),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'modern':
      default:
        return _frame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppTheme.purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _bar(width: 30, height: 4, color: AppTheme.purple),
                ],
              ),
              const SizedBox(height: 8),
              _bar(width: double.infinity, height: 3),
              const SizedBox(height: 3),
              _bar(width: 40, height: 3),
              const SizedBox(height: 3),
              _bar(width: 36, height: 3),
            ],
          ),
        );
    }
  }

  Widget _frame({required Widget child}) {
    return Container(
      width: 64,
      height: 84,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }

  Widget _bar({required double width, required double height, Color? color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// A small mock layout "picture" previewing each template's structure.
class _TemplateThumbnail extends StatelessWidget {
  final String template;

  const _TemplateThumbnail({required this.template});

  @override
  Widget build(BuildContext context) {
    switch (template) {
      case 'template2':
        return _frame(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 18,
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _bar(width: 10, height: 2, color: Colors.white70),
                    const SizedBox(height: 3),
                    _bar(width: 10, height: 2, color: Colors.white70),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 32, height: 4, color: AppTheme.purple),
                    const SizedBox(height: 6),
                    _bar(width: double.infinity, height: 3),
                    const SizedBox(height: 3),
                    _bar(width: 26, height: 3),
                    const SizedBox(height: 3),
                    _bar(width: 30, height: 3),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'template3':
        return _frame(
          child: Column(
            children: [
              _bar(width: double.infinity, height: 6, color: AppTheme.purple),
              const SizedBox(height: 6),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    4,
                    (_) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'template1':
      default:
        return _frame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(width: 36, height: 5, color: AppTheme.purple),
              const SizedBox(height: 8),
              _bar(width: double.infinity, height: 3),
              const SizedBox(height: 3),
              _bar(width: double.infinity, height: 3),
              const SizedBox(height: 3),
              _bar(width: 40, height: 3),
              const SizedBox(height: 8),
              _bar(width: double.infinity, height: 3),
              const SizedBox(height: 3),
              _bar(width: 30, height: 3),
            ],
          ),
        );
    }
  }

  Widget _frame({required Widget child}) {
    return Container(
      width: 64,
      height: 84,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }

  Widget _bar({required double width, required double height, Color? color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
