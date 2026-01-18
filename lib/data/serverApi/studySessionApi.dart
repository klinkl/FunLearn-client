import 'package:dio/dio.dart';
import '../models/studySession.dart';

class StudySessionApi {
  final Dio _dio;
  StudySessionApi(this._dio);

  Future<void> createStudySession(StudySession session) async {
    await _dio.post('/api/studysessions/', data: session.toJson());
  }
}
