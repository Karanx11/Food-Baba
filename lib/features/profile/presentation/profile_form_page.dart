import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/widgets/number_field.dart';
import '../application/profile_providers.dart';
import '../domain/nutrition_targets.dart';
import '../domain/user_profile.dart';
import 'targets_card.dart';

/// Create or edit the profile. Targets preview live as the inputs change.
class ProfileFormPage extends ConsumerStatefulWidget {
  const ProfileFormPage({super.key, this.initial});

  /// Existing profile to edit, or null to set one up.
  final UserProfile? initial;

  static Route<void> route({UserProfile? initial}) =>
      MaterialPageRoute<void>(builder: (_) => ProfileFormPage(initial: initial));

  @override
  ConsumerState<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends ConsumerState<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _age = TextEditingController(
    text: widget.initial?.age.toString() ?? '',
  );
  late final _height = TextEditingController(
    text: _initialNumber(widget.initial?.heightCm),
  );
  late final _weight = TextEditingController(
    text: _initialNumber(widget.initial?.weightKg),
  );
  late Sex _sex = widget.initial?.sex ?? Sex.male;
  late ActivityLevel _activity =
      widget.initial?.activity ?? ActivityLevel.moderate;
  late Goal _goal = widget.initial?.goal ?? Goal.maintain;
  bool _saving = false;

  static String _initialNumber(double? value) =>
      value == null ? '' : compactNumber(value);

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  /// The profile described by the current inputs, or null while invalid.
  UserProfile? _draft() {
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    if (age == null || height == null || weight == null) return null;
    if (age < ProfileLimits.minAge || age > ProfileLimits.maxAge) return null;
    if (height < ProfileLimits.minHeightCm ||
        height > ProfileLimits.maxHeightCm) {
      return null;
    }
    if (weight < ProfileLimits.minWeightKg ||
        weight > ProfileLimits.maxWeightKg) {
      return null;
    }
    return UserProfile(
      name: _name.text.trim(),
      sex: _sex,
      age: age,
      heightCm: height,
      weightKg: weight,
      activity: _activity,
      goal: _goal,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft();
    if (draft == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(draft);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final draft = _draft();
    final targets = draft == null ? null : TargetsCalculator.compute(draft);
    final isNew = widget.initial == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Set up your profile' : 'Edit profile'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle('About you'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Sex>(
                segments: [
                  for (final sex in Sex.values)
                    ButtonSegment(value: sex, label: Text(sex.label)),
                ],
                selected: {_sex},
                onSelectionChanged: (s) => setState(() => _sex = s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: NumberField(
                      controller: _age,
                      label: 'Age',
                      suffix: 'years',
                      min: ProfileLimits.minAge.toDouble(),
                      max: ProfileLimits.maxAge.toDouble(),
                      integer: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NumberField(
                      controller: _height,
                      label: 'Height',
                      suffix: 'cm',
                      min: ProfileLimits.minHeightCm,
                      max: ProfileLimits.maxHeightCm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _weight,
                label: 'Weight',
                suffix: 'kg',
                min: ProfileLimits.minWeightKg,
                max: ProfileLimits.maxWeightKg,
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Activity level'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final level in ActivityLevel.values)
                      ListTile(
                        title: Text(level.label),
                        subtitle: Text(level.description),
                        selected: level == _activity,
                        trailing: Icon(
                          level == _activity
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: level == _activity
                              ? scheme.primary
                              : scheme.outline,
                        ),
                        onTap: () => setState(() => _activity = level),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Goal'),
              SegmentedButton<Goal>(
                segments: const [
                  ButtonSegment(
                    value: Goal.lose,
                    label: Text('Lose'),
                    icon: Icon(Icons.trending_down_rounded),
                  ),
                  ButtonSegment(
                    value: Goal.maintain,
                    label: Text('Maintain'),
                    icon: Icon(Icons.trending_flat_rounded),
                  ),
                  ButtonSegment(
                    value: Goal.gain,
                    label: Text('Gain'),
                    icon: Icon(Icons.trending_up_rounded),
                  ),
                ],
                selected: {_goal},
                onSelectionChanged: (g) => setState(() => _goal = g.first),
              ),
              const SizedBox(height: 8),
              Text(
                _goal.description,
                style: text.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 24),
              if (targets != null)
                TargetsCard(targets: targets, title: 'Your targets')
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: scheme.outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Fill in age, height and weight to preview '
                            'your targets.',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
