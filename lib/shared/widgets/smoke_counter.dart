import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class SmokeCounter extends StatefulWidget {
  const SmokeCounter({super.key});

  @override
  State<SmokeCounter> createState() => _SmokeCounterState();
}

class _SmokeCounterState extends State<SmokeCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Text('Count: $_count'),
        FButton(
          onPress: () => setState(() => _count++),
          suffix: const Icon(FIcons.chevronsUp),
          child: const Text('Increase'),
        ),
      ],
    ),
  );
}
