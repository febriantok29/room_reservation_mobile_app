import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/core/session/session_user_context.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.getInstance();
});

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, Profile?>(
      AuthSessionNotifier.new,
    );

class AuthSessionNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    return null;
  }

  Future<Profile?> bootstrap() async {
    state = const AsyncLoading();

    final authService = ref.read(authServiceProvider);

    try {
      await authService.restoreApiSession();

      if (authService.accessToken == null || authService.accessToken!.isEmpty) {
        SessionUserContext.clear();
        state = const AsyncData(null);
        return null;
      }

      final profile = await authService.getMyProfileFromApi();
      SessionUserContext.setCurrentUser(profile);
      state = AsyncData(profile);
      return profile;
    } catch (_) {
      await authService.logoutApiSession();
      SessionUserContext.clear();
      state = const AsyncData(null);
      return null;
    }
  }

  Future<void> login({required String login, required String password}) async {
    state = const AsyncLoading();

    final authService = ref.read(authServiceProvider);

    await authService.loginToApi(login: login, password: password);
    final profile = await authService.getMyProfileFromApi();

    SessionUserContext.setCurrentUser(profile);
    state = AsyncData(profile);
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logoutApiSession();
    SessionUserContext.clear();
    state = const AsyncData(null);
  }
}
