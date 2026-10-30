import 'dart:convert';

import 'package:agenda_instrutor_flutter/config.dart';
import 'package:agenda_instrutor_flutter/core/api.dart';
import 'package:agenda_instrutor_flutter/core/erros.dart';
import 'package:agenda_instrutor_flutter/data/busca_repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('envia apikey e token, e filtra instrutores pela categoria', () async {
    late http.Request enviada;
    final api = Api(
      cliente: MockClient((req) async {
        enviada = req;
        return http.Response.bytes(
          utf8.encode(jsonEncode([
            {'id': 'i1', 'nome': 'João', 'categorias_cnh': ['B'], 'nota_media': 4.5},
          ])),
          200,
        );
      }),
    )..token = (() => 'tok');

    final lista = await BuscaRepositorio(api).instrutores(categoria: 'B', nome: 'jo');

    expect(lista.single.nome, 'João');
    expect(enviada.url.path, '/rest/v1/instrutores_publicos');
    expect(enviada.url.queryParameters['categorias_cnh'], 'cs.{B}');
    expect(enviada.url.queryParameters['nome'], 'ilike.*jo*');
    expect(enviada.url.queryParameters.containsKey('cidade_id'), isFalse);
    expect(enviada.headers['apikey'], Config.supabaseKey);
    expect(enviada.headers['Authorization'], 'Bearer tok');
  });

  test('renova o token vencido e repete a requisição', () async {
    var token = 'velho';
    var chamadas = 0;
    final api = Api(
      cliente: MockClient((req) async {
        chamadas++;
        return req.headers['Authorization'] == 'Bearer novo'
            ? http.Response('[]', 200)
            : http.Response('{"message":"JWT expired"}', 401);
      }),
    )
      ..token = (() => token)
      ..renovarToken = () async {
        token = 'novo';
        return true;
      };

    expect(await api.get('/rest/v1/bookings'), isEmpty);
    expect(chamadas, 2);
  });

  test('falha de rede vira erro de conexão', () async {
    final api = Api(cliente: MockClient((_) => throw http.ClientException('offline')));
    expect(
      () => api.get('/rest/v1/cidades'),
      throwsA(isA<ErroApp>().having((e) => e.tipo, 'tipo', TipoErro.conexao)),
    );
  });
}
