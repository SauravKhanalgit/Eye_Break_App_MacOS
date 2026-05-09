import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_tray/system_tray.dart';

class EyeBreakScreen extends StatefulWidget {
  const EyeBreakScreen({super.key});

  @override
  State<EyeBreakScreen> createState() => _EyeBreakScreenState();
}

class _EyeBreakScreenState extends State<EyeBreakScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  Timer? _displayTimer;
  bool _isPaused = false;
  int _breakIntervalMinutes = 20;
  int _timeUntilBreak = 20 * 60;
  final SystemTray _systemTray = SystemTray();

  static const _androidChannelId = 'eye_break_channel';
  static const _androidChannelName = 'Eye Break';
  static const _notificationId = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    if (Platform.isMacOS) _initSystemTray();
    _startTimer();
  }

  Future<void> _initNotifications() async {
    const initSettings = InitializationSettings(
      macOS: DarwinInitializationSettings(),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(initSettings);

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  NotificationDetails get _notificationDetails {
    if (Platform.isAndroid) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: '20-20-20 eye break reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
      );
    }
    return const NotificationDetails(
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  Future<void> _showNotification() async {
    await _notifications.show(
      _notificationId,
      "👀 Time for an Eye Break!",
      "Follow the 20-20-20 rule: Look at something 20 feet away for 20 seconds.",
      _notificationDetails,
    );
  }

  // Schedules a repeating background notification on Android so reminders
  // fire even when the app is killed.
  Future<void> _scheduleAndroidPeriodicNotification() async {
    await _notifications.cancel(_notificationId);
    await _notifications.periodicallyShowWithDuration(
      _notificationId,
      "👀 Time for an Eye Break!",
      "Follow the 20-20-20 rule: Look at something 20 feet away for 20 seconds.",
      Duration(minutes: _breakIntervalMinutes),
      _notificationDetails,
    );
  }

  void _startTimer() {
    if (_isPaused) return;
    _timer?.cancel();
    _displayTimer?.cancel();
    _timeUntilBreak = _breakIntervalMinutes * 60;

    if (Platform.isMacOS) _updateSystemTrayTitle();
    if (Platform.isAndroid) _scheduleAndroidPeriodicNotification();

    // On macOS the timer fires the notification; on Android notifications are
    // handled by the system scheduler above — the timer is visual only.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _timeUntilBreak -= 60;
      if (_timeUntilBreak <= 0) {
        _timeUntilBreak = _breakIntervalMinutes * 60;
        if (Platform.isMacOS) _showNotification();
      }
      if (Platform.isMacOS) _updateSystemTrayTitle();
    });

    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() => _timeUntilBreak--);
        if (Platform.isMacOS) _updateSystemTrayTitle();
      }
    });
  }

  void _updateSystemTrayTitle() {
    final minutes = (_timeUntilBreak / 60).floor();
    final seconds = _timeUntilBreak % 60;
    _systemTray.setTitle(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
        _displayTimer?.cancel();
        if (Platform.isAndroid) _notifications.cancel(_notificationId);
      } else {
        _startTimer();
      }
    });
  }

  void _resetTimer() {
    setState(() => _timeUntilBreak = _breakIntervalMinutes * 60);
    if (Platform.isMacOS) _updateSystemTrayTitle();
    if (!_isPaused) _startTimer();
  }

  Future<void> _initSystemTray() async {
    await _systemTray.initSystemTray(
      title: "EyeBreak",
      iconPath:
          "macos/Runner/Assets.xcassets/AppIcon.appiconset/tray_icon.png",
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: "Take Break Now",
        onClicked: (_) => _showNotification(),
      ),
      MenuItemLabel(
        label: _isPaused ? "Resume Timer" : "Pause Timer",
        onClicked: (_) => _togglePause(),
      ),
      MenuItemLabel(label: "Reset Timer", onClicked: (_) => _resetTimer()),
      MenuSeparator(),
      MenuItemLabel(
        label: "Set 20 min interval",
        onClicked: (_) => setState(() {
          _breakIntervalMinutes = 20;
          _resetTimer();
        }),
      ),
      MenuItemLabel(
        label: "Set 30 min interval",
        onClicked: (_) => setState(() {
          _breakIntervalMinutes = 30;
          _resetTimer();
        }),
      ),
      MenuItemLabel(
        label: "Set 60 min interval",
        onClicked: (_) => setState(() {
          _breakIntervalMinutes = 60;
          _resetTimer();
        }),
      ),
      MenuSeparator(),
      MenuItemLabel(label: "Quit", onClicked: (_) => _systemTray.destroy()),
    ]);

    await _systemTray.setContextMenu(menu);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_timeUntilBreak / 60).floor();
    final seconds = _timeUntilBreak % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Eye Break Timer 👀"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Interval: $_breakIntervalMinutes min',
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                _isPaused ? "Paused ⏸️" : "Running ▶️",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _isPaused ? Colors.red : Colors.green,
                ),
              ),
              if (Platform.isAndroid)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "Notifications continue in background",
                    style: TextStyle(fontSize: 13, color: Colors.blueAccent),
                  ),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? "Resume" : "Pause"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Follow the 20-20-20 rule:\nLook at something 20 feet away for 20 seconds every 20 minutes.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _displayTimer?.cancel();
    super.dispose();
  }
}
