import 'package:flutter/material.dart';

import '../theme.dart';

class DayNoteEditor extends StatefulWidget {
  final String date;
  final String note;
  final Future<void> Function(String date, String note) onSave;

  const DayNoteEditor({super.key, required this.date, required this.note, required this.onSave});

  @override
  State<DayNoteEditor> createState() => _DayNoteEditorState();
}

class _DayNoteEditorState extends State<DayNoteEditor> {
  late TextEditingController _controller;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note);
  }

  @override
  void didUpdateWidget(covariant DayNoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date || oldWidget.note != widget.note) {
      _controller.text = widget.note;
      _saved = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _dirty => _controller.text != widget.note;

  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await widget.onSave(widget.date, _controller.text);
      if (mounted) setState(() => _saved = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: 3,
            style: const TextStyle(color: AppColors.slate100),
            decoration: const InputDecoration(hintText: 'Anything worth remembering about this day?'),
            onChanged: (_) {
              if (_saved) setState(() => _saved = false);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saving || !_dirty ? null : _handleSave,
                child: Text(_saving ? 'Saving...' : 'Save note'),
              ),
              if (_saved && !_dirty) ...[
                const SizedBox(width: 12),
                const Text('Saved', style: TextStyle(color: AppColors.emerald400, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
