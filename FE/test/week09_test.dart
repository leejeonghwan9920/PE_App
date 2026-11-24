import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/models/common_response.dart';
import 'package:movielog/models/favorite_response_dto.dart';
import 'package:movielog/models/tmdb_movie_dto.dart';
import 'package:movielog/models/movie_record.dart';
import 'package:movielog/models/rating_request.dart';
import 'package:movielog/services/auth_api_service.dart';
import 'package:movielog/services/favorite_api_service.dart';
import 'package:movielog/services/movie_record_api_service.dart';
import 'package:movielog/services/movie_log_client.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/services/token_storage.dart';
import 'package:movielog/view_models/auth_session.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/screens/movie_search_screen.dart';
import 'package:movielog/widgets/rating_dialog.dart';

class Session extends AuthSession {
  Session() : super(AuthApiService(Dio()), const TokenStorage());
  int revision = 1, expirations = 0;
  bool active = true;
  @override
  bool get signedIn => active;
  @override
  String? get token => active ? 'test-session-token' : null;
  @override
  int get generation => revision;
  @override
  bool isCurrent(int generation) => generation == revision;
  @override
  Future<void> expire(int generation) async {
    if (!isCurrent(generation) || !active) return;
    expirations++;
    change();
  }

  void change() {
    revision++;
    active = false;
    notifyListeners();
  }
}

class Movies extends TmdbMovieService {
  Movies() : super(Dio());
  final requests = <({int page, String query, List<int>? genres})>[];
  Future<TmdbMoviePageDto> Function(int, String, List<int>?)? reply;
  final failDetails = <int>{};
  int inFlight = 0, maxInFlight = 0;
  @override
  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async =>
      const [];
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
    CancelToken? cancelToken,
  }) {
    requests.add((page: page, query: '', genres: genreIds));
    return reply!(page, '', genreIds);
  }

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required String query,
    required int page,
    CancelToken? cancelToken,
  }) {
    requests.add((page: page, query: query, genres: null));
    return reply!(page, query, null);
  }

  @override
  Future<TmdbMovieDto> fetchMovieDetail(
    int id, {
    CancelToken? cancelToken,
  }) async {
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(Duration.zero);
    inFlight--;
    if (failDetails.contains(id)) throw Exception('movie lookup failed');
    return TmdbMovieDto(id: id, title: '영화 $id');
  }
}

TmdbMoviePageDto page(int number, List<int> ids, {int total = 3}) =>
    TmdbMoviePageDto(
      page: number,
      totalPages: total,
      results: ids.map((id) => TmdbMovieDto(id: id, title: '영화 $id')).toList(),
    );

