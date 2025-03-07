import 'package:app_update_notifier/src/logic/app_update_notifier_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUpdateNotifierState', () {
    test('supports value equality', () {
      expect(
        const AppUpdateNotifierState(needUpdate: true, needForcedUpdate: false),
        equals(
          const AppUpdateNotifierState(
            needUpdate: true,
            needForcedUpdate: false,
          ),
        ),
      );
    });

    test('initial state has correct values', () {
      const state = AppUpdateNotifierState.initial();
      expect(state.needUpdate, false);
      expect(state.needForcedUpdate, false);
    });

    test('copyWith returns a new instance with updated values', () {
      const state = AppUpdateNotifierState(
        needUpdate: true,
        needForcedUpdate: false,
      );
      final newState = state.copyWith(
        needUpdate: false,
        needForcedUpdate: true,
      );
      expect(newState.needUpdate, false);
      expect(newState.needForcedUpdate, true);
    });

    test('copyWith retains old values if not provided', () {
      const state = AppUpdateNotifierState(
        needUpdate: true,
        needForcedUpdate: false,
      );
      final newState = state.copyWith();
      expect(newState.needUpdate, true);
      expect(newState.needForcedUpdate, false);
    });

    test('toString returns correct string representation', () {
      const state = AppUpdateNotifierState(
        needUpdate: true,
        needForcedUpdate: false,
      );
      expect(
        state.toString(),
        'AppUpdateNotifierState(needUpdate: true, needForcedUpdate: false)',
      );
    });

    test('hashCode is correctly implemented', () {
      const state1 = AppUpdateNotifierState(
        needUpdate: true,
        needForcedUpdate: false,
      );
      const state2 = AppUpdateNotifierState(
        needUpdate: true,
        needForcedUpdate: false,
      );
      expect(state1.hashCode, state2.hashCode);
    });
  });
}
