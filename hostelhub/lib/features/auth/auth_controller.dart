import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_provider.dart';
import '../../data/models/user.dart';
import '../../data/session_store.dart';

class AuthState {
  final User? user;
  final bool loading;
  const AuthState({this.user, this.loading = false});
}

/// Session controller: login/register/logout + bootstrap from persisted store.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _bootstrap();
    return const AuthState(loading: true);
  }

  Future<void> _bootstrap() async {
    final user = await ref.read(sessionStoreProvider).loadUser();
    state = AuthState(user: user);
  }

  /// Returns null on success, or a user-facing error message.
  Future<String?> login(String username, String password) async {
    try {
      final user =
          await ref.read(backendProvider).auth.login(username, password);
      await ref.read(sessionStoreProvider).saveUser(user);
      state = AuthState(user: user);
      return null;
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  /// Returns null on success, or a user-facing error message.
  Future<String?> register({
    required String role,
    required String name,
    required String phone,
    String email = '',
    required String username,
    required String password,
  }) async {
    try {
      final draft = User(
        id: '', // server assigns the real id
        role: role == 'owner' ? UserRole.owner : UserRole.inmate,
        name: name,
        phone: phone,
        email: email,
        username: username,
      );
      final created =
          await ref.read(backendProvider).auth.register(draft, password);
      await ref.read(sessionStoreProvider).saveUser(created);
      state = AuthState(user: created);
      return null;
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  Future<void> logout() async {
    await ref.read(sessionStoreProvider).clear();
    state = const AuthState();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
