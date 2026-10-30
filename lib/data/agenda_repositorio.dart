import '../core/api.dart';
import '../core/grade.dart';
import '../core/tempo.dart';
import 'modelos.dart';

/// Agenda e perfil profissional do instrutor logado.
class AgendaRepositorio {
  AgendaRepositorio(this._api);

  final Api _api;

  Future<List<Regra>> regras(String instrutorId) async {
    final json = await _api.get('/rest/v1/availability_rules', query: {
      'select': 'dia_semana,hora_inicio,hora_fim',
      'instructor_id': 'eq.$instrutorId',
    }) as List;
    return json.map((j) => Regra.deJson(j)).toList();
  }

  Future<List<Excecao>> excecoes(
    String instrutorId,
    DateTime de,
    DateTime ate,
  ) async {
    final json = await _api.get('/rest/v1/availability_exceptions', query: {
      'select': 'data,hora_inicio,hora_fim,tipo',
      'instructor_id': 'eq.$instrutorId',
      'and': '(data.gte.${dataIso(de)},data.lte.${dataIso(ate)})',
    }) as List;
    return json.map((j) => Excecao.deJson(j)).toList();
  }

  /// Substitui a semana padrão inteira em uma transação no banco.
  Future<void> salvarSemana(Map<int, Set<int>> semana) =>
      _api.rpc('definir_regras_semanais', {
        'p_regras': regrasDaSemana(semana).map((r) => r.paraJson()).toList(),
      });

  Future<PerfilProfissional> perfilProfissional(String instrutorId) async {
    final json = await _api.get('/rest/v1/instructors', query: {
      'select': '*',
      'profile_id': 'eq.$instrutorId',
    }) as List;
    return PerfilProfissional.deJson(json.single);
  }

  Future<PerfilProfissional> salvarPerfilProfissional(
    String instrutorId, {
    required List<String> categorias,
    required int? cidadeId,
    required bool ofereceBusca,
    required bool ativo,
    String? bio,
    String? veiculo,
    String? pontoEncontro,
    int? taxaBuscaCentavos,
  }) async {
    String? texto(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    final json = await _api.patch(
      '/rest/v1/instructors',
      query: {'profile_id': 'eq.$instrutorId'},
      corpo: {
        'categorias_cnh': categorias,
        'cidade_id': cidadeId,
        'bio': texto(bio),
        'veiculo': texto(veiculo),
        'ponto_encontro': texto(pontoEncontro),
        'oferece_busca': ofereceBusca,
        'taxa_busca_centavos': ofereceBusca ? taxaBuscaCentavos : null,
        'ativo': ativo,
      },
    ) as List;
    return PerfilProfissional.deJson(json.single);
  }
}
