import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/ui_state.dart';
import 'floor_view.dart';
import 'order_view.dart';

/// The bill this terminal currently has open. Null means we are on the floor.
final activeOrderIdProvider = uiValue<String?>(null);

class PosShell extends ConsumerWidget {
  const PosShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = ref.watch(activeOrderIdProvider);

    return AnimatedSwitcher(
      duration: Motion.fast,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      child: orderId == null
          ? const FloorView(key: ValueKey('floor'))
          : OrderView(key: ValueKey('order'), orderId: orderId),
    );
  }
}
