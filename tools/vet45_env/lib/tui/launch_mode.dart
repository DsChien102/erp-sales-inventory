/// How `vet45` should launch based on argv.
enum LaunchMode { tui, help, cli }

/// Parse top-level launch mode. Empty args and `tui` open the TUI.
LaunchMode parseLaunchMode(List<String> args) {
  if (args.isEmpty) {
    return LaunchMode.tui;
  }
  final first = args.first;
  if (first == '--help' || first == '-h') {
    return LaunchMode.help;
  }
  if (first == 'tui') {
    return LaunchMode.tui;
  }
  return LaunchMode.cli;
}
