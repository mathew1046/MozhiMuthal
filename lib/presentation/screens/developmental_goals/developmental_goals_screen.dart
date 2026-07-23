import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/cdc_developmental_goals.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_ui.dart';

class DevelopmentalGoalsScreen extends ConsumerStatefulWidget {
  const DevelopmentalGoalsScreen({super.key});

  @override
  ConsumerState<DevelopmentalGoalsScreen> createState() =>
      _DevelopmentalGoalsScreenState();
}

class _DevelopmentalGoalsScreenState
    extends ConsumerState<DevelopmentalGoalsScreen> {
  final Set<String> _checkedGoals = {};

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider).childProfile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Child details are required first.')),
      );
    }
    final group = CdcDevelopmentalGoals.forAge(profile.childAgeMonths);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Developmental goals')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppStepIndicator(
                current: 2,
                total: 4,
                label: 'Step 2 of 4 • Developmental goals',
              ),
              const SizedBox(height: 18),
              AppSurface(
                color: scheme.secondaryContainer.withValues(alpha: .34),
                borderColor: scheme.secondaryContainer,
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIconBadge(
                      icon: Icons.flag_outlined,
                      color: scheme.secondary,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goals for ${group.label}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Review the ${group.goalCount} goals the CDC lists for this age. Tick goals the child usually does.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_checkedGoals.length} of ${group.goalCount} goals ticked',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final category in group.categories.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                          category.key,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      AppSurface(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            for (final goal in category.value)
                              CheckboxListTile(
                                value: _checkedGoals.contains(goal),
                                onChanged: (checked) => setState(() {
                                  if (checked ?? false) {
                                    _checkedGoals.add(goal);
                                  } else {
                                    _checkedGoals.remove(goal);
                                  }
                                }),
                                title: Text(
                                  goal,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppSurface(
                      color: scheme.tertiaryContainer.withValues(alpha: .28),
                      borderColor: scheme.tertiaryContainer,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'This is developmental monitoring, not a diagnosis or a validated screening tool. If a child has not reached one or more goals, has lost a skill, or you are concerned, discuss it with a doctor.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(CdcDevelopmentalGoals.sourceUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('View CDC milestone source'),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.push('/questionnaire'),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue to parent questionnaire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
