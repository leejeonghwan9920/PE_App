import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/paged_movies_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/paged_movie_grid.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});
  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  bool _automatic = false;
  void _changed(String value) {
    _debounce?.cancel();
    final vm = context.read<PagedMoviesViewModel>();
    vm.invalidateSearch();
    if (_automatic) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) vm.search(value.trim());
      });
    }
  }

  void _submit() {
    _debounce?.cancel();
    context.read<PagedMoviesViewModel>().search(_query.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagedMoviesViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 검색'),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            context.canPop() ? context.pop() : context.go('/movies');
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onChanged: _changed,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: '영화 제목',
                hintText: '검색어를 입력해 주세요',
                suffixIcon: IconButton(
                  tooltip: '검색',
                  onPressed: _submit,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('입력 후 자동 검색'),
            subtitle: const Text('입력을 멈추면 0.5초 뒤 검색'),
            value: _automatic,
            onChanged: (value) {
              setState(() => _automatic = value);
              _changed(_query.text);
            },
          ),
          Expanded(
            child: switch (vm.phase) {
              LoadPhase.idle => const Center(child: Text('검색어를 입력하고 검색해 주세요.')),
              LoadPhase.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadPhase.empty => const Center(child: Text('검색 결과가 없습니다.')),
              LoadPhase.error => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.errorMessage ?? '검색 실패'),
                    TextButton(onPressed: vm.reset, child: const Text('다시 시도')),
                  ],
                ),
              ),
              LoadPhase.success => PagedMovieGrid(
                key: ValueKey(vm.query),
                vm: vm,
              ),
            },
          ),
        ],
      ),
    );
  }
}
