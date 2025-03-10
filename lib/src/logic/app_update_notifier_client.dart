import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_update_notifier/src/logic/logic.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class AppUpdateNotifierClient {
  factory AppUpdateNotifierClient({
    required String iosAppStoreId,
    required int optionalUpdateTriggerCount,
    required FutureOr<String?> Function() fetchMinVersion,
    required FutureOr<String?> Function() fetchMinForcedVersion,
  }) {
    assert(
      optionalUpdateTriggerCount >= 0,
      'optionalUpdateTriggerCount must be 0 or a positive value',
    );
    return _instance ??= AppUpdateNotifierClient._privateConstructor(
      iosAppStoreId,
      optionalUpdateTriggerCount,
      fetchMinVersion,
      fetchMinForcedVersion,
    );
  }

  AppUpdateNotifierClient._privateConstructor(
    this.iosAppStoreId,
    this.optionalUpdateTriggerCount,
    this.fetchMinVersion,
    this.fetchMinForcedVersion,
  );

  static AppUpdateNotifierClient? _instance;

  final String iosAppStoreId;
  final int optionalUpdateTriggerCount;
  final FutureOr<String?> Function() fetchMinVersion;
  final FutureOr<String?> Function() fetchMinForcedVersion;

  static const _defaultVersion = '1.0.0';
  static const _optionalUpdateTriggerShownCountKey =
      'optional_update_trigger_shown_count_key';

  final _appUpdateNotifierState = const AppUpdateNotifierState.initial();
  final _sharedPreferencesAsync = SharedPreferencesAsync();

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

    final minForcedVersionStr = await fetchMinForcedVersion.call();
    final minVersionStr = await fetchMinVersion.call();

    if (minForcedVersionStr == null ||
        minForcedVersionStr.isEmpty ||
        minVersionStr == null ||
        minVersionStr.isEmpty) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: false,
        needForcedUpdate: false,
      );
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionStr =
        RegExp(r'\d+\.\d+\.\d+').matchAsPrefix(packageInfo.version)?.group(0) ??
            _defaultVersion;

    final currentVersion = Version.parse(currentVersionStr);
    final minForcedVersion = Version.parse(minForcedVersionStr);
    final minVersion = Version.parse(minVersionStr);

    if (currentVersion < minForcedVersion) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: false,
        needForcedUpdate: true,
      );
    }

    final optionalUpdateTriggerShown = await _sharedPreferencesAsync.getInt(
          _optionalUpdateTriggerShownCountKey,
        ) ??
        0;

    final shouldShowOptionalUpdate = (optionalUpdateTriggerShown == 0 ||
            optionalUpdateTriggerShown < optionalUpdateTriggerCount) &&
        currentVersion < minVersion;

    if (shouldShowOptionalUpdate) {
      if (optionalUpdateTriggerCount > 0) {
        _sharedPreferencesAsync
            .setInt(
              _optionalUpdateTriggerShownCountKey,
              optionalUpdateTriggerShown + 1,
            )
            .ignore();
      }

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
        TargetPlatform.iOS || TargetPlatform.macOS => iosAppStoreId.isNotEmpty
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
