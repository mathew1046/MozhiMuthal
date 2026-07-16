import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../services/audio_pipeline_service.dart';

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
    AudioPipelineService.mode = _demoMode ? AudioPipelineMode.demo : AudioPipelineMode.live;
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('worker_name', _nameController.text.trim());
    await prefs.setString(
        'default_anganwadi', _anganwadiController.text.trim());
    await prefs.setBool('demo_mode', _demoMode);
    AudioPipelineService.mode = _demoMode ? AudioPipelineMode.demo : AudioPipelineMode.live;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Worker Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _anganwadiController,
            decoration: const InputDecoration(
              labelText: 'Default Anganwadi ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Demo Mode'),
            subtitle: const Text('Use synthetic data for testing'),
            value: _demoMode,
            onChanged: (v) => setState(() => _demoMode = v),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
