import '../core/api.dart';
import 'modelos.dart';

/// Perfil do usuário, cidades e endereço do aluno.
class PerfilRepositorio {
  PerfilRepositorio(this._api);

  final Api _api;
  List<Cidade>? _cidades;

  Future<List<Cidade>> cidades() async {
    final json = await _api.get('/rest/v1/cidades', query: {
      'select': 'id,nome,uf',
      'order': 'nome',
    }) as List;
    return _cidades = json.map((c) => Cidade.deJson(c)).toList();
  }

  /// Cidades em cache (carregadas uma vez por sessão).
  Future<List<Cidade>> cidadesEmCache() async => _cidades ?? await cidades();

  Future<Perfil> meuPerfil(String id) async {
    final json = await _api.get('/rest/v1/profiles', query: {
      'select': 'id,role,nome,telefone,cidade_id',
      'id': 'eq.$id',
    }) as List;
    return Perfil.deJson(json.single);
  }

  Future<Perfil> atualizar(
    String id, {
    required String nome,
    String? telefone,
    int? cidadeId,
  }) async {
    final json = await _api.patch(
      '/rest/v1/profiles',
      query: {'id': 'eq.$id', 'select': 'id,role,nome,telefone,cidade_id'},
      corpo: {'nome': nome, 'telefone': telefone, 'cidade_id': cidadeId},
    ) as List;
    return Perfil.deJson(json.single);
  }

  Future<Endereco?> endereco(String id) async {
    final json = await _api.get('/rest/v1/student_addresses', query: {
      'select': '*',
      'profile_id': 'eq.$id',
    }) as List;
    return json.isEmpty ? null : Endereco.deJson(json.single);
  }

  /// Cria ou substitui o endereço (upsert pela chave `profile_id`).
  Future<void> salvarEndereco(String id, Endereco endereco) => _api.post(
        '/rest/v1/student_addresses',
        query: {'on_conflict': 'profile_id'},
        cabecalhos: const {'Prefer': 'resolution=merge-duplicates'},
        corpo: endereco.paraJson(id),
      );
}
