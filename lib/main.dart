import 'package:flutter/material.dart';
import 'eye_break_screen.dart';
import 'baba_tiktik_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            EyeBreakScreen(),
            BabaTiktikScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.visibility_outlined),
              selectedIcon: Icon(Icons.visibility),
              label: 'Eye Break',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Baba Tiktik',
            ),
          ],
        ),
      ),
    );
  }
}
