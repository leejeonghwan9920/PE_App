import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoriteDetailViewModel?>();
    if (vm == null) return const SizedBox.shrink();
    if (vm.isLoading || vm.isSaving) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      key: const ValueKey('favorite-button'),
      tooltip: vm.hasLoaded
          ? (vm.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가')
          : '즐겨찾기 여부 다시 조회',
      onPressed: !vm.current
          ? null
          : () async {
              if (!vm.hasLoaded) {
                await vm.load();
                if (!context.mounted ||
                    !vm.current ||
                    vm.errorMessage == null) {
                  return;
                }
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
                return;
              }
              final message = await vm.toggle();
              if (!context.mounted || !vm.current || message == null) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            },
      icon: Icon(vm.isFavorite ? Icons.bookmark : Icons.bookmark_border),
    );
  }
}
