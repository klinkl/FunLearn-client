import 'package:dio/dio.dart';
import '../models/modelQuest.dart';

//for testing
abstract class IQuestsApi {
  Future<List<ModelQuest>> getQuestsByUserId(String userId);
  Future<ModelQuest> getQuestById(String questId);
  Future<void> createQuest(ModelQuest quest);
  Future<void> updateQuest(ModelQuest quest);
}

class QuestsApi implements IQuestsApi {
  final Dio _dio;
  QuestsApi(this._dio);

  @override
  Future<List<ModelQuest>> getQuestsByUserId(String userId) async {
    final res = await _dio.get('/api/quests/user/$userId');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => ModelQuest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ModelQuest> getQuestById(String questId) async {
    final res = await _dio.get('/api/quests/$questId');
    return ModelQuest.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> createQuest(ModelQuest quest) async {
    await _dio.post('/api/quests/', data: quest.toJson());
  }

  @override
  Future<void> updateQuest(ModelQuest quest) async {
    await _dio.put('/api/quests/', data: quest.toJson());
  }
}
