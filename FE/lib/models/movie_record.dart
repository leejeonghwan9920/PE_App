import 'favorite_response_dto.dart';
import 'rating_dto.dart';
import 'rating_request.dart';

class MovieRecordRequest {
  const MovieRecordRequest(this.movieId, this.input, this.addToFavorites);
  final int movieId;
  final RatingInput input;
  final bool addToFavorites;
  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': input.score,
    if (input.comment != null) 'comment': input.comment,
    'addToFavorites': addToFavorites,
  };
}

class MovieRecordResult {
  const MovieRecordResult(this.rating, this.favorite);
  final RatingDto rating;
  final FavoriteResponseDto? favorite;
  factory MovieRecordResult.fromJson(Map<String, dynamic> json) =>
      MovieRecordResult(
        RatingDto.fromJson(Map<String, dynamic>.from(json['rating'] as Map)),
        json['favorite'] == null
            ? null
            : FavoriteResponseDto.fromJson(
                Map<String, dynamic>.from(json['favorite'] as Map),
              ),
      );
}
