import 'manifest.dart';

/// Generates shell completion scripts for the `vet45` CLI.
class CompletionService {
  CompletionService({required this.manifest});

  final EnvManifest manifest;

  static const topLevelCommands = [
    'tui',
    'init',
    'example',
    'list',
    'switch',
    'use',
    'use-and-sync',
    'use-sync-run',
    'sync',
    'link',
    'doctor',
    'run',
    'resolve',
    'resolve-shell',
    'active',
    'status',
    'profile',
    'supabase',
    'admin',
    'completion',
  ];

  static const profileSubcommands = ['list', 'use', 'init'];
  static const adminSubcommands = ['create', 'grant', 'list'];
  static const completionShells = ['bash', 'zsh'];
  static const commonFlags = [
    '--profile',
    '--env',
    '--target',
    '--skip-link',
    '--offline',
    '--force',
    '--check',
    '--help',
    '--email',
    '--password',
    '--user-id',
    '--yes',
  ];

  List<String> get profileIds => manifest.profiles.profiles.keys.toList()..sort();

  List<String> get environmentIds => manifest.environments.keys.toList()..sort();

  List<String> get targetIds => manifest.targets.keys.toList()..sort();

  /// Writable app targets (excludes secrets-only targets like deploy).
  List<String> get runTargets => manifest.targets.entries
      .where((e) => e.value.writeEnvFile && e.value.actions.isNotEmpty)
      .map((e) => e.key)
      .toList()
    ..sort();

  Map<String, List<String>> get runActionsByTarget {
    final map = <String, List<String>>{};
    for (final entry in manifest.targets.entries) {
      if (entry.value.actions.isEmpty) {
        continue;
      }
      map[entry.key] = entry.value.actions.keys.toList()..sort();
    }
    return map;
  }

  String render(String shell) {
    switch (shell) {
      case 'bash':
        return _renderBash();
      case 'zsh':
        return _renderZsh();
      default:
        throw ArgumentError('Unsupported shell: $shell (use bash or zsh)');
    }
  }

  String _renderBash() {
    final profiles = profileIds.join(' ');
    final environments = environmentIds.join(' ');
    final targets = targetIds.join(' ');
    final commands = topLevelCommands.join(' ');
    final flags = commonFlags.join(' ');
    final actionCases = runActionsByTarget.entries
        .map(
          (e) => '''
        ${e.key})
          COMPREPLY=( \$(compgen -W "${e.value.join(' ')}" -- "\$cur") )
          ;;''',
        )
        .join('\n');

    return '''
# Vet45 bash completion — eval "\\\$(vet45 completion bash)"
_vet45() {
  local cur prev words cword
  cur="\${COMP_WORDS[COMP_CWORD]}"
  prev="\${COMP_WORDS[COMP_CWORD-1]}"
  cword=\$COMP_CWORD
  words=("\${COMP_WORDS[@]}")

  case "\${words[1]}" in
    completion)
      COMPREPLY=( \$(compgen -W "${completionShells.join(' ')}" -- "\$cur") )
      ;;
    profile)
      if [ "\$cword" -eq 2 ]; then
        COMPREPLY=( \$(compgen -W "${profileSubcommands.join(' ')}" -- "\$cur") )
      elif [ "\$prev" = "use" ] || [ "\$prev" = "init" ]; then
        COMPREPLY=( \$(compgen -W "$profiles" -- "\$cur") )
      fi
      ;;
    admin)
      if [ "\$cword" -eq 2 ]; then
        COMPREPLY=( \$(compgen -W "${adminSubcommands.join(' ')}" -- "\$cur") )
      elif [[ "\$cur" == -* ]]; then
        COMPREPLY=( \$(compgen -W "$flags" -- "\$cur") )
      elif [ "\$prev" = "--env" ]; then
        COMPREPLY=( \$(compgen -W "$environments" -- "\$cur") )
      elif [ "\$prev" = "--profile" ]; then
        COMPREPLY=( \$(compgen -W "$profiles" -- "\$cur") )
      fi
      ;;
    run)
      if [ "\$cword" -eq 2 ]; then
        COMPREPLY=( \$(compgen -W "${runTargets.join(' ')}" -- "\$cur") )
      elif [ "\$cword" -eq 3 ]; then
        case "\${words[2]}" in
$actionCases
        esac
      fi
      ;;
    switch|use|use-and-sync|sync|link|doctor|supabase)
      if [[ "\$cur" == -* ]]; then
        COMPREPLY=( \$(compgen -W "$flags" -- "\$cur") )
      elif [ "\$prev" = "--target" ]; then
        COMPREPLY=( \$(compgen -W "$targets" -- "\$cur") )
      elif [ "\$cword" -eq 2 ]; then
        COMPREPLY=( \$(compgen -W "$profiles $environments" -- "\$cur") )
      elif [ "\$cword" -eq 3 ]; then
        COMPREPLY=( \$(compgen -W "$environments" -- "\$cur") )
      fi
      ;;
    *)
      if [ "\$cword" -eq 1 ]; then
        COMPREPLY=( \$(compgen -W "$commands" -- "\$cur") )
      fi
      ;;
  esac
}
complete -F _vet45 vet45
''';
  }

