import 'package:app_update_notifier/src/logic/logic.dart';
import 'package:flutter/material.dart';

typedef UpdateWidgetCallback =
    void Function(BuildContext context, String storeUrl);

typedef ForcedUpdateWidgetCallback =
    Future<bool?> Function(BuildContext context, String storeUrl);

typedef ErrorUpdateWidgetCallback =
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
  final FetchMinVersion fetchMinVesion;
  final FetchMinForcedVersion fetchMinForcedVesion;
  final String iosAppStoreId;
  final UpdateWidgetCallback onUpdate;
  final ForcedUpdateWidgetCallback onForcedUpdate;
  final ErrorUpdateWidgetCallback? onException;
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
      fetchMinVesion: widget.fetchMinVesion,
      fetchMinForcedVesion: widget.fetchMinForcedVesion,
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
