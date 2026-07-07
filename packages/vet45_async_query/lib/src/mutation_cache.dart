import 'mutation.dart';
import 'mutation_context.dart';
import 'mutation_options.dart';
import 'notify_scheduler.dart';

/// Registry of active [Mutation] instances.
class MutationCache {
  MutationCache({NotifyScheduler? scheduler})
      : _scheduler = scheduler ?? NotifyScheduler();

  final NotifyScheduler _scheduler;
  final _mutations = <String, Mutation<dynamic, dynamic>>{};

  Mutation<TData, TVariables> buildMutation<TData, TVariables>({
    required MutationOptions<TData, TVariables> options,
    required MutationContext context,
  }) {
    final key = options.mutationKey?.join('|') ??
        'mutation_${DateTime.now().microsecondsSinceEpoch}';

    final existing = _mutations[key];
    if (existing != null) {
      return existing as Mutation<TData, TVariables>;
    }

    final mutation = Mutation<TData, TVariables>(
      options: options,
      context: context,
      scheduler: _scheduler,
    );
    _mutations[key] = mutation;
    return mutation;
  }

  void remove(Mutation<dynamic, dynamic> mutation) {
    _mutations.removeWhere((_, value) => identical(value, mutation));
    mutation.dispose();
  }

  void clear() {
    for (final mutation in _mutations.values) {
      mutation.dispose();
    }
    _mutations.clear();
  }

  void dispose() {
    clear();
    _scheduler.dispose();
  }
}
