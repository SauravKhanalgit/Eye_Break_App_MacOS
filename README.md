# 👀 Eye Break App

A macOS menu bar application built with Flutter that helps you follow the **20-20-20 rule** to reduce eye strain from prolonged screen time.

## 🌟 Features

- **Menu Bar Timer**: Displays countdown timer directly in your macOS menu bar
- **Smart Notifications**: Get reminded to take breaks at customizable intervals
- **Flexible Intervals**: Choose from 20, 30, or 60-minute break intervals
- **Pause & Resume**: Control your timer with ease
- **Take Break Anytime**: Manually trigger a break reminder when needed
- **Minimal & Lightweight**: Runs quietly in the background without cluttering your workspace

## 📖 The 20-20-20 Rule

Every **20 minutes**, look at something **20 feet away** for **20 seconds** to help reduce eye strain and fatigue.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- macOS (for menu bar functionality)
- Xcode (for macOS development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/eye_break_app.git
cd eye_break_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run -d macos
```

## 🛠️ Building

To build a release version for macOS:

```bash
flutter build macos --release
```

The built app will be available in `build/macos/Build/Products/Release/`.

## 📦 Dependencies

- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) - For system notifications
- [system_tray](https://pub.dev/packages/system_tray) - For macOS menu bar integration

## 🎯 Usage

1. Launch the app - it will appear in your macOS menu bar
2. The timer starts automatically with a 20-minute interval
3. Click the menu bar icon to:
   - View remaining time
   - Pause/Resume the timer
   - Reset the timer
   - Change break intervals
   - Take a break immediately
   - Quit the app

## 🖼️ Screenshots

<!-- Add screenshots here when available -->

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the 20-20-20 rule recommended by eye care professionals
- Built with Flutter for native macOS performance

## 📧 Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter)

Project Link: [https://github.com/yourusername/eye_break_app](https://github.com/yourusername/eye_break_app)

---

⭐ If this app helps you maintain better eye health, please consider giving it a star!
