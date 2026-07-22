import 'package:flutter/material.dart';

import '../app_state.dart';
import '../date_utils.dart';
import '../models.dart';
import '../theme.dart';

class DatesPage extends StatefulWidget {
  final AppState appState;
  const DatesPage({super.key, required this.appState});

  @override
  State<DatesPage> createState() => _DatesPageState();
}

class _DatesPageState extends State<DatesPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _recurringYearly = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.appState.createDate(
        title: title,
        note: _noteController.text.trim(),
        date: toDateKey(_date),
        recurringYearly: _recurringYearly,
      );
      _titleController.clear();
      _noteController.clear();
      setState(() {
        _date = DateTime.now();
        _recurringYearly = false;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _edit(SavedDate d) async {
    final titleController = TextEditingController(text: d.title);
    final noteController = TextEditingController(text: d.note);
    DateTime date = keyToDate(d.date);
    bool recurringYearly = d.recurring == 'yearly';
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.slate900,
          title: const Text('Edit date', style: TextStyle(color: AppColors.slate100)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: const InputDecoration(hintText: 'Title'),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate700),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate400),
                        const SizedBox(width: 8),
                        Text(toDateKey(date), style: const TextStyle(color: AppColors.slate100)),
                      ],
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeats yearly', style: TextStyle(color: AppColors.slate200, fontSize: 14)),
                  value: recurringYearly,
                  onChanged: (v) => setDialogState(() => recurringYearly = v),
                ),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: const InputDecoration(hintText: 'Optional note'),
                  maxLines: 2,
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(error!, style: const TextStyle(color: AppColors.rose400, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  setDialogState(() => error = 'Title is required.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await widget.appState.updateDate(
        d.id,
        title: titleController.text.trim(),
        note: noteController.text.trim(),
        date: toDateKey(date),
        recurringYearly: recurringYearly,
      );
    }
  }

  Future<void> _delete(SavedDate d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        title: const Text('Delete date', style: TextStyle(color: AppColors.slate100)),
        content: Text('Delete "${d.title}"?', style: const TextStyle(color: AppColors.slate300)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.rose400)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.appState.deleteDate(d.id);
    }
  }

  String _formatDaysUntil(int daysUntil) {
    if (daysUntil == 0) return 'Today';
    if (daysUntil == 1) return 'Tomorrow';
    if (daysUntil == -1) return 'Yesterday';
    if (daysUntil > 1) return 'in $daysUntil days';
    return '${-daysUntil} days ago';
  }

  Widget _dateCard(SavedDate d) {
    final occurrence = nextOccurrence(d.date, d.recurring);
    final occurrenceDate = keyToDate(occurrence.occurrenceKey);
    final formattedDate =
        '${occurrenceDate.month}/${occurrenceDate.day}/${occurrenceDate.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.slate900.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate800),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(d.title, style: const TextStyle(color: AppColors.slate200, fontWeight: FontWeight.w500)),
                      if (d.recurring == 'yearly') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.violet400.withValues(alpha: 0.16),
                            border: Border.all(color: AppColors.violet400.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Yearly', style: TextStyle(color: AppColors.violet300, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                  if (d.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(d.note, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '$formattedDate · ${_formatDaysUntil(occurrence.daysUntil)}',
                    style: const TextStyle(color: AppColors.slate600, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _edit(d),
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.slate500,
            ),
            IconButton(
              onPressed: () => _delete(d),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.slate500,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final withOccurrence = appState.dates
        .map((d) => MapEntry(d, nextOccurrence(d.date, d.recurring)))
        .toList();
    final upcoming = withOccurrence.where((e) => e.value.daysUntil >= 0).toList()
      ..sort((a, b) => a.value.daysUntil.compareTo(b.value.daysUntil));
    final past = withOccurrence.where((e) => e.value.daysUntil < 0).toList()
      ..sort((a, b) => b.value.daysUntil.compareTo(a.value.daysUntil));

    return RefreshIndicator(
      onRefresh: appState.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.slate900.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEW DATE',
                  style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: const InputDecoration(hintText: "e.g. Mom's birthday"),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate700),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate400),
                        const SizedBox(width: 8),
                        Text(toDateKey(_date), style: const TextStyle(color: AppColors.slate100)),
                      ],
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeats yearly', style: TextStyle(color: AppColors.slate200, fontSize: 14)),
                  value: _recurringYearly,
                  onChanged: (v) => setState(() => _recurringYearly = v),
                ),
                TextField(
                  controller: _noteController,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: const InputDecoration(hintText: 'Optional note'),
                  maxLines: 2,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(_error!, style: const TextStyle(color: AppColors.rose400, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _create,
                    child: Text(_submitting ? 'Adding...' : 'Add date'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'UPCOMING',
            style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Nothing upcoming.', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
            )
          else
            ...upcoming.map((e) => _dateCard(e.key)),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'PAST',
              style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            ...past.map((e) => _dateCard(e.key)),
          ],
        ],
      ),
    );
  }
}
