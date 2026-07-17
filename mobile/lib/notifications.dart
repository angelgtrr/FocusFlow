import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'date_utils.dart';
import 'models.dart';
import 'stats.dart';

const _channelId = 'focusflow_progress';
const _notificationId = 1;

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _plugin.initialize(settings: initSettings);

  final androidPlugin = _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      _channelId,
      'Daily progress',
      description: "Shows today's FocusFlow progress",
      importance: Importance.low,
    ),
  );
  await androidPlugin?.requestNotificationsPermission();
}

Future<void> showProgressNotification({
  required int dimensionsLogged,
  required int totalDimensions,
  required int tasksDone,
  required int totalTasks,
}) async {
  const androidDetails = AndroidNotificationDetails(
    _channelId,
    'Daily progress',
    channelDescription: "Shows today's FocusFlow progress",
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    onlyAlertOnce: true,
    showWhen: false,
  );
  await _plugin.show(
    id: _notificationId,
    title: 'FocusFlow',
    body: '$dimensionsLogged/$totalDimensions dimensions · $tasksDone/$totalTasks tasks done today',
    notificationDetails: const NotificationDetails(android: androidDetails),
  );
}

Future<void> hideProgressNotification() => _plugin.cancel(id: _notificationId);

Future<void> updateProgressNotificationFrom({
  required List<Dimension> dimensions,
  required List<Entry> entries,
  required List<Task> tasks,
  required List<TaskCompletion> taskCompletions,
}) async {
  final today = todayKey();
  final todaysEntries = entries.where((e) => e.date == today).toList();
  final dimensionsLogged = buildDimensionProgress(
    dimensions,
    todaysEntries,
  ).where((d) => d.loggedToday).length;

  final activeTasks = tasks.where((t) => t.status == TaskStatus.active).toList();
  final completedIds = completedTaskIdsForDate(taskCompletions, today);
  final tasksDone = activeTasks.where((t) => completedIds.contains(t.id)).length;

  await showProgressNotification(
    dimensionsLogged: dimensionsLogged,
    totalDimensions: dimensions.length,
    tasksDone: tasksDone,
    totalTasks: activeTasks.length,
  );
}
