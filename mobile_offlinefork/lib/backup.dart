import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_state.dart';

/// The app's own external "backups" folder — no special permissions needed
/// on modern Android since it's app-specific storage. Both the export and
/// import flows read/write here, so a backup made on this device shows up
/// for import without leaving the app; backups from elsewhere can be dropped
/// in via a Files app's "Move to" / "Copy to" action.
Future<Directory> _backupsDir() async {
  final base = await getExternalStorageDirectory();
  if (base == null) throw Exception('External storage is not available on this device.');
  final dir = Directory('${base.path}/backups');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

Future<String> backupsFolderPath() async => (await _backupsDir()).path;

/// Copies the live local database into the backups folder with a timestamped
/// name, then opens the native share sheet so it can also be saved to Drive,
/// email, a Files app, etc.
Future<void> exportBackup(AppState appState) async {
  final dbPath = await appState.localDb.databaseFilePath();
  final dbFile = File(dbPath);
  if (!await dbFile.exists()) {
    throw Exception('No local data to back up yet.');
  }
  final dir = await _backupsDir();
  final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp('[:.]'), '-');
  final exportPath = '${dir.path}/focusflow_backup_$timestamp.db';
  final exported = await dbFile.copy(exportPath);
  await SharePlus.instance.share(ShareParams(files: [XFile(exported.path)], text: 'FocusFlow backup'));
}

/// Backups available to restore, newest first.
Future<List<File>> listBackups() async {
  final dir = await _backupsDir();
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.db')).toList();
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files;
}

/// Replaces the current local database with [backupFile] and reloads
/// [appState] from disk.
Future<void> restoreBackup(AppState appState, File backupFile) async {
  await appState.localDb.close();
  final dbPath = await appState.localDb.databaseFilePath();
  await backupFile.copy(dbPath);
  await appState.reload();
}

Future<void> exportBackupWithFeedback(BuildContext context, AppState appState) async {
  try {
    await exportBackup(appState);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

Future<void> showImportBackupDialog(BuildContext context, AppState appState) async {
  List<File> backups;
  String folderPath;
  try {
    backups = await listBackups();
    folderPath = await backupsFolderPath();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not read backups: $e')));
    return;
  }
  if (!context.mounted) return;

  if (backups.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No backups found'),
        content: Text('Export a backup first, or copy a .db backup file into:\n\n$folderPath'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    return;
  }

  final picked = await showDialog<File>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Import backup'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: backups.length,
          itemBuilder: (_, i) {
            final f = backups[i];
            final name = f.path.split(Platform.pathSeparator).last;
            return ListTile(
              title: Text(name),
              subtitle: Text('${f.statSync().modified}'),
              onTap: () => Navigator.pop(ctx, f),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
    ),
  );
  if (picked == null) return;
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Replace all data?'),
      content: Text(
        'This replaces all current data on this device with '
        '"${picked.path.split(Platform.pathSeparator).last}". This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace data')),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await restoreBackup(appState, picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup imported.')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
  }
}
