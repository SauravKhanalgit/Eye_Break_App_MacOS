import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_tray/system_tray.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  Timer? _displayTimer;
  bool _isPaused = false;
  int _breakIntervalMinutes = 20; // 20-20-20 rule
  int _timeUntilBreak = 20 * 60; // in seconds
  final SystemTray _systemTray = SystemTray();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _initSystemTray();
    _startTimer();
  }

  Future<void> _initNotifications() async {
    const DarwinInitializationSettings initSettingsMac =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      macOS: initSettingsMac,
    );
    await _notifications.initialize(initSettings);
  }

  Future<void> _showNotification() async {
    const NotificationDetails details = NotificationDetails(
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _notifications.show(
      0,
      "👀 Time for an Eye Break!",
      "Follow the 20-20-20 rule:\n• Look at something 20 feet away\n• For 20 seconds\n• Every 20 minutes",
      details,
    );
  }

  void _startTimer() {
    if (_isPaused) return;

    _timer?.cancel();
    _displayTimer?.cancel();

    _timeUntilBreak = _breakIntervalMinutes * 60;
    _updateSystemTrayTitle();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _timeUntilBreak -= 60;
      if (_timeUntilBreak <= 0) {
        _timeUntilBreak = _breakIntervalMinutes * 60;
        _showNotification();
      }
      _updateSystemTrayTitle();
    });

    // Update display every second
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _timeUntilBreak--;
        _updateSystemTrayTitle();
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
      } else {
        _startTimer();
      }
    });
  }

  void _resetTimer() {
    _timeUntilBreak = _breakIntervalMinutes * 60;
    _updateSystemTrayTitle();
    if (!_isPaused) {
      _startTimer();
    }
  }

  Future<void> _initSystemTray() async {
    await _systemTray.initSystemTray(
      title: "EyeBreak",
      iconPath: "macos/Runner/Assets.xcassets/AppIcon.appiconset/tray_icon.png",
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
        onClicked: (_) {
          setState(() {
            _breakIntervalMinutes = 20;
            _resetTimer();
          });
        },
      ),
      MenuItemLabel(
        label: "Set 30 min interval",
        onClicked: (_) {
          setState(() {
            _breakIntervalMinutes = 30;
            _resetTimer();
          });
        },
      ),
      MenuItemLabel(
        label: "Set 60 min interval",
        onClicked: (_) {
          setState(() {
            _breakIntervalMinutes = 60;
            _resetTimer();
          });
        },
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Eye Break Timer 👀"),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Countdown timer
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Current interval
                Text(
                  'Interval: $_breakIntervalMinutes min',
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // Status
                Text(
                  _isPaused ? "Paused ⏸️" : "Running ▶️",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: _isPaused ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 32),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? "Resume" : "Pause"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
                          horizontal: 20,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Info
                const Text(
                  "Follow the 20-20-20 rule:\nLook at something 20 feet away for 20 seconds every 20 minutes.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
