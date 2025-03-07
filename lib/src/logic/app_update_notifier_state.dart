import 'package:flutter/foundation.dart';

@immutable
class AppUpdateNotifierState {
  const AppUpdateNotifierState({
    required this.needUpdate,
    required this.needForcedUpdate,
  });

  const AppUpdateNotifierState.initial()
    : this(needUpdate: false, needForcedUpdate: false);

  final bool needUpdate;
  final bool needForcedUpdate;

  AppUpdateNotifierState copyWith({bool? needUpdate, bool? needForcedUpdate}) {
    return AppUpdateNotifierState(
      needUpdate: needUpdate ?? this.needUpdate,
      needForcedUpdate: needForcedUpdate ?? this.needForcedUpdate,
    );
  }

  @override
  String toString() =>
      'AppUpdateNotifierState(needUpdate: $needUpdate, '
      'needForcedUpdate: $needForcedUpdate)';

  @override
  bool operator ==(covariant AppUpdateNotifierState other) {
    if (identical(this, other)) return true;

    return other.needUpdate == needUpdate &&
        other.needForcedUpdate == needForcedUpdate;
  }

  @override
  int get hashCode => needUpdate.hashCode ^ needForcedUpdate.hashCode;
}
