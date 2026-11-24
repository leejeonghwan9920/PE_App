import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_response_dto.dart';
import '../models/favorite_check_dto.dart';

class FavoriteApiService {
  FavoriteApiService(this.client);
  final Dio client;
  T _read<T>(Response response, int status, T Function(Object) decode) {
    if (response.statusCode != status ||
        response.data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected favorite response');
    }
    final result = CommonResponse<T>.fromJson(response.data, decode).result;
    if (result == null) throw const FormatException('Missing favorite result');
    return result;
  }

  Future<List<FavoriteResponseDto>> fetchFavorites() async => _read(
    await client.get('/v8/favorites'),
    200,
    (value) => (value as List)
        .map(
          (e) =>
              FavoriteResponseDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
  Future<FavoriteCheckDto> check(int movieId) async => _read(
    await client.get('/v8/favorites/$movieId'),
    200,
    (value) => FavoriteCheckDto.fromJson(
      movieId,
      Map<String, dynamic>.from(value as Map),
    ),
  );
  Future<FavoriteResponseDto> add(int movieId) async => _read(
    await client.post('/v8/favorites', data: {'movieId': movieId}),
    201,
    (value) =>
        FavoriteResponseDto.fromJson(Map<String, dynamic>.from(value as Map)),
  );
  Future<void> remove(int movieId) async {
    final response = await client.delete('/v8/favorites/$movieId');
    if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected delete response');
    }
    final parsed = CommonResponse<Object>.fromJson(
      response.data,
      (value) => value,
    );
    if (parsed.result != null) {
      throw const FormatException('Expected null result');
    }
  }
}
