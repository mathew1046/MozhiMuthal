import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/audio_pipeline_service.dart';
import '../../widgets/app_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _anganwadiController = TextEditingController();
  bool _demoMode = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('worker_name') ?? '';
    _anganwadiController.text = prefs.getString('default_anganwadi') ?? '';
    _demoMode = prefs.getBool('demo_mode') ?? true;
    AudioPipelineService.useMock = _demoMode;
    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('worker_name', _nameController.text.trim());
    await prefs.setString(
      'default_anganwadi',
      _anganwadiController.text.trim(),
    );
    await prefs.setBool('demo_mode', _demoMode);
    AudioPipelineService.useMock = _demoMode;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    context.pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _anganwadiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const PageIntro(
              eyebrow: 'Workspace',
              title: 'Set up this device.',
              subtitle:
                  'These details help personalise the local screening workspace.',
            ),
            const SizedBox(height: 24),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Worker details', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Worker name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _anganwadiController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Default Anganwadi ID',
                      prefixIcon: Icon(Icons.home_work_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              color: colors.primaryContainer.withValues(alpha: 0.48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoundIcon(
                    icon: Icons.science_outlined,
                    color: colors.primary,
                    iconColor: colors.onPrimary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Demo mode', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Use synthetic screening data for safe demonstrations.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _demoMode,
                    onChanged: (value) => setState(() => _demoMode = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}
