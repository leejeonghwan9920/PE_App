import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'support/test_tmdb_service.dart';

void main() {
  Future<MovieListViewModel> pump(
    WidgetTester tester,
    TestTmdbService service,
  ) async {
    final vm = MovieListViewModel(
      service,
      preferences: MemoryMovieListPreferences(),
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: MovieListScreen()),
      ),
    );
    vm.initialize();
    await tester.pump();
    return vm;
  }

  testWidgets('첫 로딩 중 상태를 표시하고 필터는 새 요청으로 변경할 수 있다', (tester) async {
    final service = TestTmdbService()..delay = const Duration(seconds: 1);
    await pump(tester, service);
    expect(find.byKey(const ValueKey('movie-list-loading')), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '전체'))
          .onSelected,
      isNotNull,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
  });

  testWidgets('빈 목록도 새로고침할 수 있다', (tester) async {
    final service = TestTmdbService()..empty = true;
    await pump(tester, service);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-list-empty')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('movie-list-empty')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(service.calls, 2);
  });

  testWidgets('첫 페이지 실패는 인라인 오류를 표시하고 재시도하면 회복한다', (tester) async {
    final service = TestTmdbService()..fail = true;
    await pump(tester, service);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('movie-list-error')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    service.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('movie-grid')), findsOneWidget);
    expect(service.requestedPages, [1, 1]);
  });
}
