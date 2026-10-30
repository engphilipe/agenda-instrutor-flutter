/// Erros mostrados ao usuário. Toda falha da camada de dados vira um [ErroApp]
/// com mensagem em português pronta para a tela.
enum TipoErro { validacao, negocio, autenticacao, conexao, servico }

class ErroApp implements Exception {
  const ErroApp(this.mensagem, {this.tipo = TipoErro.negocio, this.codigo});

  final String mensagem;
  final TipoErro tipo;
  final String? codigo;

  static const conexao = ErroApp(
    'Sem conexão com o servidor. Verifique sua internet e tente de novo.',
    tipo: TipoErro.conexao,
  );

  static const tempoEsgotado = ErroApp(
    'O servidor demorou para responder. Tente de novo em instantes.',
    tipo: TipoErro.conexao,
  );

  static const indisponivel = ErroApp(
    'O serviço está indisponível no momento. Tente mais tarde.',
    tipo: TipoErro.servico,
  );

  static const sessaoExpirada = ErroApp(
    'Sua sessão expirou. Entre novamente.',
    tipo: TipoErro.autenticacao,
    codigo: 'NAO_AUTENTICADO',
  );

  @override
  String toString() => mensagem;
}

/// Códigos de regra de negócio lançados pelo banco (`raise exception 'CODIGO'`).
const mensagensDoBanco = {
  'NAO_AUTORIZADO': 'Você não tem permissão para esta ação.',
  'HORARIO_INDISPONIVEL': 'Este horário não está mais disponível. Escolha outro.',
  'CONFLITO_ALUNO': 'Você já tem uma aula neste horário.',
  'BUSCA_NAO_OFERECIDA': 'Este instrutor não faz busca no endereço.',
  'ENDERECO_NAO_CADASTRADO': 'Cadastre seu endereço para pedir a busca.',
  'AULA_NAO_ENCONTRADA': 'Aula não encontrada.',
  'AULA_NAO_CANCELAVEL': 'Esta aula não pode mais ser cancelada.',
  'PRAZO_CANCELAMENTO_EXPIRADO':
      'Cancelamentos só até 2 horas antes da aula.',
  'AULA_NAO_ENCERRAVEL':
      'Só é possível registrar o resultado depois do início da aula.',
  'STATUS_INVALIDO': 'Status inválido.',
  'ALUNO_OBRIGATORIO': 'Informe o nome do aluno.',
  'JANELA_INVALIDA': 'Período de consulta inválido.',
};

/// Erros do Postgres de dado fora do formato (check, texto longo, valor inválido, nulo).
const _pgDadosInvalidos = {'23514', '22001', '22P02', '23502', '22003'};

/// Erros do Supabase Auth (campo `error_code`).
const _mensagensAuth = {
  'invalid_credentials': 'E-mail ou senha incorretos.',
  'email_not_confirmed': 'Confirme seu e-mail antes de entrar.',
  'user_already_exists': 'Já existe uma conta com este e-mail.',
  'email_exists': 'Já existe uma conta com este e-mail.',
  'weak_password':
      'A senha precisa ter ao menos 8 caracteres, com letras e números.',
  'over_request_rate_limit':
      'Muitas tentativas seguidas. Aguarde um minuto e tente de novo.',
  'over_email_send_rate_limit':
      'Muitas tentativas seguidas. Aguarde um minuto e tente de novo.',
  'refresh_token_not_found': 'Sua sessão expirou. Entre novamente.',
};

/// Converte uma resposta HTTP de erro (PostgREST ou Auth) em [ErroApp].
ErroApp erroDaResposta(int status, Object? corpo) {
  final json = corpo is Map ? corpo : const {};
  final mensagem = json['message'] ?? json['msg'];
  final codigoPg = json['code']?.toString();
  final codigoAuth = json['error_code']?.toString();

  if (mensagem is String && mensagensDoBanco.containsKey(mensagem)) {
    return ErroApp(mensagensDoBanco[mensagem]!, codigo: mensagem);
  }
  if (codigoAuth != null && _mensagensAuth.containsKey(codigoAuth)) {
    return ErroApp(
      _mensagensAuth[codigoAuth]!,
      tipo: TipoErro.autenticacao,
      codigo: codigoAuth,
    );
  }
  if (codigoPg != null && _pgDadosInvalidos.contains(codigoPg)) {
    return const ErroApp(
      'Algum campo está fora do formato aceito. Confira os dados.',
      tipo: TipoErro.validacao,
    );
  }
  if (status == 401) return ErroApp.sessaoExpirada;
  if (status == 403) return ErroApp(mensagensDoBanco['NAO_AUTORIZADO']!);
  if (status == 429) {
    return ErroApp(_mensagensAuth['over_request_rate_limit']!);
  }
  if (status >= 500) return ErroApp.indisponivel;
  return const ErroApp('Algo deu errado. Tente novamente.');
}
