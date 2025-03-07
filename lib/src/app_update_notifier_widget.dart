import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_update_notifier/src/logic/logic.dart';

typedef UpdateCallback = void Function(BuildContext context, String storeUrl);

typedef ForcedUpdateCallback =
    Future<bool?> Function(BuildContext context, String storeUrl);

typedef ErrorUpdateCallback =
    void Function(Object error, StackTrace? stackTrace);

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
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final FutureOr<String?> Function() fetchMinVesion;
  final FutureOr<String?> Function() fetchMinForcedVesion;
  final String iosAppStoreId;
  final UpdateCallback onUpdate;
  final ForcedUpdateCallback onForcedUpdate;
  final ErrorUpdateCallback? onException;
  final Widget child;

  @override
  State<AppUpdateWidget> createState() => _AppUpdateWidgetState();
}

class _AppUpdateWidgetState extends State<AppUpdateWidget>
    with WidgetsBindingObserver {
  bool isAlertVisible = false;

  late final AppUpdateNotifierClient appUpdateClient;

  Future<void> _evaluateAppUpdateRequirement() async {
    if (isAlertVisible) {
      return;
    }
    final updateState = await appUpdateClient.isAppUpdateRequired();
    if (updateState.needForcedUpdate && updateState.needUpdate) {
      return;
    }
    try {
      final storeUrl = await appUpdateClient.storeUrl();
      if (storeUrl == null) {
        return;
      }
      final ctx = widget.navigatorKey.currentContext ?? context;

      if (updateState.needUpdate && ctx.mounted) {
        widget.onUpdate.call(ctx, storeUrl);
      } else if (updateState.needForcedUpdate && ctx.mounted) {
        await _initiateForcedUpdate(storeUrl);
      }
    } on Object catch (e, st) {
      final handler = widget.onException;
      if (handler != null) {
        handler.call(e, st);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _initiateForcedUpdate(String storeUrl) async {
    final ctx = widget.navigatorKey.currentContext ?? context;

    isAlertVisible = true;
    final success = await widget.onForcedUpdate(ctx, storeUrl);

    isAlertVisible = false;
    if (success == null) {
      return _initiateForcedUpdate(storeUrl);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appUpdateClient = AppUpdateNotifierClient(
      fetchMinVersion: widget.fetchMinVesion,
      fetchMinForcedVersion: widget.fetchMinForcedVesion,
      iosAppStoreId: widget.iosAppStoreId,
    );
    _evaluateAppUpdateRequirement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateAppUpdateRequirement();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
