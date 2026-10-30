/// Configuração do backend (Supabase).
///
/// A chave "publishable" é pública por natureza: vai no bundle do app e só
/// permite o que as policies RLS do banco autorizam. Pode ser trocada em tempo
/// de build com --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
class Config {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hugpnbdoqkheiqkkvokm.supabase.co',
  );

  static const supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_lKL-7cKcnOfG9bPzxfACJw_QNrgbDBx',
  );

  /// Tempo máximo de espera de cada requisição HTTP.
  static const timeout = Duration(seconds: 15);

  /// Versão dos termos aceitos no cadastro (exigida pelo banco).
  static const versaoTermos = '2026-10';
}
