/// Validações dos formulários. Cada função devolve a mensagem de erro ou `null`
/// (formato esperado por `TextFormField.validator`).
library;

String somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

String? obrigatorio(String? valor, [String campo = 'Campo']) =>
    (valor == null || valor.trim().isEmpty) ? '$campo obrigatório' : null;

String? validarNome(String? valor) {
  final v = valor?.trim() ?? '';
  if (v.isEmpty) return 'Informe o nome';
  if (v.length < 2) return 'Nome muito curto';
  if (v.length > 120) return 'Máximo de 120 caracteres';
  return null;
}

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validarEmail(String? valor) {
  final v = valor?.trim() ?? '';
  if (v.isEmpty) return 'Informe o e-mail';
  if (!_email.hasMatch(v)) return 'E-mail inválido';
  return null;
}

String? validarSenha(String? valor) {
  final v = valor ?? '';
  if (v.isEmpty) return 'Informe a senha';
  if (v.length < 8) return 'Mínimo de 8 caracteres';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return 'Use letras e números';
  }
  return null;
}

/// Telefone com DDD (10 ou 11 dígitos). Vazio é aceito quando opcional.
String? validarTelefone(String? valor, {bool opcional = true}) {
  final d = somenteDigitos(valor ?? '');
  if (d.isEmpty) return opcional ? null : 'Informe o telefone';
  if (d.length < 10 || d.length > 11) return 'Telefone com DDD (10 ou 11 dígitos)';
  return null;
}

String? validarCep(String? valor) {
  final d = somenteDigitos(valor ?? '');
  if (d.isEmpty) return 'Informe o CEP';
  if (d.length != 8) return 'CEP com 8 dígitos';
  return null;
}

String? Function(String?) limiteDeTexto(int maximo, {bool obrigatorio = false}) =>
    (valor) {
      final v = valor?.trim() ?? '';
      if (obrigatorio && v.isEmpty) return 'Campo obrigatório';
      if (v.length > maximo) return 'Máximo de $maximo caracteres';
      return null;
    };

/// Valor em reais (ex.: "25" ou "25,50") entre 0 e 1000.
String? validarTaxa(String? valor) {
  final v = (valor ?? '').trim().replaceAll(',', '.');
  if (v.isEmpty) return 'Informe a taxa';
  final n = double.tryParse(v);
  if (n == null) return 'Valor inválido';
  if (n < 0 || n > 1000) return 'Entre R\$ 0 e R\$ 1.000';
  return null;
}

int reaisParaCentavos(String valor) =>
    (double.parse(valor.trim().replaceAll(',', '.')) * 100).round();
