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
  bool _demoMode = false;
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
    _demoMode = prefs.getBool('demo_mode') ?? false;
    AudioPipelineService.mode = _demoMode
        ? AudioPipelineMode.demo
        : AudioPipelineMode.live;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('worker_name', _nameController.text.trim());
    await prefs.setString(
      'default_anganwadi',
      _anganwadiController.text.trim(),
    );
    await prefs.setBool('demo_mode', _demoMode);
    AudioPipelineService.mode = _demoMode
        ? AudioPipelineMode.demo
        : AudioPipelineMode.live;
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
      context.pop();
    }
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const AppSectionHeader(
              title: 'Your workspace',
              subtitle:
                  'These details are used to prepare each screening session.',
            ),
            const SizedBox(height: 20),
            AppSurface(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Worker name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _anganwadiController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Default Anganwadi ID',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppSurface(
              color: _demoMode
                  ? scheme.secondaryContainer.withValues(alpha: .42)
                  : null,
              borderColor: _demoMode ? scheme.secondaryContainer : null,
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: AppIconBadge(
                  icon: Icons.science_outlined,
                  color: scheme.secondary,
                  size: 42,
                ),
                title: const Text('Demo mode'),
                subtitle: const Text(
                  'Use synthetic data for testing and walkthroughs.',
                ),
                value: _demoMode,
                onChanged: (value) => setState(() => _demoMode = value),
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}
