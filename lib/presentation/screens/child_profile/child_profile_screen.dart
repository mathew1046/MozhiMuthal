import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/child_profile.dart';
import '../../../core/constants.dart';
import '../../providers/session_provider.dart';

class ChildProfileScreen extends ConsumerStatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  ConsumerState<ChildProfileScreen> createState() =>
      _ChildProfileScreenState();
}

class _ChildProfileScreenState extends ConsumerState<ChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _anganwadiController = TextEditingController();
  int _ageMonths = 24;
  String _districtCode = 'TVM';

  static const _districts = {
    'TVM': 'Thiruvananthapuram',
    'KLM': 'Kollam',
    'PTA': 'Pathanamthitta',
    'ALP': 'Alappuzha',
    'KTM': 'Kottayam',
    'IDK': 'Idukki',
    'EKM': 'Ernakulam',
    'TSR': 'Thrissur',
    'PKD': 'Palakkad',
    'MLP': 'Malappuram',
    'KKD': 'Kozhikode',
    'WYD': 'Wayanad',
    'KNR': 'Kannur',
    'KSD': 'Kasaragod',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _anganwadiController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final profile = ChildProfile(
      childName:
          _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      childAgeMonths: _ageMonths,
      anganwadiId: _anganwadiController.text.trim(),
      districtCode: _districtCode,
    );

    ref.read(sessionProvider.notifier).setChildProfile(profile);
    context.push('/consent');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Child Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name (optional)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Child Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Age in months
              Text('Age (months)', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: _ageMonths > AppConstants.minAgeMonths
                        ? () => setState(() => _ageMonths--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_ageMonths',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: _ageMonths < AppConstants.maxAgeMonths
                        ? () => setState(() => _ageMonths++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Slider(
                value: _ageMonths.toDouble(),
                min: AppConstants.minAgeMonths.toDouble(),
                max: AppConstants.maxAgeMonths.toDouble(),
                divisions:
                    AppConstants.maxAgeMonths - AppConstants.minAgeMonths,
                label: '$_ageMonths months',
                onChanged: (v) => setState(() => _ageMonths = v.round()),
              ),
              const SizedBox(height: 20),

              // Anganwadi ID
              TextFormField(
                controller: _anganwadiController,
                decoration: const InputDecoration(
                  labelText: 'Anganwadi ID',
                  hintText: 'e.g. KL-IDK-042',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // District
              DropdownButtonFormField<String>(
                value: _districtCode,
                decoration: const InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(),
                ),
                items: _districts.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _districtCode = v);
                },
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Consent'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
