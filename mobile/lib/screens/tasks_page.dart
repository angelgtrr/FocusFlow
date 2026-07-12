import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class TasksPage extends StatefulWidget {
  final AppState appState;
  const TasksPage({super.key, required this.appState});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

const _statusOrder = {TaskStatus.active: 0, TaskStatus.paused: 1, TaskStatus.done: 2};

const _statusColors = {
  TaskStatus.active: AppColors.emerald400,
  TaskStatus.paused: AppColors.amber500,
  TaskStatus.done: AppColors.slate500,
};

class _TasksPageState extends State<TasksPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _dimensionId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      await widget.appState.createTask(
        title: title,
        description: _descriptionController.text.trim(),
        dimensionId: _dimensionId,
      );
      _titleController.clear();
      _descriptionController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(Task t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        title: const Text('Delete task', style: TextStyle(color: AppColors.slate100)),
        content: Text('Delete "${t.title}"?', style: const TextStyle(color: AppColors.slate300)),
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
      await widget.appState.deleteTask(t.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final tasks = [...appState.tasks]..sort((a, b) {
      final statusDiff = _statusOrder[a.status]! - _statusOrder[b.status]!;
      if (statusDiff != 0) return statusDiff;
      return b.createdAt.compareTo(a.createdAt);
    });

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
                const Text('NEW TASK', style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: const InputDecoration(hintText: 'e.g. Run 3x a week'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: _dimensionId,
                  dropdownColor: AppColors.slate800,
                  style: const TextStyle(color: AppColors.slate100),
                  hint: const Text('No dimension', style: TextStyle(color: AppColors.slate500)),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('No dimension')),
                    ...appState.dimensions.map((d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (v) => setState(() => _dimensionId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: const InputDecoration(hintText: 'Brief description of the task'),
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
                    child: Text(_submitting ? 'Adding...' : 'Add task'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'TASKS',
            style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No tasks yet. Add your first one.', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
            )
          else
            ...tasks.map((t) => _TaskTile(task: t, onStatusChange: appState.updateTaskStatus, onDelete: _delete)),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final Future<void> Function(int id, TaskStatus status) onStatusChange;
  final Future<void> Function(Task) onDelete;

  const _TaskTile({required this.task, required this.onStatusChange, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dimColor = task.dimensionName != null ? dimensionColor(task.dimensionName!) : noDimensionColor;
    final statusColor = _statusColors[task.status]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.slate900.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(color: AppColors.slate200, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(task),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.slate500,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dimColor.withValues(alpha: 0.14),
                    border: Border.all(color: dimColor.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(task.dimensionName ?? 'No dimension', style: TextStyle(color: dimColor, fontSize: 11)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: DropdownButton<TaskStatus>(
                    value: task.status,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.slate800,
                    isDense: true,
                    style: TextStyle(color: statusColor, fontSize: 12),
                    items: TaskStatus.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (s) {
                      if (s != null) onStatusChange(task.id, s);
                    },
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.description, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
