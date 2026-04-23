import 'package:flutter/material.dart';

/// Global notifier to trigger HomeContent refresh without rebuilding the screen
final homeRefreshNotifier = ValueNotifier<int>(0);

void triggerHomeRefresh() {
  homeRefreshNotifier.value++;
}
