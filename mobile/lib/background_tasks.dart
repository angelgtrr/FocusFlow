import 'package:workmanager/workmanager.dart';

import 'api_client.dart';
import 'models.dart';
import 'notifications.dart';

const progressRefreshTaskName = 'focusflow.progressRefresh';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final api = ApiClient();
      await api.load();
      if (!api.hasBaseUrl) return true;
      if (!await api.getSession()) return true;

      final results = await Future.wait([
        api.getDimensions(),
        api.getEntries(),
        api.getTasks(),
        api.getTaskCompletions(),
      ]);

      await initNotifications();
      await updateProgressNotificationFrom(
        dimensions: results[0] as List<Dimension>,
        entries: results[1] as List<Entry>,
        tasks: results[2] as List<Task>,
        taskCompletions: results[3] as List<TaskCompletion>,
      );
    } catch (_) {
      // Background task — nothing to surface errors to, just skip this run.
    }
    return true;
  });
}

Future<void> registerProgressRefresh() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    progressRefreshTaskName,
    progressRefreshTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
