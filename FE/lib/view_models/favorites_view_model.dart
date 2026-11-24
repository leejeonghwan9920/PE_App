import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../core/utils/map_bounded.dart';
import '../models/common_response.dart';
import '../models/favorite_list_item.dart';
import '../models/tmdb_movie_dto.dart';
import '../services/favorite_api_service.dart';
import '../services/tmdb_movie_service.dart';
import 'auth_session.dart';
import 'load_phase.dart';
import 'session_guard.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel(this._api, this._movies, AuthSession session)
    : guard = SessionGuard(session) {
    session.addListener(_sessionChanged);
  }
  final FavoriteApiService _api;
  final TmdbMovieService _movies;
  final SessionGuard guard;
  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  List<TmdbGenreDto> genres = const [];
  final Map<int, TmdbMovieDto> _movieCache = {};
  final Set<int> retrying = {};
  String? errorMessage;
  int _request = 0;
  bool get current => !isDisposed && guard.isCurrent;
  void _sessionChanged() {
    if (!guard.isCurrent) {
      ++_request;
      items = const [];
      _movieCache.clear();
      retrying.clear();
      phase = LoadPhase.idle;
      errorMessage = null;
      notifyIfAlive();
    }
  }

  Future<void> refresh() async {
    if (!current) return;
    final request = ++_request;
    phase = LoadPhase.loading;
    items = const [];
    errorMessage = null;
    retrying.clear();
    notifyIfAlive();
    try {
      final list = await _api.fetchFavorites();
      if (!current || request != _request) return;
      if (list.isNotEmpty && genres.isEmpty) {
        try {
          final available = await _movies.fetchGenres();
          if (!current || request != _request) return;
          genres = available;
        } catch (_) {
          /* Title and poster remain usable without genre labels. */
        }
      }
      final unique = {
        for (final favorite in list) favorite.movieId: favorite,
      }.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final joined = await mapBounded(unique, (favorite) async {
        TmdbMovieDto? movie = _movieCache[favorite.movieId];
        if (!current || request != _request) {
          return FavoriteListItem(favorite, null);
        }
        if (movie == null) {
          try {
            movie = await _movies.fetchMovieDetail(favorite.movieId);
          } catch (_) {
            /* Keep the failed card retryable. */
          }
        }
        if (current && request == _request && movie != null) {
          _movieCache[favorite.movieId] = movie;
        }
        return FavoriteListItem(favorite, movie);
      });
      if (!current || request != _request) return;
      items = List.unmodifiable(joined);
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (e) {
      if (!current || request != _request) return;
      errorMessage = ApiFailure.from(e, '즐겨찾기를 불러오지 못했습니다.').message;
      phase = LoadPhase.error;
    }
    notifyIfAlive();
  }

  Future<void> retryMovie(int movieId) async {
    if (!current || phase != LoadPhase.success || !retrying.add(movieId)) {
      return;
    }
    final request = _request;
    notifyIfAlive();
    try {
      final movie = await _movies.fetchMovieDetail(movieId);
      if (!current || request != _request) return;
      _movieCache[movieId] = movie;
      items = items
          .map(
            (item) => item.favorite.movieId == movieId
                ? FavoriteListItem(item.favorite, movie)
                : item,
          )
          .toList();
    } catch (_) {
      /* Preserve the placeholder and its retry button. */
    } finally {
      if (current && request == _request) {
        retrying.remove(movieId);
        notifyIfAlive();
      }
    }
  }

  @override
  void dispose() {
    guard.session.removeListener(_sessionChanged);
    super.dispose();
  }
}
