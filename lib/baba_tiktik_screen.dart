import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'foreground_task_handler.dart';

class BabaTiktikScreen extends StatefulWidget {
  const BabaTiktikScreen({super.key});

  @override
  State<BabaTiktikScreen> createState() => _BabaTiktikScreenState();
}

class _BabaTiktikScreenState extends State<BabaTiktikScreen> {
  bool _isRunning = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationEnabled = true;

  final TextEditingController _secondsController =
      TextEditingController(text: '17');
  final TextEditingController _notificationTextController =
      TextEditingController(text: 'Baba ko yad Karo');

  int get _intervalSeconds => int.tryParse(_secondsController.text) ?? 17;

  @override
  void initState() {
    super.initState();
    _checkRunningState();
    // Listen for stop button pressed in the foreground notification
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  void _onTaskData(Object data) {
    // Currently unused — reserved for future task→UI communication
  }

  Future<void> _checkRunningState() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (mounted) setState(() => _isRunning = running);
  }

  void _initService(int seconds) {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'baba_tiktik_foreground',
        channelName: 'Baba Tiktik Service',
        channelDescription: 'Keeps Baba Tiktik running in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(seconds * 1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> _saveTaskData() async {
    await FlutterForegroundTask.saveData(
        key: 'message', value: _notificationTextController.text);
    await FlutterForegroundTask.saveData(
        key: 'soundEnabled', value: _soundEnabled);
    await FlutterForegroundTask.saveData(
        key: 'vibrationEnabled', value: _vibrationEnabled);
    await FlutterForegroundTask.saveData(
        key: 'notificationEnabled', value: _notificationEnabled);
  }

  Future<void> _start() async {
    final seconds = _intervalSeconds;
    if (seconds <= 0) {
      _showError('Please enter a valid number of seconds.');
      return;
    }

    await _saveTaskData();
    _initService(seconds);

    // Request battery optimization exemption so Android won't kill the service
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Baba Tiktik Running',
      notificationText: 'Reminding every ${seconds}s',
      callback: startCallback,
      notificationButtons: [
        const NotificationButton(id: 'stop', text: 'Stop'),
      ],
    );

    if (result is ServiceRequestSuccess) {
      setState(() => _isRunning = true);
    } else if (result is ServiceRequestFailure) {
      _showError('Could not start service: ${result.error}');
    }
  }

  Future<void> _stop() async {
    final result = await FlutterForegroundTask.stopService();
    if (result is ServiceRequestSuccess || result is ServiceRequestFailure) {
      setState(() => _isRunning = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text('Baba Tiktik ⏰'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Interval Input ──────────────────────────────────────
            _SectionCard(
              title: 'Reminder Interval',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notify every how many seconds?',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _secondsController,
                    enabled: !_isRunning,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      suffixText: 'seconds',
                      suffixStyle:
                          const TextStyle(fontSize: 16, color: Colors.black45),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Start / Stop ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? _stop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.red.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Running Status ──────────────────────────────────────
            Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isRunning ? Colors.green : Colors.black38,
                ),
                child: Text(
                  _isRunning
                      ? '● Running — notifying every ${_intervalSeconds}s'
                      : '○ Stopped',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Notification Text ───────────────────────────────────
            _SectionCard(
              title: 'Notification Message',
              child: TextField(
                controller: _notificationTextController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Baba ko yad Karo',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Settings Toggles ────────────────────────────────────
            _SectionCard(
              title: 'Settings',
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.volume_up,
                    iconColor: Colors.deepPurple,
                    title: 'Tick Sound',
                    subtitle: 'Play sound with each notification',
                    value: _soundEnabled,
                    onChanged: (v) => setState(() => _soundEnabled = v),
                  ),
                  const Divider(height: 1),
                  _ToggleRow(
                    icon: Icons.vibration,
                    iconColor: Colors.orange,
                    title: 'Vibration',
                    subtitle: Platform.isAndroid
                        ? 'Vibrate with each notification'
                        : 'Not available on macOS',
                    value: _vibrationEnabled,
                    onChanged: (v) => setState(() => _vibrationEnabled = v),
                    enabled: Platform.isAndroid,
                  ),
                  const Divider(height: 1),
                  _ToggleRow(
                    icon: Icons.notifications_active,
                    iconColor: Colors.blue,
                    title: 'Notification Popup',
                    subtitle: 'Show banner notification on screen',
                    value: _notificationEnabled,
                    onChanged: (v) => setState(() => _notificationEnabled = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _secondsController.dispose();
    _notificationTextController.dispose();
    super.dispose();
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }
}
