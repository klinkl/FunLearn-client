import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/serverApi/apiClient.dart';
import '../data/serverApi/usersApi.dart';

class ApiTestScreen extends StatelessWidget {
  ApiTestScreen({super.key});

  final client = ApiClient(baseUrl: 'http://localhost:8080');
  late final usersApi = UsersApi(client.dio);

  Future<void> testUserApi() async {
    final user = User(username: "TestUser");
    await usersApi.createUser(user);

    final fetched = await usersApi.getUserById(user.userId);
    debugPrint("User from server: ${fetched.username} (${fetched.userId})");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await testUserApi();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Test OK')));
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          child: const Text('Test USER API'),
        ),
      ),
    );
  }
}
