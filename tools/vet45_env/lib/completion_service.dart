import 'manifest.dart';

/// Generates shell completion scripts for the `vet45` CLI.
class CompletionService {
  CompletionService({required this.manifest});

  final EnvManifest manifest;

  static const topLevelCommands = [
    'init',
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
    'completion',
  ];

  static const profileSubcommands = ['list', 'use', 'init'];
  static const runTargets = ['erp', 'worker'];
  static const completionShells = ['bash', 'zsh'];
  static const commonFlags = [
    '--profile',
    '--env',
    '--target',
    '--skip-link',
    '--offline',
    '--force',
    '--help',
  ];

  List<String> get profileIds => manifest.profiles.profiles.keys.toList()..sort();

  List<String> get environmentIds => manifest.environments.keys.toList()..sort();

  List<String> get targetIds => manifest.targets.keys.toList()..sort();

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
    run)
      if [ "\$cword" -eq 2 ]; then
        COMPREPLY=( \$(compgen -W "${runTargets.join(' ')}" -- "\$cur") )
      fi
      ;;
    switch|use|use-and-sync|sync|link|doctor|supabase)
      if [[ "\$cur" == -* ]]; then
        COMPREPLY=( \$(compgen -W "$flags" -- "\$cur") )
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

    return '''
# Vet45 zsh completion — eval "\\\$(vet45 completion zsh)"
#compdef vet45

_vet45() {
  local -a commands profiles environments targets flags profile_cmds run_targets shells
  commands=($commands)
  profiles=($profiles)
  environments=($environments)
  targets=($targets)
  flags=($flags)
  profile_cmds=(${profileSubcommands.map((c) => "'$c'").join(' ')})
  run_targets=(${runTargets.map((t) => "'$t'").join(' ')})
  shells=(${completionShells.map((s) => "'$s'").join(' ')})

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
        run)
          case \$CURRENT in
            3) _describe 'run target' run_targets ;;
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
