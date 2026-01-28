import 'package:dio/dio.dart';
import 'package:funlearn_client/data/models/friendRequest.dart';
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
  Future<void> sendFriendRequest(FriendRequest request) async {
    await _dio.post('/api/users/friend/', data: request.toJson());
  }
  Future<void> updateFriendRequest(FriendRequest request) async {
    await _dio.put('/api/users/friend/', data: request.toJson());
  }
  Future<void> deleteFriendRequest(FriendRequest request) async {
    await _dio.delete('/api/users/friend/', data: request.toJson());
  }
  Future<List<FriendRequest>> getSent(String id) async {
    final res = await _dio.get('/api/users/friend/sent/$id');
    final data = res.data as List<dynamic>;
    return data.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<List<FriendRequest>> getReceived(String id) async {
    final res = await _dio.get('/api/users/friend/received/$id');
    final data = res.data as List<dynamic>;
    return data.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }
}
