import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indexes of the bottom-navigation destinations.
abstract final class ShellTabs {
  static const int home = 0;
  static const int log = 1;
  static const int analyze = 2;
  static const int profile = 3;
}

/// Which tab the shell shows. Pages can switch tabs through this.
class ShellTab extends Notifier<int> {
  @override
  int build() => ShellTabs.home;

  void select(int index) => state = index;
}

final shellTabProvider = NotifierProvider<ShellTab, int>(ShellTab.new);
