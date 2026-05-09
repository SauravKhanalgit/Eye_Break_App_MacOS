import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_tray/system_tray.dart';
import 'package:timezone/timezone.dart' as tz;

class EyeBreakScreen extends StatefulWidget {
  const EyeBreakScreen({super.key});

  @override
  State<EyeBreakScreen> createState() => _EyeBreakScreenState();
}

class _EyeBreakScreenState extends State<EyeBreakScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _displayTimer;
  bool _isPaused = false;
  int _breakIntervalMinutes = 20;
  int _timeUntilBreak = 20 * 60;
  bool _exactAlarmGranted = false;
  final SystemTray _systemTray = SystemTray();

  static final _batteryChannel = const MethodChannel('eye_break/battery');

  // IDs 100–123 reserved for the 24 pre-scheduled eye-break notifications.
  static const int _scheduleIdBase = 100;
  static const int _scheduleCount = 24;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    if (Platform.isMacOS) _initSystemTray();
    _startDisplayTimer();
    if (Platform.isAndroid) _scheduleAndroidNotifications();
  }

  Future<void> _initNotifications() async {
    const initSettings = InitializationSettings(
      macOS: DarwinInitializationSettings(),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(initSettings);

    if (Platform.isAndroid) {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.requestNotificationsPermission();
      final granted = await plugin?.requestExactAlarmsPermission();
      setState(() => _exactAlarmGranted = granted ?? false);
      await _requestBatteryOptimizationExemption();
    }
  }

  Future<bool> _isIgnoringBatteryOptimizations() async {
    try {
      return await _batteryChannel
          .invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      final alreadyExempt = await _isIgnoringBatteryOptimizations();
      if (!alreadyExempt) {
        await _batteryChannel
            .invokeMethod('requestIgnoreBatteryOptimizations');
      }
    } catch (_) {}
  }

  NotificationDetails get _notificationDetails {
    if (Platform.isAndroid) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          'eye_break_channel',
          'Eye Break',
          channelDescription: '20-20-20 eye break reminders',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          fullScreenIntent: false,
        ),
      );
    }
    return const NotificationDetails(
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  // macOS: show an immediate notification (timer-based).
  Future<void> _showNotificationMacOS() async {
    await _notifications.show(
      0,
      "👀 Time for an Eye Break!",
      "Follow the 20-20-20 rule: Look at something 20 feet away for 20 seconds.",
      _notificationDetails,
    );
  }

  // Android: cancel existing scheduled batch and schedule 24 exact-alarm
  // notifications at the configured interval. These fire even when the app
  // is completely killed.
  Future<void> _scheduleAndroidNotifications() async {
    await _cancelAndroidScheduled();

    final plugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await plugin?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final now = tz.TZDateTime.now(tz.UTC);

    for (int i = 1; i <= _scheduleCount; i++) {
      await _notifications.zonedSchedule(
        _scheduleIdBase + i - 1,
        "👀 Time for an Eye Break!",
        "Follow the 20-20-20 rule: Look at something 20 feet away for 20 seconds.",
        now.add(Duration(minutes: _breakIntervalMinutes * i)),
        _notificationDetails,
        androidScheduleMode: scheduleMode,
      );
    }

    if (mounted) setState(() => _exactAlarmGranted = canExact);
  }

  Future<void> _cancelAndroidScheduled() async {
    for (int i = 0; i < _scheduleCount; i++) {
      await _notifications.cancel(_scheduleIdBase + i);
    }
  }

  // Drives the visible countdown in the UI. On macOS it also fires the
  // notification; on Android notifications are handled by the OS scheduler.
  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _timeUntilBreak = _breakIntervalMinutes * 60;
    if (Platform.isMacOS) _updateSystemTrayTitle();

    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || !mounted) return;
      setState(() {
        _timeUntilBreak--;
        if (_timeUntilBreak <= 0) {
          _timeUntilBreak = _breakIntervalMinutes * 60;
          if (Platform.isMacOS) _showNotificationMacOS();
        }
      });
      if (Platform.isMacOS) _updateSystemTrayTitle();
    });
  }

  void _updateSystemTrayTitle() {
    final m = (_timeUntilBreak / 60).floor();
    final s = _timeUntilBreak % 60;
    _systemTray.setTitle(
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}');
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      if (Platform.isAndroid) _cancelAndroidScheduled();
    } else {
      if (Platform.isAndroid) _scheduleAndroidNotifications();
    }
  }

  void _resetTimer() {
    setState(() => _timeUntilBreak = _breakIntervalMinutes * 60);
    if (Platform.isMacOS) _updateSystemTrayTitle();
    if (!_isPaused && Platform.isAndroid) _scheduleAndroidNotifications();
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
        onClicked: (_) => _showNotificationMacOS(),
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
              if (Platform.isAndroid) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _exactAlarmGranted
                          ? Icons.alarm_on
                          : Icons.alarm_off,
                      size: 16,
                      color: _exactAlarmGranted
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _exactAlarmGranted
                          ? "Exact alarms active — works when app is closed"
                          : "Grant exact alarm permission for background use",
                      style: TextStyle(
                        fontSize: 12,
                        color: _exactAlarmGranted
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (!_exactAlarmGranted)
                  TextButton(
                    onPressed: () async {
                      await _notifications
                          .resolvePlatformSpecificImplementation<
                              AndroidFlutterLocalNotificationsPlugin>()
                          ?.requestExactAlarmsPermission();
                    },
                    child: const Text("Grant Permission"),
                  ),
              ],
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
    _displayTimer?.cancel();
    super.dispose();
  }
}
