import '../config.dart';
import '../core/api.dart';
import '../core/erros.dart';

/// Tokens da sessão do Supabase Auth (persistidos no aparelho).
class SessaoAuth {
  const SessaoAuth({
    required this.accessToken,
    required this.refreshToken,
    required this.expiraEm,
    required this.usuarioId,
    required this.email,
  });

  factory SessaoAuth.deResposta(Map<String, dynamic> j) {
    final usuario = j['user'] as Map<String, dynamic>;
    return SessaoAuth(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String,
      expiraEm: DateTime.now().add(Duration(seconds: j['expires_in'] as int)),
      usuarioId: usuario['id'] as String,
      email: usuario['email'] as String? ?? '',
    );
  }

  factory SessaoAuth.deJson(Map<String, dynamic> j) => SessaoAuth(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        expiraEm: DateTime.parse(j['expiraEm'] as String),
        usuarioId: j['usuarioId'] as String,
        email: j['email'] as String,
      );

  final String accessToken;
  final String refreshToken;
  final DateTime expiraEm;
  final String usuarioId;
  final String email;

  bool get expirada =>
      DateTime.now().isAfter(expiraEm.subtract(const Duration(minutes: 1)));

  Map<String, String> paraJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiraEm': expiraEm.toIso8601String(),
        'usuarioId': usuarioId,
        'email': email,
      };
}

/// Cadastro, login e renovação de sessão (Supabase Auth, `/auth/v1`).
class AuthRepositorio {
  AuthRepositorio(this._api);

  final Api _api;

  Future<SessaoAuth> entrar(String email, String senha) async {
    final json = await _api.post(
      '/auth/v1/token',
      query: {'grant_type': 'password'},
      corpo: {'email': email.trim(), 'password': senha},
      autenticado: false,
    );
    return SessaoAuth.deResposta(json as Map<String, dynamic>);
  }

  /// O banco cria o perfil (e o registro de instrutor) a partir dos metadados.
  Future<SessaoAuth> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required bool instrutor,
  }) async {
    final json = await _api.post(
      '/auth/v1/signup',
      corpo: {
        'email': email.trim(),
        'password': senha,
        'data': {
          'nome': nome.trim(),
          'role': instrutor ? 'instructor' : 'student',
          'consentimento_versao': Config.versaoTermos,
        },
      },
      autenticado: false,
    ) as Map<String, dynamic>;
    if (json['access_token'] == null) {
      // Projeto com confirmação por e-mail ligada: a conta existe, mas sem sessão.
      throw const ErroApp(
        'Conta criada. Confirme seu e-mail e depois entre.',
        tipo: TipoErro.autenticacao,
      );
    }
    return SessaoAuth.deResposta(json);
  }

  Future<SessaoAuth> renovar(String refreshToken) async {
    final json = await _api.post(
      '/auth/v1/token',
      query: {'grant_type': 'refresh_token'},
      corpo: {'refresh_token': refreshToken},
      autenticado: false,
    );
    return SessaoAuth.deResposta(json as Map<String, dynamic>);
  }

  Future<void> sair() => _api.post('/auth/v1/logout');
}
