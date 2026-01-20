import 'package:dio/dio.dart';
import '../models/studySession.dart';

abstract class IStudySessionApi {
  Future<void> createStudySession(StudySession session);
}

class StudySessionApi implements IStudySessionApi {
  final Dio _dio;
  StudySessionApi(this._dio);

  @override
  Future<void> createStudySession(StudySession session) async {
    await _dio.post('/api/studysessions/', data: session.toJson());
  }
}
