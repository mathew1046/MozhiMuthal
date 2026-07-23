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
  int _gestationalWeeks = 40;
  String _districtCode = 'TVM';
  late DateTime _birthDate = _birthDateForAge(_ageMonths);

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
            childUuid: ChildProfile.stableUuid(
              childName: _nameController.text,
              birthDate: _birthDate,
              anganwadiId: _anganwadiController.text,
              districtCode: _districtCode,
            ),
            childName: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
            childAgeMonths: _ageMonths,
            birthDate: _birthDate,
            gestationalWeeks: _gestationalWeeks,
            anganwadiId: _anganwadiController.text.trim(),
            districtCode: _districtCode,
          ),
        );
    context.push('/developmental-goals');
  }

  static DateTime _birthDateForAge(int months) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - months, now.day);
  }

  int _ageFromBirthDate(DateTime date) {
    final now = DateTime.now();
    var months = (now.year - date.year) * 12 + now.month - date.month;
    if (now.day < date.day) months--;
    return months.clamp(AppConstants.minAgeMonths, AppConstants.maxAgeMonths);
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: _birthDateForAge(AppConstants.maxAgeMonths),
      lastDate: _birthDateForAge(AppConstants.minAgeMonths),
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _ageMonths = _ageFromBirthDate(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Child details')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const AppStepIndicator(
                current: 1,
                total: 4,
                label: 'Step 1 of 4 • About the child',
              ),
              const SizedBox(height: 20),
              const AppSectionHeader(
                title: 'Let’s start with the basics',
                subtitle:
                    'Use the details shared by the parent. The name is optional.',
              ),
              const SizedBox(height: 22),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconBadge(
                          icon: Icons.child_care_outlined,
                          color: scheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Child profile',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Child name',
                        hintText: 'Optional',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Age', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _RoundIconButton(
                          icon: Icons.remove_rounded,
                          onPressed: _ageMonths > AppConstants.minAgeMonths
                              ? () => setState(() {
                                  _ageMonths--;
                                  _birthDate = _birthDateForAge(_ageMonths);
                                })
                              : null,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$_ageMonths',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              Text(
                                'months old',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _RoundIconButton(
                          icon: Icons.add_rounded,
                          onPressed: _ageMonths < AppConstants.maxAgeMonths
                              ? () => setState(() {
                                  _ageMonths++;
                                  _birthDate = _birthDateForAge(_ageMonths);
                                })
                              : null,
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
                      onChanged: (value) => setState(() {
                        _ageMonths = value.round();
                        _birthDate = _birthDateForAge(_ageMonths);
                      }),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: _pickBirthDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        'Date of birth • ${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Gestational age at birth',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_gestationalWeeks weeks',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Slider(
                      value: _gestationalWeeks.toDouble(),
                      min: 28,
                      max: 42,
                      divisions: 14,
                      label: '$_gestationalWeeks weeks',
                      onChanged: (value) =>
                          setState(() => _gestationalWeeks = value.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screening location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _anganwadiController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Anganwadi ID (optional)',
                        hintText: 'For example, KL-IDK-042',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _districtCode,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: _districts.entries
                          .map(
                            (district) => DropdownMenuItem(
                              value: district.key,
                              child: Text(district.value),
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
                label: const Text('Continue to questions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
    );
  }
}
