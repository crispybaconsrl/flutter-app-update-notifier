import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_update_notifier/src/logic/logic.dart';

typedef UpdateCallback = void Function(BuildContext context, String storeUrl);

typedef ForcedUpdateCallback = Future<bool?> Function(
  BuildContext context,
  String storeUrl,
);

typedef ErrorUpdateCallback = void Function(
  Object error,
  StackTrace? stackTrace,
);

typedef FetchMinVersionCallback = FutureOr<String?> Function();

typedef FetchMinForcedVersionCallback = FutureOr<String?> Function();

class AppUpdateWidget extends StatefulWidget {
  const AppUpdateWidget({
    required this.navigatorKey,
    required this.iosAppStoreId,
    required this.fetchMinVesion,
    required this.fetchMinForcedVesion,
    required this.onUpdate,
    required this.onForcedUpdate,
    required this.onException,
    required this.child,
    this.optionalUpdateTriggerCount = 0,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final FetchMinVersionCallback fetchMinVesion;
  final FetchMinForcedVersionCallback fetchMinForcedVesion;
  final String iosAppStoreId;
  final int optionalUpdateTriggerCount;
  final UpdateCallback onUpdate;
  final ForcedUpdateCallback onForcedUpdate;
  final ErrorUpdateCallback? onException;
  final Widget child;

  @override
  State<AppUpdateWidget> createState() => _AppUpdateWidgetState();
}

class _AppUpdateWidgetState extends State<AppUpdateWidget>
    with WidgetsBindingObserver {
  bool _isAlertVisible = false;

  late final AppUpdateNotifierClient _appUpdateClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUpdateClient();
    _checkForUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeUpdateClient() {
    _appUpdateClient = AppUpdateNotifierClient(
      fetchMinVersion: widget.fetchMinVesion,
      fetchMinForcedVersion: widget.fetchMinForcedVesion,
      iosAppStoreId: widget.iosAppStoreId,
      optionalUpdateTriggerCount: widget.optionalUpdateTriggerCount,
    );
  }

  Future<void> _checkForUpdates() async {
    try {
      await _evaluateAppUpdateRequirement();
    } on Object catch (e, st) {
      _handleUpdateError(e, st);
    }
  }

  Future<void> _evaluateAppUpdateRequirement() async {
    if (_isAlertVisible) return;

    final updateState = await _appUpdateClient.isAppUpdateRequired();

    if (updateState.needForcedUpdate && updateState.needUpdate) return;

    final storeUrl = await _appUpdateClient.storeUrl();
    if (storeUrl == null) return;

    final ctx = widget.navigatorKey.currentContext ?? context;
    if (!ctx.mounted) return;

    if (updateState.needUpdate) {
      widget.onUpdate(ctx, storeUrl);
    } else if (updateState.needForcedUpdate) {
      await _showForcedUpdateDialog(storeUrl);
    }
  }

  Future<void> _showForcedUpdateDialog(String storeUrl) async {
    final ctx = widget.navigatorKey.currentContext ?? context;
    if (!ctx.mounted) return;

    _isAlertVisible = true;
    final userResponse = await widget.onForcedUpdate(ctx, storeUrl);
    _isAlertVisible = false;

    if (userResponse == null) {
      await _showForcedUpdateDialog(storeUrl);
    }
  }

  void _handleUpdateError(Object error, StackTrace stackTrace) {
    final errorHandler = widget.onException;
    if (errorHandler != null) {
      errorHandler(error, stackTrace);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        _checkForUpdates(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
