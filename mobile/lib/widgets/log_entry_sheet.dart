import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

Future<void> showLogEntrySheet({
  required BuildContext context,
  required AppState appState,
  required String date,
  int? initialDimensionId,
}) {
  if (appState.dimensions.isEmpty) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        content: const Text(
          'No dimensions yet. Head to the Dimensions tab to create one first.',
          style: TextStyle(color: AppColors.slate300),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.slate900,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        child: _LogEntrySheetContent(appState: appState, date: date, initialDimensionId: initialDimensionId),
      ),
    ),
  );
}

class _LogEntrySheetContent extends StatefulWidget {
  final AppState appState;
  final String date;
  final int? initialDimensionId;

  const _LogEntrySheetContent({required this.appState, required this.date, this.initialDimensionId});

  @override
  State<_LogEntrySheetContent> createState() => _LogEntrySheetContentState();
}

class _LogEntrySheetContentState extends State<_LogEntrySheetContent> {
  late int dimensionId;
  int? score;
  late TextEditingController noteController;
  final FocusNode _noteFocusNode = FocusNode();
  bool submitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    dimensionId = widget.initialDimensionId ?? widget.appState.dimensions.first.id;
    final existing = _existingEntry();
    score = existing?.score;
    noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _noteFocusNode.dispose();
    super.dispose();
  }

  Entry? _existingEntry() {
    for (final e in widget.appState.entries) {
      if (e.dimensionId == dimensionId && e.date == widget.date) return e;
    }
    return null;
  }

  void _onDimensionChanged(int? id) {
    if (id == null) return;
    setState(() {
      dimensionId = id;
      final existing = _existingEntry();
      score = existing?.score;
      noteController.text = existing?.note ?? '';
    });
    // Closing the dropdown's menu route sometimes hands keyboard focus to the
    // next focusable widget (the note field) instead of releasing it — a known
    // Flutter framework quirk. Explicitly drop focus once that settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_noteFocusNode.hasFocus) _noteFocusNode.unfocus();
    });
  }

  Future<void> _submit() async {
    if (score == null) {
      setState(() => error = 'Pick a score first.');
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      await widget.appState.logEntry(
        dimensionId: dimensionId,
        score: score!,
        note: noteController.text.trim(),
        date: widget.date,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingEntry() != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.slate700, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            isEditing ? 'Update progress' : 'Log progress',
            style: const TextStyle(color: AppColors.slate100, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text('DIMENSION', style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: dimensionId,
            dropdownColor: AppColors.slate800,
            style: const TextStyle(color: AppColors.slate100),
            items: widget.appState.dimensions
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: _onDimensionChanged,
          ),
          const SizedBox(height: 16),
          const Text('SCORE', style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var s = 0; s <= 4; s++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => setState(() => score = s),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: score == s ? scoreRingColors[s].withValues(alpha: 0.18) : null,
                        side: BorderSide(color: score == s ? scoreRingColors[s] : AppColors.slate700),
                      ),
                      child: Text(
                        '$s',
                        style: TextStyle(color: score == s ? AppColors.slate100 : AppColors.slate400),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (score != null) ...[
            const SizedBox(height: 6),
            Text(scoreLabels[score!], style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          const Text('NOTE', style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: noteController,
            focusNode: _noteFocusNode,
            maxLines: 3,
            style: const TextStyle(color: AppColors.slate100),
            decoration: const InputDecoration(hintText: 'What did you do today?'),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: AppColors.rose400, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.slate700),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.slate300)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: submitting ? null : _submit,
                  child: Text(submitting ? 'Saving...' : 'Save entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
