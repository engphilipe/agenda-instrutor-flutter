import '../core/api.dart';
import '../core/grade.dart';
import '../core/tempo.dart';
import 'modelos.dart';

/// Busca de instrutores, horários livres e agendamento pelo aluno.
class BuscaRepositorio {
  BuscaRepositorio(this._api);

  final Api _api;

  /// Só instrutores aprovados e ativos aparecem (a view já filtra).
  Future<List<Instrutor>> instrutores({
    required String categoria,
    int? cidadeId,
    String? nome,
  }) async {
    final termo = nome?.trim().replaceAll(RegExp(r'[*,()]'), '') ?? '';
    final json = await _api.get('/rest/v1/instrutores_publicos', query: {
      'select': '*',
      'categorias_cnh': 'cs.{$categoria}',
      'cidade_id': ?cidadeId == null ? null : 'eq.$cidadeId',
      'nome': ?termo.isEmpty ? null : 'ilike.*$termo*',
      'order': 'nota_media.desc,total_avaliacoes.desc',
      'limit': '50',
    }) as List;
    return json.map((j) => Instrutor.deJson(j)).toList();
  }

  /// Horários livres de [dias] dias a partir de hoje, agrupados por data.
  Future<Map<DateTime, List<Horario>>> horariosLivres(
    String instrutorId, {
    int dias = 14,
  }) async {
    final agora = DateTime.now().toUtc();
    final de = hojeLocal(agora);
    final ate = somarDias(de, dias - 1);

    final respostas = await Future.wait([
      _api.get('/rest/v1/availability_rules', query: {
        'select': 'dia_semana,hora_inicio,hora_fim',
        'instructor_id': 'eq.$instrutorId',
      }),
      _api.get('/rest/v1/availability_exceptions', query: {
        'select': 'data,hora_inicio,hora_fim,tipo',
        'instructor_id': 'eq.$instrutorId',
        'and': '(data.gte.${dataIso(de)},data.lte.${dataIso(ate)})',
      }),
      _api.rpc('horarios_ocupados', {
        'p_instructor': instrutorId,
        'p_de': paraInstante(de, 0).toIso8601String(),
        'p_ate': paraInstante(somarDias(ate, 1), 0).toIso8601String(),
      }),
    ]);

    final regras = (respostas[0] as List).map((j) => Regra.deJson(j)).toList();
    final excecoes =
        (respostas[1] as List).map((j) => Excecao.deJson(j)).toList();
    final ocupados = (respostas[2] as List)
        .map((j) => Intervalo(
              DateTime.parse(j['inicio'] as String),
              DateTime.parse(j['fim'] as String),
            ))
        .toList();

    final resultado = <DateTime, List<Horario>>{};
    for (var i = 0; i < dias; i++) {
      final data = somarDias(de, i);
      final livres = gradeDoDia(
        data,
        regras: regras,
        excecoes: excecoes,
        ocupados: ocupados,
        agora: agora,
      ).where((h) => h.estado == EstadoHorario.livre).toList();
      if (livres.isNotEmpty) resultado[data] = livres;
    }
    return resultado;
  }

  /// O banco revalida o horário e já cria a aula confirmada.
  Future<void> agendar({
    required String instrutorId,
    required DateTime inicio,
    required bool busca,
    String? observacao,
  }) =>
      _api.rpc('agendar_aula', {
        'p_instructor': instrutorId,
        'p_inicio': inicio.toUtc().toIso8601String(),
        'p_local': busca ? 'busca' : 'ponto_encontro',
        if (observacao != null && observacao.trim().isNotEmpty)
          'p_observacao': observacao.trim(),
      });
}
