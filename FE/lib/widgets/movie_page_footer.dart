import 'package:flutter/material.dart';

import '../view_models/paged_movies_view_model.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({required this.vm, this.automatic = false, super.key});
  final PagedMoviesViewModel vm;
  final bool automatic;
  @override
  Widget build(BuildContext context) {
    if (vm.isLoadingNext) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!vm.hasNextPage) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (vm.nextPageError != null)
            Text(vm.nextPageError!, textAlign: TextAlign.center),
          if (!automatic || vm.nextPageError != null)
            TextButton(
              onPressed: vm.loadNextPage,
              child: Text(vm.nextPageError == null ? '더 보기' : '같은 페이지 다시 시도'),
            ),
          if (automatic && vm.nextPageError == null)
            const Text('아래로 스크롤하면 더 불러옵니다.'),
        ],
      ),
    );
  }
}
