class FavoriteCheckDto {
  const FavoriteCheckDto(this.movieId, this.isFavorite);
  final int movieId;
  final bool isFavorite;
  factory FavoriteCheckDto.fromJson(int movieId, Map<String, dynamic> json) =>
      FavoriteCheckDto(movieId, json['isFavorite'] as bool);
}
