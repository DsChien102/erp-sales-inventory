import 'package:async_query/async_query.dart';
import 'package:async_query_flutter/async_query_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  final client = QueryClient(
    options: const QueryClientOptions(
      queries: QueryOptionsDefaults(
        staleTime: Duration(seconds: 30),
        gcTime: Duration(minutes: 5),
      ),
    ),
  );

  runApp(AsyncQueryExampleApp(client: client));
}

class AsyncQueryExampleApp extends StatelessWidget {
  const AsyncQueryExampleApp({required this.client, super.key});

  final QueryClient client;

  @override
  Widget build(BuildContext context) {
    return QueryClientProvider(
      client: client,
      child: AppLifecycleRefetch(
        child: MaterialApp(
          title: 'async_query example',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          home: const UserListPage(),
        ),
      ),
    );
  }
}

class User {
  const User({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;
}

/// In-memory fake API for demo purposes.
class FakeUserApi {
  FakeUserApi() {
    _users = List.generate(
      12,
      (index) => User(
        id: index + 1,
        name: 'User ${index + 1}',
        email: 'user${index + 1}@example.com',
      ),
    );
  }

  late List<User> _users;
  int _detailFetchCount = 0;
  int _listFetchCount = 0;

  int get listFetchCount => _listFetchCount;
  int get detailFetchCount => _detailFetchCount;

  Future<List<User>> fetchUsers() async {
    _listFetchCount++;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List<User>.from(_users);
  }

  Future<User> fetchUser(int id) async {
    _detailFetchCount++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _users.firstWhere((user) => user.id == id);
  }

  Future<User> createUser(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final user = User(
      id: _users.length + 1,
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '')}@example.com',
    );
    _users = [..._users, user];
    return user;
  }
}

final _api = FakeUserApi();

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'List fetches: ${_api.listFetchCount} | '
                    'Detail fetches: ${_api.detailFetchCount}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: UseQuery<List<User>>(
        queryKey: const ['users'],
        queryFn: _api.fetchUsers,
        staleTime: const Duration(seconds: 30),
        builder: (context, result) {
          if (result.isLoading && !result.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (result.isError) {
            return Center(child: Text('Error: ${result.error}'));
          }

          final users = result.data ?? [];
          return RefreshIndicator(
            onRefresh: () => result.refetch(),
            child: ListView.separated(
              itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: result.isRefetching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => UserDetailPage(userId: user.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create user'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            UseMutation<User, String>(
              mutationFn: _api.createUser,
              onSuccess: (data, variables, ctx) async {
                await ctx.client.invalidateQueries(queryKey: const ['users']);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              builder: (context, mutation) {
                return FilledButton(
                  onPressed: mutation.isPending
                      ? null
                      : () => mutation.mutate(controller.text),
                  child: mutation.isPending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User #$userId')),
      body: UseQuery<User>(
        queryKey: ['users', userId],
        queryFn: () => _api.fetchUser(userId),
        staleTime: const Duration(seconds: 30),
        builder: (context, result) {
          if (!result.hasData && !result.isError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.isError) {
            return Center(child: Text('Error: ${result.error}'));
          }

          final user = result.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(user.email),
                const SizedBox(height: 24),
                if (result.isRefetching)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Refreshing...'),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
