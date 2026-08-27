import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds one piece of throwaway UI state — a search string, a selected filter,
/// which nav section is open.
///
/// Riverpod 3 moved `StateProvider` into `legacy.dart`; this is the same idea
/// on the supported `Notifier` API, without pulling the legacy import into
/// every screen.
class UiValue<T> extends Notifier<T> {
  UiValue(this.initial);

  final T initial;

  @override
  T build() => initial;

  void set(T value) => state = value;
}

NotifierProvider<UiValue<T>, T> uiValue<T>(T initial) =>
    NotifierProvider<UiValue<T>, T>(() => UiValue<T>(initial));
