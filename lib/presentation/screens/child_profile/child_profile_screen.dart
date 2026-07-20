import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../data/models/child_profile.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_ui.dart';

class ChildProfileScreen extends ConsumerStatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  ConsumerState<ChildProfileScreen> createState() => _ChildProfileScreenState();
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
    ref
        .read(sessionProvider.notifier)
        .setChildProfile(
          ChildProfile(
            childName: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
            childAgeMonths: _ageMonths,
            anganwadiId: _anganwadiController.text.trim(),
            districtCode: _districtCode,
          ),
        );
    context.push('/consent');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New screening')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const PageIntro(
                eyebrow: 'Step 1 of 4',
                title: 'A few child details.',
                subtitle:
                    'Only the information needed for this screening is collected.',
              ),
              const SizedBox(height: 24),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Child profile', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Child name',
                        hintText: 'Optional',
                        prefixIcon: Icon(Icons.face_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Age in months', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.56),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Decrease age',
                                onPressed:
                                    _ageMonths > AppConstants.minAgeMonths
                                    ? () => setState(() => _ageMonths--)
                                    : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '$_ageMonths',
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(
                                          color: colors.onPrimaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    'months',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Increase age',
                                onPressed:
                                    _ageMonths < AppConstants.maxAgeMonths
                                    ? () => setState(() => _ageMonths++)
                                    : null,
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                          Slider(
                            value: _ageMonths.toDouble(),
                            min: AppConstants.minAgeMonths.toDouble(),
                            max: AppConstants.maxAgeMonths.toDouble(),
                            divisions:
                                AppConstants.maxAgeMonths -
                                AppConstants.minAgeMonths,
                            label: '$_ageMonths months',
                            onChanged: (value) =>
                                setState(() => _ageMonths = value.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screening location',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _anganwadiController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Anganwadi ID',
                        hintText: 'For example, KL-IDK-042',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter an Anganwadi ID'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _districtCode,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: _districts.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _districtCode = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue to consent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
