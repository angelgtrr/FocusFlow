import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'date_utils.dart';
import 'hourglass.dart';
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
  required int currentScore,
  required int maxScore,
  required List<String> doneDimensions,
  required List<String> missingDimensions,
}) async {
  final body = '$dimensionsLogged/$totalDimensions dimensions · $currentScore/$maxScore points today';

  final dayProgress = hourglassDayProgress();

  final androidDetails = AndroidNotificationDetails(
    _channelId,
    'Daily progress',
    channelDescription: "Shows today's FocusFlow progress",
    icon: hourglassIconName(dayProgress),
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    onlyAlertOnce: true,
    showWhen: false,
    styleInformation: BigTextStyleInformation(
      [
        hourglassRemainingLabel(dayProgress),
        if (doneDimensions.isNotEmpty) 'Done: ${doneDimensions.join(', ')}',
        if (missingDimensions.isNotEmpty) 'Pending: ${missingDimensions.join(', ')}',
      ].join('\n'),
      contentTitle: 'FocusFlow',
      summaryText: body,
    ),
  );
  await _plugin.show(
    id: _notificationId,
    title: 'FocusFlow',
    body: body,
    notificationDetails: NotificationDetails(android: androidDetails),
  );
}

Future<void> hideProgressNotification() => _plugin.cancel(id: _notificationId);

Future<void> updateProgressNotificationFrom({
  required List<Dimension> dimensions,
  required List<Entry> entries,
}) async {
  final today = todayKey();
  final todaysEntries = entries.where((e) => e.date == today).toList();
  final progress = buildDimensionProgress(dimensions, todaysEntries);
  final doneDimensions = progress.where((d) => d.loggedToday).map((d) => d.dimension.name).toList();
  final missingDimensions = progress.where((d) => !d.loggedToday).map((d) => d.dimension.name).toList();

  final currentScore = todaysEntries.fold<int>(0, (sum, e) => sum + e.score);
  final maxScore = dimensions.length * 4;

  await showProgressNotification(
    dimensionsLogged: doneDimensions.length,
    totalDimensions: dimensions.length,
    currentScore: currentScore,
    maxScore: maxScore,
    doneDimensions: doneDimensions,
    missingDimensions: missingDimensions,
  );
}
