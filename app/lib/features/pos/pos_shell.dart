import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/ui_state.dart';
import '../../data/offline/pending_writes.dart';
import 'floor_view.dart';
import 'order_view.dart';

/// The bill this terminal currently has open. Null means we are on the floor.
final activeOrderIdProvider = uiValue<String?>(null);

class PosShell extends ConsumerWidget {
  const PosShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the queue draining wherever a till is open, rather than depending
    // on someone being on a particular screen when the wi-fi comes back.
    ref.watch(queueFlusherProvider);

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