class Favorites extends FavoriteApiService {
  Favorites() : super(Dio());
  bool favorite = false;
  int writes = 0, checks = 0;
  Object? writeError;
  Completer<void>? pending;
  List<FavoriteResponseDto> list = [];
  @override
  Future<List<FavoriteResponseDto>> fetchFavorites() async => list;
  @override
  Future<FavoriteResponseDto> add(int movieId) async {
    writes++;
    await pending?.future;
    if (writeError != null) throw writeError!;
    favorite = true;
    return FavoriteResponseDto(
      favoriteId: 1,
      movieId: movieId,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> remove(int movieId) async {
    writes++;
    if (writeError != null) throw writeError!;
    favorite = false;
  }

  // Use the real decoder for the no-movieId response shape.
  @override
  Future<dynamic> noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  FutureOr<ResponseBody> Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => reply(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody wrap(int status, Object? result, {String? code}) =>
    ResponseBody.fromString(
      jsonEncode({
        'isSuccess': status < 300,
        'code': code ?? 'COMMON$status',
        'message': 'test response',
        'result': result,
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  test(
    'W09 pagination starts with one page and deduplicates appended IDs',
    () async {
      final service = Movies()
        ..reply = (p, q, g) async => page(p, p == 1 ? [1, 2] : [2, 3]);
      final vm = PagedMoviesViewModel(service);
      addTearDown(vm.dispose);
      await vm.reset();
      expect(service.requests.map((r) => r.page), [1]);
      await vm.loadNextPage();
      expect(vm.movies.map((m) => m.id), [1, 2, 3]);
      expect(vm.page, 2);
    },
  );
  test('W09 failed next page keeps cards and retries the same page', () async {
    var fail = true;
    final service = Movies()
      ..reply = (p, q, g) async {
        if (p == 2 && fail) throw Exception('offline');
        return page(p, [p]);
      };
    final vm = PagedMoviesViewModel(service);
    addTearDown(vm.dispose);
    await vm.reset();
    await vm.loadNextPage();
    expect(vm.page, 1);
    expect(vm.movies.length, 1);
    expect(vm.nextPageError, isNotNull);
    fail = false;
    await vm.loadNextPage();
    expect(service.requests.map((r) => r.page), [1, 2, 2]);
    expect(vm.nextPageError, isNull);
  });
  test('W09 duplicate next-page taps issue only one request', () async {
    final waiting = Completer<TmdbMoviePageDto>();
    final service = Movies()
      ..reply = (p, q, g) =>
          p == 1 ? Future.value(page(1, [1])) : waiting.future;
    final vm = PagedMoviesViewModel(service);
    addTearDown(vm.dispose);
    await vm.reset();
    final next = vm.loadNextPage();
    await vm.loadNextPage();
    waiting.complete(page(2, [2]));
    await next;
    expect(service.requests.length, 2);
  });
  test('W09 last page stops further requests', () async {
    final service = Movies()..reply = (p, q, g) async => page(1, [1], total: 1);
    final vm = PagedMoviesViewModel(service);
    addTearDown(vm.dispose);
    await vm.reset();
    await vm.loadNextPage();
    expect(vm.hasNextPage, false);
    expect(service.requests.length, 1);
  });
  test('W09 new genre discards an older slow response', () async {
    final old = Completer<TmdbMoviePageDto>();
    final service = Movies()
      ..reply = (p, q, g) =>
          g?.first == 28 ? Future.value(page(1, [28])) : old.future;
    final vm = PagedMoviesViewModel(service);
    addTearDown(vm.dispose);
    final previous = vm.reset();
    await Future<void>.delayed(Duration.zero);
    await vm.selectGenres([28]);
    old.complete(page(1, [99]));
    await previous;
    expect(vm.movies.single.id, 28);
    expect(vm.isLoadingNext, false);
  });
  test(
    'W09 blank search is idle without API requests and query is trimmed',
    () async {
      final service = Movies()..reply = (p, q, g) async => page(p, [1]);
      final vm = PagedMoviesViewModel(service, isSearch: true);
      addTearDown(vm.dispose);
      await vm.search('   ');
      expect(vm.phase, LoadPhase.idle);
      expect(service.requests, isEmpty);
      await vm.search('  제임스  ');
      expect(service.requests.single.query, '제임스');
    },
  );
  test(
    'W09 older search cannot replace latest results or clear its spinner',
    () async {
      final old = Completer<TmdbMoviePageDto>(),
          latest = Completer<TmdbMoviePageDto>();
      final service = Movies()
        ..reply = (p, q, g) => q == 'old' ? old.future : latest.future;
      final vm = PagedMoviesViewModel(service, isSearch: true);
      addTearDown(vm.dispose);
      final first = vm.search('old');
      await Future<void>.delayed(Duration.zero);
      final second = vm.search('new');
      old.complete(page(1, [1]));
      await first;
      expect(vm.phase, LoadPhase.loading);
      latest.complete(page(1, [2]));
      await second;
      expect(vm.movies.single.id, 2);
    },
  );
  test('W09 dispose ignores late page results', () async {
    final pending = Completer<TmdbMoviePageDto>();
    final service = Movies()..reply = (p, q, g) => pending.future;
    final vm = PagedMoviesViewModel(service);
    final work = vm.reset();
    await Future<void>.delayed(Duration.zero);
    vm.dispose();
    pending.complete(page(1, [1]));
    await work;
    expect(vm.movies, isEmpty);
  });
  test(
    'W09 movie lookups preserve order and run at most five at once',
    () async {
      var running = 0, peak = 0;
      final result = await mapBounded(List.generate(17, (i) => i), (
        int i,
      ) async {
        running++;
        if (running > peak) peak = running;
        await Future<void>.delayed(Duration.zero);
        running--;
        return i;
      });
      expect(peak, 5);
      expect(result, List.generate(17, (i) => i));
    },
  );
  test(
    'W09 favorites keep partial failures retryable and clear on account change',
    () async {
      final session = Session();
      addTearDown(session.dispose);
      final api = Favorites()
        ..list = List.generate(
          12,
          (i) => FavoriteResponseDto(
            favoriteId: i,
            movieId: i,
            createdAt: DateTime(2026, 1, i + 1),
          ),
        );
      final movies = Movies()..failDetails.add(3);
      final vm = FavoritesViewModel(api, movies, session);
      addTearDown(vm.dispose);
      await vm.refresh();
      expect(vm.items.length, 12);
      expect(movies.maxInFlight, lessThanOrEqualTo(5));
      expect(vm.items.first.favorite.movieId, 11);
      expect(vm.items.firstWhere((e) => e.favorite.movieId == 3).movie, isNull);
      movies.failDetails.clear();
      await vm.retryMovie(3);
      expect(
        vm.items.firstWhere((e) => e.favorite.movieId == 3).movie,
        isNotNull,
      );
      session.change();
      expect(vm.items, isEmpty);
      expect(vm.phase, LoadPhase.idle);
    },
  );
  test(
    'W09 favorite check uses requested movie ID; delete accepts 200/null',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
      dio.httpClientAdapter = Adapter((r) {
        requests.add(r);
        return wrap(200, r.method == 'GET' ? {'isFavorite': true} : null);
      });
      final api = FavoriteApiService(dio);
      final check = await api.check(550);
      await api.remove(550);
      expect(check.movieId, 550);
      expect(check.isFavorite, true);
      expect(requests.map((r) => r.path), [
        '/v8/favorites/550',
        '/v8/favorites/550',
      ]);
      dio.close();
    },
  );
  test(
    'W09 favorite save stays unchanged while pending; duplicate taps ignored',
    () async {
      final pending = Completer<ResponseBody>();
      final started = Completer<void>();
      var posts = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
      dio.httpClientAdapter = Adapter((r) {
        if (r.method == 'POST') {
          posts++;
          started.complete();
          return pending.future;
        }
        return wrap(200, {'isFavorite': false});
      });
      final session = Session();
      final vm = FavoriteDetailViewModel(550, FavoriteApiService(dio), session);
      addTearDown(() {
        vm.dispose();
        session.dispose();
        dio.close();
      });
      await vm.load();
      final save = vm.toggle();
      await vm.toggle();
      await started.future;
      expect(vm.isFavorite, false);
      expect(vm.isSaving, true);
      expect(posts, 1);
      pending.complete(
        wrap(201, {
          'favoriteId': 1,
          'movieId': 550,
          'createdAt': '2026-11-24T00:00:00Z',
        }),
      );
      await save;
      expect(vm.isFavorite, true);
    },
  );
  test('W09 favorite conflict rechecks state without retrying POST', () async {
    var checks = 0, posts = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    dio.httpClientAdapter = Adapter((r) {
      if (r.method == 'POST') {
        posts++;
        return wrap(409, null, code: 'FAVORITE409_1');
      }
      checks++;
      return wrap(200, {'isFavorite': checks > 1});
    });
    final session = Session();
    final vm = FavoriteDetailViewModel(550, FavoriteApiService(dio), session);
    addTearDown(() {
      vm.dispose();
      session.dispose();
      dio.close();
    });
    await vm.load();
    await vm.toggle();
    expect(posts, 1);
    expect(checks, 2);
    expect(vm.isFavorite, true);
  });
  test('W09 network save failure preserves previous favorite state', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    dio.httpClientAdapter = Adapter((r) {
      if (r.method == 'POST') {
        throw DioException.connectionError(
          requestOptions: r,
          reason: 'offline',
        );
      }
      return wrap(200, {'isFavorite': false});
    });
    final session = Session();
    final vm = FavoriteDetailViewModel(550, FavoriteApiService(dio), session);
    addTearDown(() {
      vm.dispose();
      session.dispose();
      dio.close();
    });
    await vm.load();
    await vm.toggle();
    expect(vm.isFavorite, false);
    expect(vm.errorMessage, isNotNull);
    expect(session.active, true);
  });
  test('W09 auth attaches only to v8 protected host and methods', () async {
    final session = Session();
    addTearDown(session.dispose);
    final seen = <RequestOptions>[];
    final dio = createMovieLogClient();
    addTearDown(dio.close);
    dio.httpClientAdapter = Adapter((r) {
      seen.add(r);
      return wrap(200, null);
    });
    attachMovieLogAuth(dio, session);
    await dio.get('/v8/favorites');
    await dio.post('/v8/movie-records');
    await dio.get('https://api.themoviedb.org/3/movie/550');
    await dio.get('/v8/members/1/ratings');
    expect(
      seen
          .take(2)
          .every(
            (r) => r.headers['Authorization'] == 'Bearer test-session-token',
          ),
      true,
    );
    expect(
      seen.skip(2).every((r) => !r.headers.containsKey('Authorization')),
      true,
    );
  });
  test(
    'W09 403 does not expire; stale previous-session 401 is ignored',
    () async {
      final session = Session();
      addTearDown(session.dispose);
      final dio = createMovieLogClient();
      addTearDown(dio.close);
      final delayed = Completer<ResponseBody>();
      final started = Completer<void>();
      var count = 0;
      dio.httpClientAdapter = Adapter((r) {
        count++;
        if (count == 2) started.complete();
        return count == 1 ? wrap(403, null, code: 'COMMON403') : delayed.future;
      });
      attachMovieLogAuth(dio, session);
      await expectLater(dio.get('/v8/favorites'), throwsA(isA<DioException>()));
      expect(session.expirations, 0);
      final old = dio.get('/v8/favorites');
      final caught = expectLater(old, throwsA(isA<DioException>()));
      await started.future;
      session.revision++;
      delayed.complete(wrap(401, null, code: 'AUTH401_4'));
      await caught;
      expect(session.expirations, 0);
    },
  );
  test('W09 movie-record request includes required false flag and accepts null favorite', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
    addTearDown(dio.close);
    dio.httpClientAdapter = Adapter((r) {
      expect(r.path, '/v8/movie-records');
      expect(r.data, {'movieId': 550, 'score': 4, 'addToFavorites': false});
      return wrap(201, {
        'rating': {
          'ratingId': 1,
          'movieId': 550,
          'score': 4,
          'comment': null,
          'createdAt': '2026-11-24T00:00:00Z',
          'updatedAt': '2026-11-24T00:00:00Z',
        },
        'favorite': null,
      });
    });
    final result = await MovieRecordApiService(dio)
        .create(MovieRecordRequest(550, RatingInput(4, null), false));
    expect(result.favorite, isNull);
    expect(result.rating.score, 4);
  });
  testWidgets(
    'W09 search submits manually by default; debounce is 500ms when enabled',
    (tester) async {
      final movies = Movies()..reply = (p, q, g) async => page(p, [], total: 0);
      final vm = PagedMoviesViewModel(movies, isSearch: true);
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: MovieSearchScreen()),
        ),
      );
      await tester.enterText(find.byType(TextField), '제임스');
      await tester.pump(const Duration(seconds: 1));
      expect(movies.requests, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(movies.requests.length, 1);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '홀란드');
      await tester.pump(const Duration(milliseconds: 499));
      expect(movies.requests.length, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(movies.requests.last.query, '홀란드');
    },
  );
  testWidgets(
    'W09 rating checkbox stays hidden when editing and preserves input on failure',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => RatingDialog(
                  initialRating: 4,
                  showAddToFavorite: true,
                  onSubmit: (_) async {},
                  onSubmitRecord: (input, add) async {
                    expect(input.score, 4);
                    expect(add, true);
                    throw const ApiFailure('통신 실패');
                  },
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '기록 유지');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('통신 실패'), findsOneWidget);
      expect(find.text('기록 유지'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
    },
  );
}
