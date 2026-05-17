import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BabaTiktikTaskHandler());
}

class BabaTiktikTaskHandler extends TaskHandler {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final message = await FlutterForegroundTask.getData<String>(key: 'message')
        ?? 'Baba ko yad Karo';
    final soundEnabled =
        await FlutterForegroundTask.getData<bool>(key: 'soundEnabled') ?? true;
    final vibrationEnabled =
        await FlutterForegroundTask.getData<bool>(key: 'vibrationEnabled') ?? true;
    final notificationEnabled =
        await FlutterForegroundTask.getData<bool>(key: 'notificationEnabled') ?? true;

    if (!notificationEnabled) return;

    await _localNotifications.show(
      1,
      '⏰ Tiktik!',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'baba_tiktik_channel',
          'Baba Tiktik',
          channelDescription: 'Periodic reminders from Baba Tiktik',
          importance: Importance.high,
          priority: Priority.high,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
        ),
      ),
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) async {
    if (data is Map<String, dynamic>) {
      await FlutterForegroundTask.saveData(
          key: 'message', value: data['message'] as String);
      await FlutterForegroundTask.saveData(
          key: 'soundEnabled', value: data['soundEnabled'] as bool);
      await FlutterForegroundTask.saveData(
          key: 'vibrationEnabled', value: data['vibrationEnabled'] as bool);
      await FlutterForegroundTask.saveData(
          key: 'notificationEnabled', value: data['notificationEnabled'] as bool);
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }
}
