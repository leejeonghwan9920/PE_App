import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../models/common_response.dart';
import '../services/favorite_api_service.dart';
import 'auth_session.dart';
import 'session_guard.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel(this.movieId, this._api, AuthSession session)
    : guard = SessionGuard(session) {
    session.addListener(_sessionChanged);
  }
  final int movieId;
  final FavoriteApiService _api;
  final SessionGuard guard;
  bool isLoading = false,
      isSaving = false,
      isFavorite = false,
      hasLoaded = false;
  String? errorMessage;
  bool get current => !isDisposed && guard.isCurrent;
  bool get canSave =>
      current && !guard.session.busy && hasLoaded && !isLoading && !isSaving;
  void _sessionChanged() {
    if (!guard.isCurrent) {
      isFavorite = false;
      hasLoaded = false;
      errorMessage = null;
      isLoading = false;
      isSaving = false;
      notifyIfAlive();
    }
  }

  Future<void> load() async {
    if (!current || isLoading || isSaving) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await _api.check(movieId);
      if (!current) return;
      isFavorite = result.isFavorite;
      hasLoaded = true;
    } catch (e) {
      if (current) {
        errorMessage = ApiFailure.from(e, '즐겨찾기 여부를 불러오지 못했습니다.').message;
      }
    } finally {
      if (current) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  /// Updates only after server confirmation; ambiguous writes are never retried automatically.
  Future<String?> toggle() async {
    if (!canSave) return null;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    final target = !isFavorite;
    try {
      if (target) {
        await _api.add(movieId);
      } else {
        await _api.remove(movieId);
      }
      if (!current) return null;
      isFavorite = target;
      return target ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 해제했습니다.';
    } catch (e) {
      if (!current) return null;
      final failure = ApiFailure.from(e, '즐겨찾기를 변경하지 못했습니다. 다시 확인해 주세요.');
      if (failure.code == 'FAVORITE409_1' || failure.code == 'FAVORITE404_1') {
        try {
          final checked = await _api.check(movieId);
          if (!current) return null;
          isFavorite = checked.isFavorite;
        } catch (_) {
          if (!current) return null;
        }
      }
      errorMessage = failure.message;
      return errorMessage;
    } finally {
      if (current) {
        isSaving = false;
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
