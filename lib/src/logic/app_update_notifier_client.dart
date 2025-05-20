import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_update_notifier/src/logic/logic.dart';
import 'package:flutter_app_update_notifier/src/utils/callbacks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class AppUpdateNotifierClient {
  factory AppUpdateNotifierClient({
    required String iosAppStoreId,
    required int optionalUpdateTriggerCount,
    required FetchMinVersionCallback fetchMinVersion,
    required FetchMinForcedVersionCallback fetchMinForcedVersion,
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
  final FetchMinVersionCallback fetchMinVersion;
  final FetchMinForcedVersionCallback fetchMinForcedVersion;

  static const _defaultVersion = '1.0.0';
  static const _optionalUpdateTriggerShownCountKey =
      'optional_update_trigger_shown_count_key';
  static final _semanicVersionPattern = RegExp(r'^\d+\.\d+\.\d+');

  final _appUpdateNotifierState = const AppUpdateNotifierState.initial();
  final _sharedPreferencesAsync = SharedPreferencesAsync();

  bool _isSupportedPlatform() =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  Future<Version> _getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionStr = _extractSemverString(packageInfo.version);
    return Version.parse(currentVersionStr);
  }

  String _extractSemverString(String versionString) {
    return _semanicVersionPattern.matchAsPrefix(versionString)?.group(0) ??
        _defaultVersion;
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

    if (_isVersionInfoMissing(minForcedVersionStr, minVersionStr)) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: false,
        needForcedUpdate: false,
      );
    }

    final currentVersion = await _getCurrentAppVersion();
    final minForcedVersion = Version.parse(minForcedVersionStr!);
    final minVersion = Version.parse(minVersionStr!);

    if (currentVersion < minForcedVersion) {
      return _appUpdateNotifierState.copyWith(
        needUpdate: false,
        needForcedUpdate: true,
      );
    }

    return _handleOptionalUpdate(currentVersion, minVersion);
  }

  bool _isVersionInfoMissing(
    String? minForcedVersionStr,
    String? minVersionStr,
  ) {
    return minForcedVersionStr == null ||
        minForcedVersionStr.isEmpty ||
        minVersionStr == null ||
        minVersionStr.isEmpty;
  }

  Future<AppUpdateNotifierState> _handleOptionalUpdate(
    Version currentVersion,
    Version minVersion,
  ) async {
    final optionalUpdateTriggerShown = await _sharedPreferencesAsync.getInt(
          _optionalUpdateTriggerShownCountKey,
        ) ??
        0;

    if (currentVersion <= minVersion && optionalUpdateTriggerShown > 0) {
      await _sharedPreferencesAsync.setInt(
        _optionalUpdateTriggerShownCountKey,
        0,
      );
    }

    final shouldShowOptionalUpdate = _shouldShowOptionalUpdateNotification(
      currentVersion,
      minVersion,
      optionalUpdateTriggerShown,
    );

    if (shouldShowOptionalUpdate) {
      await _incrementOptionalUpdateCounter(optionalUpdateTriggerShown);
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

  bool _shouldShowOptionalUpdateNotification(
    Version currentVersion,
    Version minVersion,
    int shownCount,
  ) {
    final belowCountLimit =
        shownCount == 0 || shownCount < optionalUpdateTriggerCount;
    return belowCountLimit && currentVersion < minVersion;
  }

  Future<void> _incrementOptionalUpdateCounter(int currentCount) async {
    if (optionalUpdateTriggerCount > 0) {
      _sharedPreferencesAsync
          .setInt(
            _optionalUpdateTriggerShownCountKey,
            currentCount + 1,
          )
          .ignore();
    }
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
