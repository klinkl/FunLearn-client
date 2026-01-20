import 'package:dio/dio.dart';
import '../models/user.dart';

class UsersApi {
  final Dio _dio;
  UsersApi(this._dio);

  Future<User> getUserById(String id) async {
    final res = await _dio.get('/api/users/$id');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<User>> getAllUsers() async {
    final res = await _dio.get('/api/users/');
    final data = res.data as List<dynamic>;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createUser(User user) async {
    await _dio.post('/api/users/', data: user.toJson());
  }

  Future<void> updateUser(User user) async {
    await _dio.put('/api/users/', data: user.toJson());
  }
}
