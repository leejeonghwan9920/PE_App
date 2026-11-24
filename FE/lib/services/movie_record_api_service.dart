import 'package:dio/dio.dart';

import '../models/movie_record.dart';
import '../models/common_response.dart';

class MovieRecordApiService {
  MovieRecordApiService(this.client);
  final Dio client;
  Future<MovieRecordResult> create(MovieRecordRequest request) async {
    final response = await client.post<Map<String, dynamic>>(
      '/v8/movie-records',
      data: request.toJson(),
    );
    if (response.statusCode != 201 || response.data == null) {
      throw const FormatException('Unexpected movie record response');
    }
    final result = CommonResponse<MovieRecordResult>.fromJson(
      response.data!,
      (value) =>
          MovieRecordResult.fromJson(Map<String, dynamic>.from(value as Map)),
    ).result;
    if (result == null) throw const FormatException('Missing movie record');
    return result;
  }
}
