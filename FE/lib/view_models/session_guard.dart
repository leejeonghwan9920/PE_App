import 'auth_session.dart';

class SessionGuard {
  SessionGuard(this.session) : generation = session.generation;
  final AuthSession session;
  final int generation;
  bool get isCurrent =>
      session.signedIn &&
      session.token != null &&
      session.isCurrent(generation);
}
