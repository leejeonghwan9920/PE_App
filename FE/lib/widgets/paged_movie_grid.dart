import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../view_models/paged_movies_view_model.dart';
import 'movie_card.dart';
import 'movie_page_footer.dart';

class PagedMovieGrid extends StatefulWidget {
  const PagedMovieGrid({required this.vm, this.automatic = false, super.key});
  final PagedMoviesViewModel vm;
  final bool automatic;
  @override
  State<PagedMovieGrid> createState() => _PagedMovieGridState();
}

class _PagedMovieGridState extends State<PagedMovieGrid> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.automatic &&
        _scroll.hasClients &&
        _scroll.position.extentAfter < 300 &&
        widget.vm.nextPageError == null) {
      widget.vm.loadNextPage();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movies = widget.vm.visibleMovies;
    return CustomScrollView(
      key: const PageStorageKey('movie-grid'),
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: .54,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final movie = movies[index];
              return MovieCard(
                key: ValueKey(movie.id),
                movie: movie,
                onTap: () => context.push('/movies/${movie.id}', extra: movie),
              );
            }, childCount: movies.length),
          ),
        ),
        SliverToBoxAdapter(
          child: MoviePageFooter(vm: widget.vm, automatic: widget.automatic),
        ),
      ],
    );
  }
}
