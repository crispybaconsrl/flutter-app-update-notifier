# App Update Notifier

A Flutter package that alerts users when app updates are available, supporting both optional and mandatory update prompts.

## Features

- Check for app updates on both iOS and Android platforms.
- Support for optional and mandatory updates.
- Customizable update prompts.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  app_update_notifier: ^0.0.1
```

Then run:

```sh
flutter pub get
```

## Usage

### Basic Setup

1. **Initialize the `AppUpdateNotifierClient`:**

```dart
import 'package:app_update_notifier/app_update_notifier.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
```

2. **Wrap your app with `AppUpdateWidget`:**

```dart
import 'package:flutter/material.dart';
import 'package:app_update_notifier/app_update_notifier.dart';
import 'package:example/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return MaterialApp(
      title: 'App Update Notifier App',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) {
        return AppUpdateWidget(
          navigatorKey: navigatorKey,
          iosAppStoreId: 'YOUR_IOS_APP_STORE_ID',
          fetchMinVersion: fetchMinVersion,
          fetchMinForcedVersion: fetchMinForcedVersion,
          onUpdate: (context, storeUrl) async {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Update Available'),
                content: const Text(
                  'A new version of the app is available. Would you like to update?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Later'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Update'),
                  ),
                ],
              ),
            );
          },
          onForcedUpdate: (context, storeUrl) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Update Required'),
                content: const Text('Please update the app to continue.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          onException: (error, stackTrace) {
            debugPrint('Error: $error, StackTrace: $stackTrace');
          },
          child: child!,
        );
      },
      home: const HomePage(),
    );
  }

  Future<String?> fetchMinVersion() async {
    // Fetch the minimum version from your server
    return '1.0.0';
  }

  Future<String?> fetchMinForcedVersion() async {
    // Fetch the minimum forced version from your server
    return '2.0.0';
  }
}
```

3. **Create your `HomePage`:**

```dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('App Update Notifier Example'),
    ),
    body: const SizedBox.shrink(),
  );
}
```

## Example

Check the [example](example) directory for a complete example.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
