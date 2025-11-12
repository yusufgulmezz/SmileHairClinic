import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcı modeli
class User {
  final String email;
  final String name;

  User({required this.email, required this.name});
}

/// Auth durumu
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
}

/// Auth Provider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    
    // Simüle edilmiş login (gerçek implementasyonda API çağrısı yapılacak)
    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && password.isNotEmpty) {
      state = AuthState(
        user: User(
          email: email,
          name: email.split('@')[0],
        ),
      );
      return true;
    } else {
      state = AuthState(error: 'E-posta ve şifre gerekli');
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

