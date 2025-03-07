import 'dart:async';
import 'package:app_update_notifier/src/logic/logic.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

final class AppUpdateNotifierClient {
  factory AppUpdateNotifierClient({
    required String iosAppStoreId,
    required FutureOr<String?> Function() fetchMinVersion,
    required FutureOr<String?> Function() fetchMinForcedVersion,
  }) {
    return _instance ??= AppUpdateNotifierClient._privateConstructor(
      iosAppStoreId,
      fetchMinVersion,
      fetchMinForcedVersion,
    );
  }
  AppUpdateNotifierClient._privateConstructor(
    this.iosAppStoreId,
    this.fetchMinVersion,
    this.fetchMinForcedVersion,
  );

  static AppUpdateNotifierClient? _instance;

  final String iosAppStoreId;
  final FutureOr<String?> Function() fetchMinVersion;
  final FutureOr<String?> Function() fetchMinForcedVersion;

  static const _defaultVersion = '1.0.0';

  final _appUpdateNotifierState = const AppUpdateNotifierState.initial();

  bool _isSupportedPlatform() {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<AppUpdateNotifierState> isAppUpdateRequired() async {
    if (!_isSupportedPlatform()) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: false,
        needForcedUpdate: false,
      );
    }

    final minForcedVersion = await fetchMinForcedVersion.call();
    final minVersion = await fetchMinVersion.call();

    if (minForcedVersion == null ||
        minForcedVersion.isEmpty ||
        minVersion == null ||
        minVersion.isEmpty) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: false,
        needForcedUpdate: false,
      );
    }
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final currentVersionStr =
        RegExp(r'\d+\.\d+\.\d+').matchAsPrefix(currentVersion)?.group(0) ??
        _defaultVersion;

    final parsedMinForcedVersion = Version.parse(minForcedVersion);
    final parsedCurrentVersion = Version.parse(currentVersionStr);

    if (parsedCurrentVersion < parsedMinForcedVersion) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: false,
        needForcedUpdate: true,
      );
    }

    final parsedMinVersion = Version.parse(minVersion);

    if (parsedCurrentVersion < parsedMinVersion) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: true,
        needForcedUpdate: false,
      );
    }

    return _appUpdateNotifierState.copyWith(
      needUpdate: false,
      needForcedUpdate: false,
    );
  }

  Future<String?> storeUrl() async {
    if (_isSupportedPlatform()) {
      final packageInfo = await PackageInfo.fromPlatform();
      return switch (defaultTargetPlatform) {
        TargetPlatform.android =>
          'https://play.google.com/store/apps/details?id=${packageInfo.packageName}',
        TargetPlatform.iOS || TargetPlatform.macOS =>
          iosAppStoreId.isNotEmpty
              ? 'https://apps.apple.com/app/id$iosAppStoreId'
              : null,
        TargetPlatform.windows =>
          'https://www.microsoft.com/store/apps/${packageInfo.packageName}',
        _ => null,
      };
    }
    throw UnsupportedError('Unsupported platform');
  }
}