  String _renderZsh() {
    final profiles = profileIds.map((id) => "'$id'").join(' ');
    final environments = environmentIds.map((id) => "'$id'").join(' ');
    final targets = targetIds.map((id) => "'$id'").join(' ');
    final commands = topLevelCommands.map((c) => "'$c'").join(' ');
    final flags = commonFlags.map((f) => "'$f'").join(' ');

    final actionGroups = runActionsByTarget.entries
        .map(
          (e) =>
              "  '${e.key}': (${e.value.map((a) => "'$a'").join(' ')})",
        )
        .join('\n');

    return '''
# Vet45 zsh completion — eval "\\\$(vet45 completion zsh)"
#compdef vet45

_vet45() {
  local -a commands profiles environments targets flags profile_cmds admin_cmds run_targets shells
  local -A run_actions
  commands=($commands)
  profiles=($profiles)
  environments=($environments)
  targets=($targets)
  flags=($flags)
  profile_cmds=(${profileSubcommands.map((c) => "'$c'").join(' ')})
  admin_cmds=(${adminSubcommands.map((c) => "'$c'").join(' ')})
  run_targets=(${runTargets.map((t) => "'$t'").join(' ')})
  shells=(${completionShells.map((s) => "'$s'").join(' ')})

$actionGroups

  _arguments -C \\
    '1:command:->command' \\
    '*::arg:->args'

  case \$state in
    command)
      _describe 'vet45 command' commands
      ;;
    args)
      case \$words[1] in
        completion)
          _describe 'shell' shells
          ;;
        profile)
          case \$CURRENT in
            3) _describe 'profile subcommand' profile_cmds ;;
            4) _describe 'profile id' profiles ;;
          esac
          ;;
        admin)
          case \$CURRENT in
            3) _describe 'admin subcommand' admin_cmds ;;
            *)
              if [[ \$words[\$CURRENT] == -* ]]; then
                _describe 'flag' flags
              elif [[ \$words[\$CURRENT-1] == '--env' ]]; then
                _describe 'environment' environments
              elif [[ \$words[\$CURRENT-1] == '--profile' ]]; then
                _describe 'profile id' profiles
              fi
              ;;
          esac
          ;;
        run)
          case \$CURRENT in
            3) _describe 'run target' run_targets ;;
            4)
              local -a actions
              actions=( \${run_actions[\$words[2]]} )
              _describe 'run action' actions
              ;;
          esac
          ;;
        switch|use|use-and-sync|sync|link|doctor|supabase)
          if [[ \$words[\$CURRENT] == -* ]]; then
            _describe 'flag' flags
          elif (( CURRENT == 3 )); then
            _describe 'profile or environment' profiles environments
          elif (( CURRENT == 4 )); then
            _describe 'environment' environments
          fi
          ;;
      esac
      ;;
  esac
}
''';
  }
}
