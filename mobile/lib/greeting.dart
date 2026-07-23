import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart';

String greetingSalutation([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

const _motivationalLines = [
  "Let's make today count.",
  'Small steps, big progress.',
  'Your streak is waiting.',
  'One good day at a time.',
  'Show up for yourself today.',
  'Progress, not perfection.',
  "You've got this.",
];

int _dayOfYear(DateTime d) => d.difference(DateTime(d.year)).inDays;

/// Deterministic per-day pick so the line doesn't flicker on every rebuild —
/// it only changes when the calendar day changes.
String motivationalLine([DateTime? now]) {
  final date = now ?? DateTime.now();
  return _motivationalLines[_dayOfYear(date) % _motivationalLines.length];
}

/// Shown at the top of the Daily page. Tapping it reopens the name dialog.
class GreetingHeader extends StatelessWidget {
  final AppState appState;
  const GreetingHeader({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final name = appState.userName;
    final salutation = greetingSalutation();
    return GestureDetector(
      onTap: () => promptForName(context, appState),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? '$salutation!' : '$salutation, $name!',
              style: const TextStyle(color: AppColors.slate100, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(motivationalLine(), style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Asks for a name. Required — no skip/cancel — used both for the first-run
/// prompt and for editing the name later via [GreetingHeader]'s tap target.
Future<void> promptForName(BuildContext context, AppState appState) async {
  final controller = TextEditingController(text: appState.userName);
  String? error;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> save() async {
            final name = controller.text.trim();
            if (name.isEmpty) {
              setDialogState(() => error = 'Please enter a name.');
              return;
            }
            await appState.setUserName(name);
            if (ctx.mounted) Navigator.of(ctx).pop();
          }

          return AlertDialog(
            backgroundColor: AppColors.slate900,
            title: const Text('What should we call you?', style: TextStyle(color: AppColors.slate100)),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.slate100),
              decoration: InputDecoration(hintText: 'Your name', errorText: error),
              onSubmitted: (_) => save(),
            ),
            actions: [
              TextButton(onPressed: save, child: const Text('Save')),
            ],
          );
        },
      ),
    ),
  );
}
