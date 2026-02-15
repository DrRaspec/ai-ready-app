# AI Chat Bot

A Flutter-based AI chat bot application designed for seamless conversational AI interactions. Built with modern Flutter architecture using BLoC for state management, secure storage for data persistence, and environment-based configuration for flexible deployments.

## Features

- **Cross-Platform Support**: Runs on Android, iOS, Web, Windows, macOS, and Linux.
- **State Management**: Powered by BLoC (Business Logic Component) for predictable and testable UI logic.
- **Secure Storage**: Utilizes `flutter_secure_storage` for sensitive data and `shared_preferences` for app settings.
- **Environment Configuration**: Supports development and production environments with `.env` files.
- **Custom Logging**: Integrated logging system with configurable levels and caller information.
- **Modular Architecture**: Organized into core utilities, features, and app-level components.

## Prerequisites

Before running this project, ensure you have the following installed:

- **Flutter SDK**: Version 3.10.7 or later. [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Included with Flutter.
- **Android Studio** or **Xcode**: For Android/iOS development and emulators/simulators.
- **Git**: For version control.

Verify your setup:

```bash
flutter doctor
```

## Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/your-username/ai_chat_bot.git
   cd ai_chat_bot
   ```

2. **Install dependencies**:

   ```bash
   flutter pub get
   ```

3. **Set up environment files**:
   - Copy the example files in `env/`:
     - `env/.env.dev.example` -> `env/.env.dev`
     - `env/.env.production.example` -> `env/.env.production`
   - Required keys:
     ```
     API_BASE_URL=https://api.example.com
     BASE_URL=https://api.example.com
     GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
     ENABLE_MOCK_AUTH=false
     CONNECT_TIMEOUT=10000
     ```

4. **Set up Android release signing**:
   - Copy `android/key.properties.example` -> `android/key.properties`.
   - Fill in `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`.
   - Keep both `android/key.properties` and your keystore file out of git.

## Usage

### Running in Development Mode

To run the app in development mode with debug features enabled:

```bash
flutter run --dart-define=ENV=dev
```

### Running in Production Mode

For production builds with optimizations:

```bash
flutter run --release --dart-define=ENV=production
```

### Building for Platforms

#### Android APK

```bash
flutter build apk --dart-define=ENV=production
```

#### Android App Bundle

```bash
flutter build appbundle --dart-define=ENV=production
```

#### iOS

```bash
flutter build ios --dart-define=ENV=production
```

#### Web

```bash
flutter build web --dart-define=ENV=production
```

#### Other Platforms

- **Windows**: `flutter build windows`
- **macOS**: `flutter build macos`
- **Linux**: `flutter build linux`

## Project Structure

```
ai_chat_bot/
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── lib/                     # Main Flutter code
│   ├── app/                 # App-level widgets and configuration
│   ├── core/                # Core utilities
│   │   ├── config/          # Environment and app configuration
│   │   └── logging/         # Custom logging system
│   ├── features/            # Feature-specific modules (expandable)
│   └── main.dart            # App entry point
├── web/                     # Web-specific files
├── windows/                 # Windows-specific files
├── macos/                   # macOS-specific files
├── linux/                   # Linux-specific files
├── env/                     # Environment configuration files
├── pubspec.yaml             # Flutter dependencies and config
└── README.md                # This file
```

## Architecture

This app follows a clean architecture pattern:

- **Presentation Layer**: Widgets and UI components managed by BLoC.
- **Business Logic Layer**: BLoC cubits handling state and events.
- **Data Layer**: Repositories for API calls, local storage, and data models.
- **Core Layer**: Shared utilities like logging, configuration, and environment management.

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Submit a pull request.

## Testing

Run tests with:

```bash
flutter test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions or issues, please open an issue on GitHub or contact the maintainers.
