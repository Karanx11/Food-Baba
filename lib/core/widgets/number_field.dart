import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';

/// Outlined numeric text field with optional range validation.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.hint,
    this.min,
    this.max,
    this.integer = false,
    this.isRequired = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? hint;
  final double? min;
  final double? max;
  final bool integer;
  final bool isRequired;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(integer ? '[0-9]' : '[0-9.]')),
      ],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final raw = (value ?? '').trim();
        if (raw.isEmpty) return isRequired ? 'Required' : null;
        final n = double.tryParse(raw);
        if (n == null) return 'Enter a number';
        final lo = min;
        final hi = max;
        if (lo != null && hi != null && (n < lo || n > hi)) {
          return 'Enter ${compactNumber(lo)}–${compactNumber(hi)}';
        }
        if (lo != null && n < lo) return 'At least ${compactNumber(lo)}';
        if (hi != null && n > hi) return 'At most ${compactNumber(hi)}';
        return null;
      },
    );
  }
}
