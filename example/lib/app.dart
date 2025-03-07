import 'package:flutter_app_update_notifier/app_update_notifier.dart';
import 'package:example/pages/home_page.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<String> fetchMinForcedVersion() async =>
      Future.delayed(const Duration(seconds: 1), () => '1.0.0');

  Future<String> fetchMinVersion() async =>
      Future.delayed(const Duration(seconds: 1), () => '1.0.1');

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'App Update Notifier App',
    navigatorKey: navigatorKey,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    builder: (context, child) {
      return AppUpdateWidget(
        navigatorKey: navigatorKey,
        iosAppStoreId: '284882215',
        fetchMinVesion: () async => fetchMinVersion(),
        fetchMinForcedVesion: () async => fetchMinForcedVersion(),
        onUpdate: (context, storeUrl) async {
          await showAdaptiveDialog<void>(
            context: context,
            builder:
                (context) => AlertDialog(
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
          return await showAdaptiveDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
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
        onException: (error, exception) {
          debugPrint('Error: $error, Exception: $exception');
        },
        child: child!,
      );
    },
    home: const HomePage(),
  );
}
