import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class DimensionsPage extends StatefulWidget {
  final AppState appState;
  const DimensionsPage({super.key, required this.appState});

  @override
  State<DimensionsPage> createState() => _DimensionsPageState();
}

class _DimensionsPageState extends State<DimensionsPage> {
  final _newNameController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _newNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.appState.createDimension(name);
      _newNameController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _rename(Dimension d) async {
    final controller = TextEditingController(text: d.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        title: const Text('Rename dimension', style: TextStyle(color: AppColors.slate100)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.slate100),
          decoration: const InputDecoration(hintText: 'Dimension name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != d.name) {
      try {
        await widget.appState.renameDimension(d.id, newName);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _delete(Dimension d, int taskCount) async {
    final message = taskCount > 0
        ? 'Delete "${d.name}"? $taskCount task(s) will become dimension-less.'
        : 'Delete "${d.name}"?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        title: const Text('Delete dimension', style: TextStyle(color: AppColors.slate100)),
        content: Text(message, style: const TextStyle(color: AppColors.slate300)),
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
      await widget.appState.deleteDimension(d.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final taskCounts = <int, int>{};
    for (final t in appState.tasks) {
      if (t.dimensionId != null) {
        taskCounts[t.dimensionId!] = (taskCounts[t.dimensionId!] ?? 0) + 1;
      }
    }

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
                  'NEW DIMENSION',
                  style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newNameController,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: const InputDecoration(hintText: 'e.g. Exercise, Work, Learning'),
                  onSubmitted: (_) => _create(),
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
                    child: Text(_submitting ? 'Adding...' : 'Add dimension'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'DIMENSIONS',
            style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          if (appState.dimensions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'No dimensions yet. Add one to start grouping tasks.',
                style: TextStyle(color: AppColors.slate500, fontSize: 13),
              ),
            )
          else
            ...appState.dimensions.map((d) {
              final count = taskCounts[d.id] ?? 0;
              final color = dimensionColor(d.name);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.slate900.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate800),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _rename(d),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.16),
                                  border: Border.all(color: color.withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(d.name, style: TextStyle(color: color, fontSize: 13)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$count ${count == 1 ? 'task' : 'tasks'}',
                                style: const TextStyle(color: AppColors.slate500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _delete(d, count),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.slate500,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
