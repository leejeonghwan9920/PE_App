import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/movie_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 즐겨찾기'),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            context.canPop() ? context.pop() : context.go('/my');
          },
        ),
      ),
      body: switch (vm.phase) {
        LoadPhase.idle ||
        LoadPhase.loading => const Center(child: CircularProgressIndicator()),
        LoadPhase.empty => const Center(child: Text('아직 즐겨찾기한 영화가 없습니다.')),
        LoadPhase.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.errorMessage ?? '즐겨찾기 조회 실패'),
              TextButton(onPressed: vm.refresh, child: const Text('다시 시도')),
            ],
          ),
        ),
        LoadPhase.success => RefreshIndicator(
          onRefresh: vm.refresh,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .54,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: vm.items.length,
            itemBuilder: (context, index) {
              final item = vm.items[index];
              final movie = item.movie;
              if (movie == null) {
                return Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 40),
                      Text(
                        '영화 정보 조회 실패 (#${item.favorite.movieId})',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: vm.retrying.contains(item.favorite.movieId)
                            ? null
                            : () => vm.retryMovie(item.favorite.movieId),
                        child: const Text('이 영화 다시 시도'),
                      ),
                    ],
                  ),
                );
              }
              final card = movie.toMovie(vm.genres);
              return MovieCard(
                movie: card,
                onTap: () async {
                  await context.push('/movies/${movie.id}', extra: card);
                  if (context.mounted && vm.current) await vm.refresh();
                },
              );
            },
          ),
        ),
      },
    );
  }
}
