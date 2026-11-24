import '../models/movie.dart';
import '../services/movie_list_preferences.dart';
import 'movie_home_view_model.dart';
import 'paged_movies_view_model.dart';
import 'load_phase.dart';

class MovieListViewModel extends PagedMoviesViewModel {
  MovieListViewModel(
    super.service, {
    this.preferences = const SharedPreferencesMovieListPreferences(),
  });
  final MovieListPreferences preferences;
  MovieSortOption sortOption = MovieSortOption.latest;
  bool _initialized = false;
  int get failureRevision => 0;
  MovieLoadStatus get status => switch (phase) {
    LoadPhase.idle => MovieLoadStatus.idle,
    LoadPhase.loading => MovieLoadStatus.loading,
    LoadPhase.success => MovieLoadStatus.success,
    LoadPhase.empty => MovieLoadStatus.empty,
    LoadPhase.error => MovieLoadStatus.error,
  };
  @override
  List<Movie> get visibleMovies {
    final result = [...movies];
    switch (sortOption) {
      case MovieSortOption.latest:
        result.sort((a, b) => b.year.compareTo(a.year));
      case MovieSortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case MovieSortOption.title:
        result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }

  Future<void> initialize({List<int>? genreIds}) async {
    if (_initialized || isDisposed) return;
    _initialized = true;
    try {
      final saved = await preferences.read();
      if (isDisposed) return;
      sortOption = saved.sortOption;
      var ids = genreIds;
      if (ids == null) {
        final available = await service.fetchGenres();
        if (isDisposed) return;
        genres = available;
        final names = {for (final g in available) g.name: g.id};
        ids = saved.genres
            .map((g) => int.tryParse(g) ?? names[g])
            .whereType<int>()
            .toList();
      }
      final normalized = ids.where((id) => id > 0).toSet().toList()..sort();
      selectedGenreIds = normalized.isEmpty ? null : normalized;
    } catch (_) {
      selectedGenreIds = genreIds;
    }
    if (!isDisposed) await reset();
  }

  @override
  Future<void> selectGenres(List<int>? ids) async {
    final request = super.selectGenres(ids);
    try {
      await preferences.saveGenres(ids?.map((id) => '$id').toSet() ?? {});
    } catch (_) {}
    await request;
  }

  Future<void> setSortOption(MovieSortOption value) async {
    sortOption = value;
    notifyIfAlive();
    try {
      await preferences.saveSortOption(value);
    } catch (_) {}
  }

  Future<void> load({bool clearWhileLoading = false}) =>
      isLoading ? Future.value() : reset();
}
