import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'erros.dart';

/// Cliente HTTP do Supabase: Auth (`/auth/v1`) e banco via PostgREST (`/rest/v1`).
///
/// Única classe do app que faz requisições. Monta os cabeçalhos, aplica timeout,
/// renova o token quando ele expira e converte qualquer falha em [ErroApp].
class Api {
  Api({http.Client? cliente}) : _http = cliente ?? http.Client();

  final http.Client _http;

  /// Token do usuário logado (definido pela sessão).
  String? Function()? token;

  /// Renova o token expirado; devolve `false` se não conseguir (sessão perdida).
  Future<bool> Function()? renovarToken;

  Future<dynamic> get(String caminho, {Map<String, Object>? query}) =>
      _enviar('GET', caminho, query: query);

  Future<dynamic> post(
    String caminho, {
    Object? corpo,
    Map<String, Object>? query,
    Map<String, String>? cabecalhos,
    bool autenticado = true,
  }) =>
      _enviar(
        'POST',
        caminho,
        corpo: corpo,
        query: query,
        cabecalhos: cabecalhos,
        autenticado: autenticado,
      );

  Future<dynamic> patch(
    String caminho, {
    required Object corpo,
    Map<String, Object>? query,
  }) =>
      _enviar(
        'PATCH',
        caminho,
        corpo: corpo,
        query: query,
        cabecalhos: const {'Prefer': 'return=representation'},
      );

  /// Chama uma função do banco (`/rest/v1/rpc/<nome>`).
  Future<dynamic> rpc(String funcao, Map<String, Object?> parametros) =>
      post('/rest/v1/rpc/$funcao', corpo: parametros);

  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    Object? corpo,
    Map<String, Object>? query,
    Map<String, String>? cabecalhos,
    bool autenticado = true,
    bool podeRenovar = true,
  }) async {
    final uri = Uri.parse('${Config.supabaseUrl}$caminho')
        .replace(queryParameters: query);
    final requisicao = http.Request(metodo, uri)
      ..headers.addAll({
        'apikey': Config.supabaseKey,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?cabecalhos,
      });
    final tokenAtual = autenticado ? token?.call() : null;
    if (tokenAtual != null) {
      requisicao.headers['Authorization'] = 'Bearer $tokenAtual';
    }
    if (corpo != null) requisicao.body = jsonEncode(corpo);

    final http.Response resposta;
    try {
      final enviado = await _http.send(requisicao).timeout(Config.timeout);
      resposta = await http.Response.fromStream(enviado).timeout(Config.timeout);
    } on TimeoutException {
      throw ErroApp.tempoEsgotado;
    } on http.ClientException {
      throw ErroApp.conexao;
    }

    final json = _decodificar(resposta);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return json;

    // Token vencido: renova uma vez e repete a requisição.
    if (resposta.statusCode == 401 &&
        tokenAtual != null &&
        podeRenovar &&
        renovarToken != null &&
        await renovarToken!()) {
      return _enviar(
        metodo,
        caminho,
        corpo: corpo,
        query: query,
        cabecalhos: cabecalhos,
        podeRenovar: false,
      );
    }
    throw erroDaResposta(resposta.statusCode, json);
  }

  static Object? _decodificar(http.Response resposta) {
    final texto = utf8.decode(resposta.bodyBytes);
    if (texto.trim().isEmpty) return null;
    try {
      return jsonDecode(texto);
    } on FormatException {
      if (resposta.statusCode >= 500) throw ErroApp.indisponivel;
      return null;
    }
  }
}
