import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cv_components.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('userProfiles').doc(uid).get();
      if (mounted) setState(() {
        _profile = doc.data();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveField(String key, dynamic value) async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _load();
  }

  int get _completionPct {
    var filled = 0;
    const total = 5;
    final p = _profile;
    final user = AuthService.instance.currentUser;
    if ((user?.displayName ?? '').trim().isNotEmpty) filled++;
    if (p?['professionalTitle'] != null && (p!['professionalTitle'] as String).isNotEmpty) filled++;
    if (p?['preferredRoles'] != null && (p!['preferredRoles'] as List).isNotEmpty) filled++;
    if (p?['links'] != null) filled++;
    if (p?['languages'] != null) filled++;
    return ((filled / total) * 100).round();
  }

  List<String> get _missing {
    final p = _profile;
    final missing = <String>[];
    if (p?['links'] == null) missing.add('LinkedIn');
    if (p?['preferredIndustries'] == null || (p?['preferredIndustries'] as List? ?? []).isEmpty) missing.add('preferred industries');
    return missing;
  }

  Future<void> _editDisplayName(String current) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    try {
      await AuthService.instance.updateProfile(displayName: value);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update name: $e')));
      }
    }
  }

  Future<void> _addIndustry() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add an industry'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Fintech')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    final current = List<String>.from(_profile?['preferredIndustries'] as List? ?? []);
    if (!current.contains(value)) current.add(value);
    await _saveField('preferredIndustries', current);
  }

  Future<void> _editLanguages(List<String> current) async {
    final controller = TextEditingController(text: current.join(', '));
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Languages'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Arabic, English')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (value == null) return;
    final list = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    await _saveField('languages', list);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName! : (user?.email?.split('@').first ?? 'Your profile');
    final initials = displayName.isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';
    final title = _profile?['professionalTitle'] as String? ?? '';
    final roles = List<String>.from(_profile?['preferredRoles'] as List? ?? []);
    final industries = List<String>.from(_profile?['preferredIndustries'] as List? ?? []);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      ),
                      CvAppBarAction(icon: Icons.edit_outlined, onTap: () => _editDisplayName(displayName)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
                        child: Text(initials, style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                            Text(
                              title.isEmpty ? (user?.email ?? '') : title,
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CvCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MetricBar(label: 'Profile completion', value: _completionPct, color: AppTheme.warningColor),
                        if (_missing.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Missing: ${_missing.join(', ')}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Career goals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  CvCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preferred roles', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final r in roles) StatusChip(label: r, tone: ChipTone.blue),
                            if (roles.isEmpty)
                              Text('None set', style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall?.color)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('Industries', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final i in industries) StatusChip(label: i, tone: ChipTone.purple),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 16),
                              label: const Text('Add'),
                              onPressed: _addIndustry,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _row(context, Icons.work_outline, 'Experience & education', 'Edit in the CV builder', () => Navigator.pushNamed(context, '/my-resumes')),
                  const SizedBox(height: 10),
                  _row(context, Icons.link, 'Links', _linksSubtitle(), () => _editLinks()),
                  const SizedBox(height: 10),
                  _row(context, Icons.language, 'Languages', _languagesSubtitle(), () => _editLanguages(_languagesList())),
                  const SizedBox(height: 10),
                  _row(context, Icons.settings_outlined, 'Settings', 'Account, AI, privacy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ],
              ),
      ),
      bottomNavigationBar: const CvBottomNav(currentIndex: 4),
    );
  }

  List<String> _languagesList() => List<String>.from(_profile?['languages'] as List? ?? []);

  String _languagesSubtitle() {
    final list = _languagesList();
    return list.isEmpty ? 'Add the languages you speak' : list.join(' · ');
  }

  String _linksSubtitle() {
    final links = _profile?['links'] as Map<String, dynamic>?;
    if (links == null || links.isEmpty) return 'Add LinkedIn, GitHub, portfolio';
    return links.values.join(' · ');
  }

  Future<void> _editLinks() async {
    final controller = TextEditingController(text: _linksSubtitle() == 'Add LinkedIn, GitHub, portfolio' ? '' : _linksSubtitle());
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Links'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'linkedin.com/in/you')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (value != null) await _saveField('links', {'linkedin': value});
  }

  Widget _row(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return CvCard(
      onTap: onTap,
      child: Row(
        children: [
          IconTile(icon: icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
