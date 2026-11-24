import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../models/movie.dart';
import '../models/tmdb_movie_dto.dart';
import '../services/tmdb_movie_service.dart';
import '../services/tmdb_client.dart';
import 'load_phase.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel(this.service, {this.isSearch = false});
  final TmdbMovieService service;
  final bool isSearch;
  LoadPhase phase = LoadPhase.idle;
  List<Movie> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int>? selectedGenreIds;
  String query = '';
  String? errorMessage, nextPageError;
  bool isLoadingNext = false;
  int page = 0, totalPages = 0;
  int _generation = 0;
  CancelToken? _cancelToken;
  bool get hasNextPage => page > 0 && page < totalPages && page < 500;
  bool get isLoading => phase == LoadPhase.loading;
  List<Movie> get visibleMovies => movies;
  Future<void> search(String value) {
    query = value.trim();
    return reset();
  }

  /// Invalidates outstanding responses immediately, including during debounce.
  void invalidateSearch() {
    ++_generation;
    _cancelToken?.cancel();
    movies = const [];
    page = 0;
    totalPages = 0;
    isLoadingNext = false;
    errorMessage = null;
    nextPageError = null;
    phase = LoadPhase.idle;
    notifyIfAlive();
  }

  Future<void> selectGenres(List<int>? ids) {
    final normalized = ids?.where((id) => id > 0).toSet().toList() ?? <int>[];
    normalized.sort();
    selectedGenreIds = normalized.isEmpty
        ? null
        : List.unmodifiable(normalized);
    return reset();
  }

  Future<void> reset() async {
    if (isDisposed) return;
    ++_generation;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    movies = const [];
    page = 0;
    totalPages = 0;
    errorMessage = null;
    nextPageError = null;
    isLoadingNext = false;
    phase = isSearch && query.isEmpty ? LoadPhase.idle : LoadPhase.loading;
    notifyIfAlive();
    if (phase == LoadPhase.idle) return;
    await _fetch(1, _generation);
  }

  Future<void> loadNextPage() async {
    if (isDisposed || isLoading || isLoadingNext || !hasNextPage) return;
    isLoadingNext = true;
    nextPageError = null;
    notifyIfAlive();
    await _fetch(page + 1, _generation);
  }

  Future<void> _fetch(int requestedPage, int generation) async {
    final token = _cancelToken;
    try {
      if (genres.isEmpty) {
        final available = await service.fetchGenres(cancelToken: token);
        if (isDisposed || generation != _generation) return;
        genres = available;
      }
      final response = isSearch
          ? await service.searchMovies(
              query: query,
              page: requestedPage,
              cancelToken: token,
            )
          : await service.discoverMovies(
              page: requestedPage,
              genreIds: selectedGenreIds,
              cancelToken: token,
            );
      if (isDisposed || generation != _generation) return;
      if (response.page != requestedPage) {
        throw const FormatException('Unexpected page');
      }
      final unique = {for (final m in movies) m.id: m};
      for (final dto in response.results) {
        unique.putIfAbsent(dto.id, () => dto.toMovie(genres));
      }
      movies = List.unmodifiable(unique.values);
      page = requestedPage;
      totalPages = response.results.isEmpty
          ? page
          : response.totalPages.clamp(0, 500);
      phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (e) {
      if (isDisposed || generation != _generation) return;
      if (requestedPage == 1) {
        errorMessage = tmdbErrorMessage(e);
        phase = LoadPhase.error;
      } else {
        nextPageError = tmdbErrorMessage(e);
      }
    } finally {
      if (!isDisposed && generation == _generation) {
        isLoadingNext = false;
        notifyIfAlive();
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    _cancelToken?.cancel();
    super.dispose();
  }
}
